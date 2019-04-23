json.type "FeatureCollection"
json.features @locations.each do |location|
  json.type "Feature"
  json.geometry do
  	json.type "Point"
  	json.coordinates location.coords.coordinates
  end
  json.properties do
    json.description location.organization.name.to_s + "\n" + location.organization.url.to_s + "\n" + location.address.to_s
  end
end