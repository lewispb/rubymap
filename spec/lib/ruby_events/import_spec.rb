require "rails_helper"

RSpec.describe RubyEvents::Import do
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:directory_path) { root.join("organizations.yml") }
  let(:directory) { RubyMap::Directory.new(directory_path) }

  before do
    File.write(directory_path, [{"name" => "Bangkok.rb", "type" => "meetup", "url" => "https://www.meetup.com/bangkok-rb/", "locations" => [{"address" => "Bangkok"}]}].to_yaml)
    allow(RubyMap::ImageFile).to receive(:save) { |path, name:, kind:| "#{name.parameterize}-#{kind}.webp" }
    stub_const("RubyEvents::Import::IGNORED_PATH", root.join("ignored.yml"))
  end

  after { FileUtils.rm_rf(root) }

  def series(id, attributes, events)
    FileUtils.mkdir_p(root.join("data", id))
    File.write(root.join("data", id, "series.yml"), attributes.merge("id" => id).to_yaml)
    events.each do |event_id, event|
      FileUtils.mkdir_p(root.join("data", id, event_id))
      File.write(root.join("data", id, event_id, "event.yml"), event.to_yaml)
      FileUtils.mkdir_p(root.join("app/assets/images/events", id, event_id))
      FileUtils.touch(root.join("app/assets/images/events", id, event_id, "card.webp"))
    end
  end

  def import
    described_class.new(root, directory: directory, today: Date.new(2026, 10, 21)).run
  end

  it "adds a conference at its next edition with the RubyEvents coordinates and images" do
    series("rubykaigi", {"name" => "RubyKaigi", "kind" => "conference", "website" => "https://rubykaigi.org", "twitter" => "RubyKaigi"}, {
      "rubykaigi-2025" => {"start_date" => "2025-04-16", "location" => "Matsuyama, Japan", "coordinates" => {"latitude" => 33.8, "longitude" => 132.7}},
      "rubykaigi-2027" => {"start_date" => "2027-04-20", "location" => "Hakodate, Japan", "coordinates" => {"latitude" => 41.7, "longitude" => 140.7}}
    })

    result = import

    expect(result.added).to eq(["RubyKaigi"])
    expect(RubyMap::Directory.new(directory_path).find("RubyKaigi")).to include(
      "type" => "event", "url" => "https://rubykaigi.org", "twitter_handle" => "RubyKaigi", "source" => "rubyevents:rubykaigi",
      "photo" => "rubykaigi-photo.webp",
      "locations" => [{"address" => "Hakodate, Japan", "latitude" => 41.7, "longitude" => 140.7}]
    )
  end

  it "skips conferences with no edition since 2024 and online events" do
    series("old-conf", {"name" => "Old Conf", "kind" => "conference"}, {"old-conf-2015" => {"start_date" => "2015-01-01", "location" => "Paris", "coordinates" => {"latitude" => 48.8, "longitude" => 2.3}}})
    series("online-rb", {"name" => "Online.rb", "kind" => "meetup"}, {"online-rb-meetup" => {"location" => "online", "coordinates" => {"latitude" => 0, "longitude" => 0}}})

    expect(import.added).to be_empty
  end

  it "matches an existing entry by alias and only adds the source and images" do
    series("bangkok-rb", {"name" => "Bangkok Ruby", "kind" => "meetup", "aliases" => ["Bangkok.rb"]}, {"bangkok-rb-meetup" => {"location" => "Bangkok, Thailand", "coordinates" => {"latitude" => 13.7, "longitude" => 100.5}}})

    result = import

    expect(result.matched).to eq(["Bangkok.rb"])
    expect(RubyMap::Directory.new(directory_path).organizations.sole).to include(
      "name" => "Bangkok.rb", "source" => "rubyevents:bangkok-rb", "photo" => "bangkok-rb-photo.webp", "locations" => [{"address" => "Bangkok"}]
    )
  end

  it "skips ignored series" do
    File.write(root.join("ignored.yml"), ["tokyo-rb"].to_yaml)
    series("tokyo-rb", {"name" => "Tokyo.rb", "kind" => "meetup"}, {"tokyo-rb-meetup" => {"location" => "Tokyo", "coordinates" => {"latitude" => 35.6, "longitude" => 139.7}}})

    expect(import.added).to be_empty
  end
end
