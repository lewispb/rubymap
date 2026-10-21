# Addresses are geocoded with OpenStreetMap's Nominatim service. Its usage
# policy requires an identifying User-Agent and at most one request per second,
# which Location enforces between uncached lookups.
# https://operations.osmfoundation.org/policies/nominatim/
Geocoder.configure(
  lookup: :nominatim,
  timeout: 10,
  http_headers: {"User-Agent" => "Ruby Map (https://www.rubymap.com)"},
  cache: Rails.cache,
  cache_options: {prefix: "geocoder:nominatim:"}
)
