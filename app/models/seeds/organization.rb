module Seeds
  # Syncs the database with data/seeds/organizations.yml. Existing locations keep
  # their coordinates; only new addresses are geocoded.
  class Organization < ActiveYaml::Base
    set_root_path "data"

    def self.sync
      all.each(&:sync)
      ::Organization.where.not(name: all.map(&:name)).destroy_all
    end

    def sync
      organization = ::Organization.find_or_initialize_by(name: name)
      organization.update!(org_type: type, url: url, twitter_handle: twitter_handle)
      organization.locations.where.not(address: addresses).destroy_all
      addresses.each { |address| sync_location(organization, address) }
    end

    private

    def addresses
      locations.map { |location| location["address"] }
    end

    def sync_location(organization, address)
      location = organization.locations.find_or_initialize_by(address: address)
      return if location.persisted? || location.save

      warn "Could not geocode #{address.inspect} for #{name}"
    end
  end
end
