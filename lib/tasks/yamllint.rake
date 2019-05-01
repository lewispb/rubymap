require "yamllint/rake_task"

YamlLint::RakeTask.new do |t|
  t.paths = %w(
    data/**/*.yml
  )
end
