require "rails_helper"

RSpec.describe "Location" do
  it "returns json" do
    get "/locations.json"
    expect_json_response("type").to eq("FeatureCollection")
  end
end