# Ruby Map

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

Whilst travelling to other cities I've often wondered: "What's going on in the local Ruby community?"
To answer this question, hopefully fellow Rubyists will share their organization / meetup / events and anyone interested will be able to discover the Ruby world around them!
Sometimes folks are interested in finding a new gig, in a new location. Ruby Map might be useful for that too, if companies share if they are hiring.

## Your company / meetup / event is missing?

What if your company / meetup / event is missing on the map? No problem, just send us a PR and it will get added asap.
An example PR can be found [here](https://github.com/lewispb/rubymap/pull/1).

Please try to maintain the order-by-name of the yaml file, to prevent merge conflicts.

## Development

Ruby Map is a Rails app backed by PostgreSQL with PostGIS. The map is drawn with
[MapLibre GL JS](https://maplibre.org) using [OpenFreeMap](https://openfreemap.org)
tiles of [OpenStreetMap](https://www.openstreetmap.org) data, and addresses are
geocoded with [Nominatim](https://nominatim.org). None of these need an API key.

You need Ruby (see `.ruby-version`) and Docker. Start PostGIS, then set up the app:

```bash
docker compose up -d
bin/setup
```

`bin/setup` creates the database and starts the server at http://localhost:3000.
To load the organizations, run:

```bash
bin/rails db:seed
```

Seeding geocodes each address once, at one request per second, so a first run
takes about five minutes. Later runs only geocode addresses that are new.

Run the tests and linters with:

```bash
bundle exec rspec
bundle exec standardrb
bundle exec rake yamllint
```

## Deployment

The app runs on Dokku with the Heroku Ruby buildpack pinned in `.buildpacks`.
On each deploy, the `release` process in `Procfile` runs migrations and syncs
`data/seeds/organizations.yml` into the database. Existing locations keep their
coordinates and only new addresses are geocoded.

It expects `DATABASE_URL` (PostgreSQL with PostGIS), `REDIS_URL`,
`RAILS_MASTER_KEY` and, optionally, `SENTRY_DSN`.
