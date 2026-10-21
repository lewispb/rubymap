require "rails_helper"

RSpec.describe "Locations" do
  before do
    allow(Geocoder).to receive(:search).and_return([double(coordinates: [51.45, -2.58], cache_hit: true)])
  end

  it "renders the map" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="map"')
  end

  it "returns locations as GeoJSON" do
    create(:location, address: "Bristol, UK")

    get "/locations.json"

    json = JSON.parse(response.body)
    expect(json["type"]).to eq("FeatureCollection")
    expect(json["features"].first).to include(
      "geometry" => include("coordinates" => [a_value_within(0.001).of(-2.58), 51.45]),
      "properties" => include("name" => "My Org", "type" => "meetup", "address" => "Bristol, UK", "twitter_handle" => "example")
    )
  end
end
