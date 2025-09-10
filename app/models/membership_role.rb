class MembershipRole < ApplicationRecord
  has_paper_trail
  belongs_to :membership
  belongs_to :role

  validates :membership_id, uniqueness: { scope: :role_id }
end


