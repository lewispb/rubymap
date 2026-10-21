class Organization < ApplicationRecord
  has_many :locations, dependent: :destroy

  validates :name, presence: true
  enum :org_type, {business: "business", meetup: "meetup", event: "event"}
end
