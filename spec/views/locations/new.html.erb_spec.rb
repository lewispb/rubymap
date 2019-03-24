require 'rails_helper'

RSpec.describe "locations/new", type: :view do
  before(:each) do
    assign(:location, Location.new(
      :address => "MyString",
      :organization => nil,
      :coords => "MyString"
    ))
  end

  it "renders new location form" do
    render

    assert_select "form[action=?][method=?]", locations_path, "post" do

      assert_select "input[name=?]", "location[address]"

      assert_select "input[name=?]", "location[organization_id]"

      assert_select "input[name=?]", "location[coords]"
    end
  end
end
