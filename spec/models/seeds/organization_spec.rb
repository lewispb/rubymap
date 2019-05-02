require 'rails_helper'

RSpec.describe Seeds::Organization do
  before do
    allow(Geocoder).to receive(:search).and_return([double(coordinates: [0, 0])])
  end

  describe '.import' do
    it "imports organizations" do
      Seeds::Organization.import
      expect(Organization.all).to include an_object_having_attributes(name: "Cookpad", twitter_handle: "cookpad_dev")
    end
  end
end
