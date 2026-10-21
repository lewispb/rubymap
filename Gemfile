source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1.4"

gem "active_hash"
gem "activerecord-postgis-adapter"
gem "bootsnap", require: false
gem "geocoder"
gem "importmap-rails"
gem "jbuilder"
gem "pg"
gem "propshaft"
gem "puma"
gem "redis"
gem "sentry-rails"
gem "sentry-ruby"
gem "yamllint"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "image_processing", require: false
  gem "ruby-vips", require: false
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "standard"
end

group :development do
  gem "web-console"
end
