class RolePermission < ApplicationRecord
  has_paper_trail
  belongs_to :role
  belongs_to :permission

  validates :role_id, uniqueness: { scope: :permission_id }
end


