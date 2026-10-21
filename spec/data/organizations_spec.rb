require "rails_helper"

RSpec.describe "data/seeds/organizations.yml" do
  organizations = YAML.load_file(Rails.root.join("data/seeds/organizations.yml"))

  it "is sorted by name, ignoring case" do
    names = organizations.map { |organization| organization["name"] }
    expect(names).to eq(names.sort_by(&:downcase)), "Run bin/sort-orgs to sort data/seeds/organizations.yml"
  end

  it "has unique names" do
    names = organizations.map { |organization| organization["name"] }
    expect(names.tally.select { |_, count| count > 1 }.keys).to be_empty
  end

  organizations.each do |organization|
    describe organization["name"] do
      it "is a known type with at least one address" do
        expect(%w[business meetup event]).to include(organization["type"])
        expect(organization["locations"]).to all(include("address" => be_present))
      end

      it "links to an http or https URL, if any" do
        expect(organization["url"]).to match(%r{\Ahttps?://\S+\z}) if organization["url"]
      end

      it "has a short plain description, if any" do
        expect(organization["description"]).to match(/\A[^\n]{20,240}\z/) if organization["description"]
      end

      it "refers to images that exist" do
        %w[photo logo].each do |key|
          next unless organization[key]
          expect(Rails.root.join("app/assets/images/organizations", organization[key])).to exist
        end
      end
    end
  end
end
