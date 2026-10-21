json.type "Feature"
json.id location.id
json.geometry do
  json.type "Point"
  json.coordinates location.coords.coordinates
end
json.properties do
  json.name location.organization.name
  json.type location.organization.org_type
  json.url location.organization.url
  json.twitter_handle location.organization.twitter_handle
  json.address location.address
end
