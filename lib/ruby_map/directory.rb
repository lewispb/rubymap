module RubyMap
  # Reads and writes data/seeds/organizations.yml, keeping entries sorted by
  # name and their keys in a fixed order so diffs stay small.
  class Directory
    PATH = Rails.root.join("data/seeds/organizations.yml")
    KEYS = %w[name type url twitter_handle description photo logo source locations]

    attr_reader :organizations

    def initialize(path = PATH)
      @path = path
      @organizations = YAML.load_file(path)
    end

    def find(name)
      organizations.find { |organization| organization["name"] == name }
    end

    def add(organization)
      organizations << organization
    end

    def save
      sorted = organizations.sort_by { |organization| organization["name"].downcase }
      File.write(@path, sorted.map { |organization| tidy(organization) }.to_yaml(line_width: -1))
    end

    private

    def tidy(organization)
      organization.compact.sort_by { |key, _| KEYS.index(key) || KEYS.size }.to_h
    end
  end
end
