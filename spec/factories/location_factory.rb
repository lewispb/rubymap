FactoryBot.define do
  factory :location do
    association :organization
    address { "Bristol, UK" }
  end
end