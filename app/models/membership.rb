class Membership < ApplicationRecord
  has_paper_trail
  belongs_to :user
  belongs_to :organization
  belongs_to :invited_by, class_name: "User", optional: true

  STATUSES = ["active", "invited", "disabled"].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :organization_id }

  has_many :membership_roles, dependent: :destroy
  has_many :roles, through: :membership_roles
end


