json.type "Feature"
json.geometry do
  json.type "Point"
  json.coordinates location.coords.coordinates
end
json.properties do
  json.description render partial: 'description', formats: [:html], locals: { location: location }
end
