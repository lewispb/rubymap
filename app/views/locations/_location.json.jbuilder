json.type "Feature"
json.geometry do
  json.type "Point"
  json.coordinates location.coords.coordinates
end
json.properties do
  json.description render partial: 'locations/description.html.erb', locals: { location: location }
end