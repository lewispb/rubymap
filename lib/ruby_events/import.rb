module RubyEvents
  # Adds meetups and events from a local clone of the RubyEvents repository
  # (https://github.com/rubyevents/rubyevents) to data/seeds/organizations.yml.
  #
  # Each series becomes one organization at the place of its next edition, or
  # its latest one. Conferences without an edition since ACTIVE_SINCE are
  # skipped. Entries that already exist keep their details and only gain the
  # RubyEvents source and any missing images.
  class Import
    KINDS = {
      "meetup" => "meetup", "organisation" => "meetup",
      "conference" => "event", "retreat" => "event", "hackathon" => "event", "workshop" => "event", "event" => "event"
    }
    ACTIVE_SINCE = Date.new(2024, 1, 1)
    IGNORED_PATH = Rails.root.join("data/seeds/rubyevents_ignored.yml")

    Result = Struct.new(:added, :matched, :skipped)

    def initialize(root, directory: RubyMap::Directory.new, today: Date.current)
      @root = Pathname(root)
      @directory = directory
      @today = today
      @ignored = IGNORED_PATH.exist? ? YAML.load_file(IGNORED_PATH).to_a : []
      @result = Result.new(added: [], matched: [], skipped: [])
    end

    def run
      Dir[@root.join("data/*/series.yml")].sort.each { |path| import_series(Pathname(path).dirname) }
      @directory.save
      @result
    end

    private

    def import_series(directory)
      series = YAML.load_file(directory.join("series.yml"))
      source = "rubyevents:#{series["id"]}"
      type = KINDS[series["kind"]]
      edition = edition_for(directory, type)

      return @result.skipped << series["id"] if type.nil? || edition.nil? || @ignored.include?(series["id"])

      if (existing = match(series, source))
        enrich(existing, series, edition, source)
        @result.matched << existing["name"]
      else
        @directory.add(organization_for(series, edition, type, source))
        @result.added << series["name"]
      end
    end

    def edition_for(directory, type)
      editions = Dir[directory.join("*/event.yml")].filter_map do |path|
        event = YAML.load_file(path)
        next unless coordinates(event) && !event["location"].to_s.casecmp?("online")

        venue_path = Pathname(path).dirname.join("venue.yml")
        event.merge("directory" => Pathname(path).dirname, "venue" => (YAML.load_file(venue_path) if venue_path.exist?))
      end

      return editions.first if type == "meetup"

      dated = editions.select { |event| event["start_date"] }.sort_by { |event| Date.parse(event["start_date"].to_s) }
      upcoming = dated.find { |event| Date.parse(event["start_date"].to_s) >= @today }
      latest = upcoming || dated.last
      latest if latest && Date.parse(latest["start_date"].to_s) >= ACTIVE_SINCE
    end

    def match(series, source)
      urls = [series["website"], series["meetup"]].compact_blank.map { |url| normalize_url(url) }
      names = [series["name"], *series["aliases"]].map { |name| normalize_name(name) }

      @directory.organizations.find { |organization| organization["source"] == source } ||
        @directory.organizations.find { |organization| urls.include?(normalize_url(organization["url"])) } ||
        @directory.organizations.find { |organization| names.include?(normalize_name(organization["name"])) }
    end

    def enrich(organization, series, edition, source)
      organization["source"] ||= source
      organization["photo"] ||= save_image(series, edition, "card.webp", organization["name"], :photo)
      organization["logo"] ||= save_image(series, edition, "avatar.webp", organization["name"], :logo)
    end

    def organization_for(series, edition, type, source)
      coordinates = coordinates(edition["venue"]) || coordinates(edition)

      {
        "name" => series["name"],
        "type" => type,
        "url" => series["website"].presence || edition["website"].presence || "https://www.rubyevents.org/events/#{series["id"]}",
        "twitter_handle" => series["twitter"].presence,
        "photo" => save_image(series, edition, "card.webp", series["name"], :photo),
        "logo" => save_image(series, edition, "avatar.webp", series["name"], :logo),
        "source" => source,
        "locations" => [{
          "address" => edition.dig("venue", "address", "display").presence || edition["location"],
          "latitude" => coordinates["latitude"].to_f,
          "longitude" => coordinates["longitude"].to_f
        }]
      }
    end

    def save_image(series, edition, filename, name, kind)
      images = @root.join("app/assets/images/events", series["id"])
      path = [images.join(edition["directory"].basename, filename), images.join("default", filename)].find(&:exist?)
      RubyMap::ImageFile.save(path, name: name, kind: kind) if path
    end

    def coordinates(record)
      coordinates = record["coordinates"] if record.is_a?(Hash)
      coordinates if coordinates.is_a?(Hash) && coordinates["latitude"] && coordinates["longitude"]
    end

    def normalize_url(url)
      url.to_s.downcase.sub(%r{\Ahttps?://}, "").sub(/\Awww\./, "").sub(%r{\Ameetup\.com/en(-[a-z]+)?/}, "meetup.com/").sub(%r{/(events/?)?\z}, "")
    end

    def normalize_name(name)
      name.to_s.downcase.gsub(/[^\p{L}\p{N}]/, "")
    end
  end
end
