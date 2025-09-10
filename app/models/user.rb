class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :owned_organizations, class_name: "Organization", foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  def has_permission?(key, organization:)
    return false if key.blank? || organization.nil?

    # Owners have full permissions within their organizations
    return true if organization.owner_id == id

    membership = memberships.find_by(organization_id: organization.id)
    return false unless membership

    Role
      .joins(:permissions, :membership_roles)
      .where(membership_roles: { membership_id: membership.id })
      .where(permissions: { key: key })
      .exists?
  end
end
