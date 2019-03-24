require 'rails_helper'

RSpec.describe "locations/index", type: :view do
  before(:each) do
    assign(:locations, [
      Location.create!(
        :address => "Address",
        :organization => nil,
        :coords => "Coords"
      ),
      Location.create!(
        :address => "Address",
        :organization => nil,
        :coords => "Coords"
      )
    ])
  end

  it "renders a list of locations" do
    render
    assert_select "tr>td", :text => "Address".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Coords".to_s, :count => 2
  end
end
