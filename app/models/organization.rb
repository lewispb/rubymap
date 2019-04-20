class Organization < ApplicationRecord
    enum org_type: { business: :business }
end
