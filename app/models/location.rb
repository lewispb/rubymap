class Location < ApplicationRecord
  belongs_to :organization
  validates :coords, presence: true

  before_validation :geocode_address

  def self.import(organization:, address:)
    new(organization: organization, address: address).save!
  end

  private

  def geocode_address
    self.coords = "SRID=4326;POINT(#{geocoded_coords_with_entropy.join(" ")})"
  end

  def geocoded_coords_with_entropy
    [geocoded_coords[0].round(5) + rand(0.0001..0.0009), geocoded_coords[1]]
  end

  def geocoded_coords
    @_geocoded_coords ||= Geocoder.search(address).first&.coordinates.reverse
  end
end
