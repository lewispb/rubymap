module Seeds
  # Syncs the database with data/seeds/organizations.yml. Existing locations keep
  # their coordinates; new locations use the coordinates given in the YAML or are
  # geocoded from their address.
  class Organization < ActiveYaml::Base
    set_root_path "data"

    def self.sync
      all.each(&:sync)
      ::Organization.where.not(name: all.map(&:name)).destroy_all
    end

    def sync
      organization = ::Organization.find_or_initialize_by(name: name)
      organization.update!(details)
      organization.locations.where.not(address: addresses).destroy_all
      locations.each { |location| sync_location(organization, location) }
    end

    private

    def details
      {
        org_type: type,
        url: url,
        twitter_handle: attributes[:twitter_handle],
        description: attributes[:description],
        photo: attributes[:photo],
        logo: attributes[:logo],
        source: attributes[:source]
      }
    end

    def addresses
      locations.map { |location| location["address"] }
    end

    def sync_location(organization, attributes)
      location = organization.locations.find_or_initialize_by(address: attributes["address"])
      return if location.persisted?

      if attributes["latitude"] && attributes["longitude"]
        location.coords = "SRID=4326;POINT(#{attributes["longitude"]} #{attributes["latitude"]})"
      end

      warn "Could not geocode #{location.address.inspect} for #{name}" unless location.save
    end
  end
end
