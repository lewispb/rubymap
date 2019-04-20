json.type "FeatureCollection"
json.features @locations.each do |location|
  json.type "Feature"
  json.geometry do
  	json.type "Point"
  	json.coordinates location.coords.coordinates
  end
  json.properties do
  	json.description location.organization.name + " " + location.address
  end
end