json.extract! location, :id, :address, :organization_id, :coords, :created_at, :updated_at
json.url location_url(location, format: :json)
