require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:location) { create(:location) }

  describe "callbacks" do
    it "adds entropy to coordinates to prevent collisions" do
      allow(Geocoder).to receive(:search).and_return([double(coordinates: [1.123456, 2.123456])])

      expect(location.coords.coordinates).to include(a_value_within(0.001).of(2.123456), 1.123456)
    end
  end
end
