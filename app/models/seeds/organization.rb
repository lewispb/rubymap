module Seeds
  class Organization < ActiveYaml::Base
  	set_root_path "data"

    def self.import
      all.each(&:import)
    end

  	def import
      locations.each do |location|
        Location.find_or_create_by!(organization: organization, address: location["address"]) do |location|
          location.coords = "SRID=4326;POINT(#{geocoded_coords(location["address"]).reverse.join(" ")})"
        end
      end
  	end

    private

      def organization
        @_organization ||= ::Organization.find_or_create_by!(name: name) do |organization|
          organization.org_type = type
          organization.url = url
          organization.twitter_handle = twitter_handle
        end
      end

      def geocoded_coords(address)
        Geocoder.search(address).first&.coordinates
      end
  end
end
