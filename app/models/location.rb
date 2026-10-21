class Location < ApplicationRecord
  NOMINATIM_INTERVAL = 1.second

  belongs_to :organization
  validates :coords, presence: true

  before_validation :geocode_address, if: -> { coords.blank? }

  private

  def geocode_address
    return if geocoded_coords.blank?

    self.coords = "SRID=4326;POINT(#{geocoded_coords_with_entropy.join(" ")})"
  end

  def geocoded_coords_with_entropy
    [geocoded_coords[0].round(5) + rand(0.0001..0.0009), geocoded_coords[1]]
  end

  def geocoded_coords
    @_geocoded_coords ||= address_candidates.lazy.filter_map { |query| geocode(query) }.first&.coordinates&.reverse
  end

  # Nominatim matches structured addresses better than it matches floor and
  # suite details, so retry with leading parts removed: "Level 6, 241 Commonwealth St,
  # Surry Hills" is retried as "241 Commonwealth St, Surry Hills", then "Surry Hills".
  def address_candidates
    parts = address.to_s.split(",").map(&:strip).reject(&:blank?)
    parts.size.times.map { |index| parts.drop(index).join(", ") }
  end

  def geocode(query)
    Geocoder.search(query).first.tap do |result|
      sleep NOMINATIM_INTERVAL unless result&.cache_hit
    end
  end
end
