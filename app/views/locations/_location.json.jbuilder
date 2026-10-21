organization = location.organization

json.type "Feature"
json.id location.id
json.geometry do
  json.type "Point"
  json.coordinates location.coords.coordinates
end
json.properties do
  json.name organization.name
  json.type organization.org_type
  json.url organization.url
  json.twitter_handle organization.twitter_handle
  json.address location.address
  json.description organization.description
  json.photo organization.photo && image_url("organizations/#{organization.photo}")
  json.logo organization.logo && image_url("organizations/#{organization.logo}")
  json.source organization.source
end
