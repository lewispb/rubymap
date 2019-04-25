class Organization < ApplicationRecord
  validates :name, presence: true
  enum org_type: { business: :business, meetup: :meetup }
end
