class Permission < ApplicationRecord
  has_paper_trail only: %i[name description], ignore: %i[key]
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
end


