require 'rails_helper'

RSpec.describe "locations/show", type: :view do
  before(:each) do
    @location = assign(:location, Location.create!(
      :address => "Address",
      :organization => nil,
      :coords => "Coords"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Address/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Coords/)
  end
end
