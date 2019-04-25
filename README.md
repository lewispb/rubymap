# Ruby Map

Whilst travelling to other cities I've often wondered: "What's going on in the local Ruby community?"
To answer this question, hopefully fellow Rubyists will share their organization / meetup / events and anyone interested will be able to discover the Ruby world around them!
Sometimes folks are interested in finding a new gig, in a new location. Ruby Map might be useful for that too, if companies share if they are hiring.

## Your company / meetup / event is missing?

What if your company / meetup / event is missing on the map? No problem, just send us a PR and it will get added asap.
An example PR can be found [here](https://github.com/lewispb/rubymap/pull/1).

## Prerequisites

```bash
brew install postgres
brew install postgis
brew install geos
```

Add PostGIS to postgres

```
rake db:gis:setup
```
