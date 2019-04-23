json.type -"FeatureCollection"
json.features @locations do |location|
  json.cache! location do
    json.partial! "location", location: location
  end
end