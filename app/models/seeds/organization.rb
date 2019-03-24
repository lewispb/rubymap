module Seeds
  class Organization < ActiveYaml::Base
  	set_root_path "data"

  	def import
      locations.each do |location|
        Location.create!(
          organization: organization,
          address: location["address"],
          coords: "POINT(#{geocoded_coords(location["address"]).join(" ")})"
        )
      end
  	end

    private

      def organization
        @_organization ||= ::Organization.create(name: name)
      end

      def geocoded_coords(address)
        Geocoder.search(address).first&.coordinates
      end
  end
end