source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

gem "rails", "~> 7"

gem "active_hash"
gem "activerecord-postgis-adapter"
gem "geocoder"
gem "jbuilder", "~> 2.5"
gem "pg"
gem "puma", "~> 4.3"
gem "redis", "~> 4.0"
gem "sentry-raven"
gem "turbolinks", "~> 5"
gem "yamllint"

gem "importmap-rails"
gem "cssbundling-rails"
gem "sprockets-rails"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "standard"
  gem "listen"
end

group :development do
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "capybara", ">= 2.15"
  gem "launchy"
  gem "rails-controller-testing"
  gem "rspec_junit_formatter"
  gem "utensils", github: "balvig/utensils"
end
