require "rails_helper"

RSpec.describe Location, type: :model do
  describe "geocoding" do
    it "adds entropy to coordinates to prevent collisions" do
      allow(Geocoder).to receive(:search).and_return([double(coordinates: [1.123456, 2.123456], cache_hit: true)])

      location = create(:location)

      expect(location.coords.coordinates).to include(a_value_within(0.001).of(2.123456), 1.123456)
    end

    it "retries without leading address parts when the full address is not found" do
      allow(Geocoder).to receive(:search).and_return([])
      allow(Geocoder).to receive(:search).with("Surry Hills, Australia").and_return([double(coordinates: [-33.88, 151.21], cache_hit: true)])

      location = create(:location, address: "Level 6, 241 Commonwealth St, Surry Hills, Australia")

      expect(location.coords.coordinates).to include(-33.88)
      expect(Geocoder).to have_received(:search).with("Level 6, 241 Commonwealth St, Surry Hills, Australia").ordered
      expect(Geocoder).to have_received(:search).with("241 Commonwealth St, Surry Hills, Australia").ordered
    end

    it "keeps existing coordinates" do
      allow(Geocoder).to receive(:search).and_return([double(coordinates: [1, 2], cache_hit: true)])
      location = create(:location)

      location.update!(address: "Somewhere else")

      expect(Geocoder).to have_received(:search).once
    end

    it "is invalid when no part of the address is found" do
      allow(Geocoder).to receive(:search).and_return([])

      expect(build(:location, address: "Nowhere")).not_to be_valid
    end
  end
end
