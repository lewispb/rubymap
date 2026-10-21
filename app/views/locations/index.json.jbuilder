json.type "FeatureCollection"
json.features @locations do |location|
  json.cache! [location, location.organization] do
    json.partial! "location", location: location
  end
end
