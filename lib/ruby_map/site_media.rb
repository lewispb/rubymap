require "image_processing/vips"
require "net/http"

module RubyMap
  # Fetches an organization's website and saves its share image (og:image) as
  # the card photo and its largest icon as the logo. It identifies itself,
  # respects robots.txt and skips meetup.com, whose terms forbid copying.
  class SiteMedia
    USER_AGENT = "RubyMap/1.0 (+https://www.rubymap.com)"
    SKIPPED_HOSTS = /(\A|\.)meetup\.com\z/
    MAX_BYTES = 5.megabytes
    MIN_PHOTO_WIDTH = 400
    MIN_LOGO_WIDTH = 64

    Result = Struct.new(:photo, :logo, :title, :description, :error)

    def initialize(url)
      @url = URI.parse(url.to_s.match?(%r{\Ahttps?://}) ? url.to_s : "https://#{url}")
    end

    def fetch(name:, photo: true, logo: true)
      return Result.new(error: "skipped host") if @url.host.to_s.match?(SKIPPED_HOSTS)
      return Result.new(error: "disallowed by robots.txt") unless allowed?(@url)

      response, page_url = get(@url)
      return Result.new(error: "HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

      document = Nokogiri::HTML(response.body)
      Result.new(
        title: document.at("title")&.text&.squish,
        description: meta(document, "og:description") || meta(document, "description"),
        photo: (save_photo(document, page_url, name) if photo),
        logo: (save_logo(document, page_url, name) if logo)
      )
    rescue => error
      Result.new(error: "#{error.class}: #{error.message.truncate(80)}")
    end

    private

    def save_photo(document, page_url, name)
      candidates = [meta(document, "og:image"), meta(document, "twitter:image")].compact
      save_first(candidates, page_url, name, :photo, MIN_PHOTO_WIDTH)
    end

    def save_logo(document, page_url, name)
      icons = document.css("link[rel~='apple-touch-icon'], link[rel~='apple-touch-icon-precomposed'], link[rel~='icon']").map do |link|
        size = link["sizes"].to_s[/\d+/].to_i
        size = 512 if link["type"] == "image/svg+xml" || link["href"].to_s.end_with?(".svg")
        [link["href"], size]
      end
      candidates = icons.sort_by { |_, size| -size }.map(&:first) + ["/apple-touch-icon.png"]
      save_first(candidates.reject { |href| href.to_s.end_with?(".ico") }, page_url, name, :logo, MIN_LOGO_WIDTH)
    end

    def save_first(candidates, page_url, name, kind, min_width)
      candidates.uniq.each do |href|
        file = download(URI.join(page_url, href.strip))
        next unless file

        image = Vips::Image.new_from_file(file.path)
        next if image.width < min_width || generic?(href)

        return ImageFile.save(file.path, name: name, kind: kind)
      rescue Vips::Error, URI::Error, ArgumentError
        next
      ensure
        file&.close!
      end
      nil
    end

    def generic?(href)
      href.include?("meetup-flyer") || href.include?("default-share")
    end

    def download(uri)
      return unless uri.is_a?(URI::HTTP) && allowed?(uri)

      response, _ = get(uri)
      return unless response.is_a?(Net::HTTPSuccess) && response.body.bytesize <= MAX_BYTES && response["content-type"].to_s.start_with?("image/")

      Tempfile.new(["rubymap", File.extname(uri.path).presence || ".img"], binmode: true).tap do |file|
        file.write(response.body)
        file.flush
      end
    end

    def get(uri, redirects = 5)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.get(uri.request_uri, "User-Agent" => USER_AGENT, "Accept" => "text/html,image/*;q=0.9,*/*;q=0.8")
      end

      if response.is_a?(Net::HTTPRedirection) && redirects.positive?
        get(URI.join(uri, response["location"]), redirects - 1)
      else
        [response, uri]
      end
    end

    def meta(document, name)
      document.at("meta[property='#{name}'], meta[name='#{name}']")&.[]("content")&.squish.presence
    end

    # Reads the rules for all user agents, and for RubyMap if named.
    def allowed?(uri)
      @robots ||= {}
      rules = @robots[uri.host] ||= begin
        response, _ = get(URI.join(uri, "/robots.txt"))
        response.is_a?(Net::HTTPSuccess) ? disallowed_paths(response.body) : []
      rescue
        []
      end
      rules.none? { |path| uri.path.presence.to_s.start_with?(path) || (path == "/" && uri.path.blank?) }
    end

    def disallowed_paths(body)
      groups = body.split(/^\s*user-agent:/i).drop(1)
      group = groups.find { |text| text.lines.first.to_s.strip.casecmp?("rubymap") } ||
        groups.find { |text| text.lines.first.to_s.strip == "*" }
      group.to_s.scan(/^\s*disallow:\s*(\S+)/i).flatten
    end
  end
end
