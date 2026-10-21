namespace :rubyevents do
  desc "Add meetups and events from a local clone of github.com/rubyevents/rubyevents"
  task :import, [:path] => :environment do |_, args|
    abort "Usage: bin/rails rubyevents:import[path/to/rubyevents]" if args[:path].blank?

    result = RubyEvents::Import.new(args[:path]).run
    puts "Added #{result.added.size}, matched #{result.matched.size}, skipped #{result.skipped.size}."
    puts "Matched existing entries: #{result.matched.sort.join(", ")}" if result.matched.any?
  end
end
