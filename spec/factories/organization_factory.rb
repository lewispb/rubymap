FactoryBot.define do
  factory :organization do
    name { "My Org" }
    org_type { :meetup }
    url { "https://www.example.com" }
    twitter_handle { "example" }
  end
end