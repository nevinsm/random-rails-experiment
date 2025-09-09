class OrganizationPolicy < ApplicationPolicy
  include PermissionCheck

  def show?
    allow?("org.read")
  end

  def update?
    allow?("org.update")
  end

  # Anyone authenticated can create an organization
  def create?
    user.present?
  end
end


