require "rails_helper"

RSpec.describe Seeds::Organization do
  before do
    allow(Geocoder).to receive(:search).and_return([double(coordinates: [0, 0], cache_hit: true)])
  end

  describe ".sync" do
    it "uses coordinates from the YAML instead of geocoding" do
      Seeds::Organization.sync

      retreat = Organization.find_by!(name: "Ruby Retreat AU").locations.sole
      expect(retreat.coords.coordinates).to eq([151.2428673, -33.8560452])
    end

    it "imports organizations" do
      Seeds::Organization.sync

      expect(Organization.all).to include an_object_having_attributes(name: "Cookpad", twitter_handle: "cookpad_dev")
      expect(Location.count).to eq(Seeds::Organization.all.sum { |org| org.locations.size })
    end

    it "keeps the coordinates of existing locations and geocodes only new ones" do
      Seeds::Organization.sync
      location = Location.first
      location.update_columns(coords: "SRID=4326;POINT(10 20)")

      Seeds::Organization.sync

      expect(location.reload.coords.coordinates).to eq([10, 20])
      expect(Geocoder).to have_received(:search).exactly(Seeds::Organization.all.sum { |org| org.locations.count { |location| location["latitude"].nil? } }).times
    end

    it "removes organizations and locations that are no longer listed" do
      stale = create(:organization, name: "Gone")
      create(:location, organization: stale)

      Seeds::Organization.sync

      expect(Organization.exists?(name: "Gone")).to be(false)
      expect(Location.where(organization_id: stale.id)).to be_empty
    end
  end
end
