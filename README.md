# Ruby Map

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

Whilst travelling to other cities I've often wondered: "What's going on in the local Ruby community?"
To answer this question, hopefully fellow Rubyists will share their organization / meetup / events and anyone interested will be able to discover the Ruby world around them!
Sometimes folks are interested in finding a new gig, in a new location. Ruby Map might be useful for that too, if companies share if they are hiring.

## Your company / meetup / event is missing?

What if your company / meetup / event is missing on the map? No problem, just send us a PR and it will get added asap.
An example PR can be found [here](https://github.com/lewispb/rubymap/pull/1).

Please try to maintain the order-by-name of the yaml file, to prevent merge conflicts.

## Prerequisites

```bash
brew install redis
brew install postgres
brew install postgis
brew install geos
```

Add PostGIS to postgres

```
rake db:gis:setup
```

### Development server

```
bin/dev
```
