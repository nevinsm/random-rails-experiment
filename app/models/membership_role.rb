class MembershipRole < ApplicationRecord
  belongs_to :membership
  belongs_to :role

  validates :membership_id, uniqueness: { scope: :role_id }
end


