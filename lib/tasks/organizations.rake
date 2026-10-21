namespace :organizations do
  desc "Fetch photos and logos from organization websites for entries that have none"
  task media: :environment do
    directory = RubyMap::Directory.new
    pending = directory.organizations.select { |organization| organization["photo"].nil? || organization["logo"].nil? }
    queue = Queue.new.tap { |q| pending.each { |organization| q << organization } }.tap(&:close)
    results = Concurrent::Map.new

    8.times.map do
      Thread.new do
        while (organization = queue.pop)
          results[organization["name"]] = RubyMap::SiteMedia.new(organization["url"])
            .fetch(name: organization["name"], photo: organization["photo"].nil?, logo: organization["logo"].nil?)
        end
      end
    end.each(&:join)

    pending.each do |organization|
      result = results[organization["name"]]
      organization["photo"] ||= result.photo
      organization["logo"] ||= result.logo
      puts "#{organization["name"]}: #{result.error}" if result.error
    end
    directory.save

    text = results.each_pair.to_h { |name, result| [name, {title: result.title, description: result.description}] }
    File.write(Rails.root.join("tmp/organization_text.json"), JSON.pretty_generate(text))
    puts "Photos: #{pending.count { it["photo"] }} of #{pending.size}. Logos: #{pending.count { it["logo"] }} of #{pending.size}."
  end
end
