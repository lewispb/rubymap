json.type "FeatureCollection"
json.features @locations.each do |location|
  json.type "Feature"
  json.geometry do
  	json.type "Point"
  	json.coordinates location.coords.coordinates
  end
  json.properties do
    json.description do
      location.organization.name + "\n" + location.organization.url + "\n" + location.address
    end
  end
end