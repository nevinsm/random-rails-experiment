class Role < ApplicationRecord
  has_paper_trail
  belongs_to :organization

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  has_many :membership_roles, dependent: :destroy
  has_many :memberships, through: :membership_roles

  validates :name, presence: true
  validates :key, presence: true
  validates :key, uniqueness: { scope: :organization_id }
  validates :name, uniqueness: { scope: :organization_id }

  scope :system, -> { where(system: true) }
end


