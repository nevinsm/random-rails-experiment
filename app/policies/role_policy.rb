class RolePolicy < ApplicationPolicy
  include PermissionCheck

  def index?
    allow?("role.manage")
  end

  def show?
    allow?("role.read")
  end

  def create?
    allow?("role.manage")
  end

  def update?
    allow?("role.manage")
  end

  def destroy?
    allow?("role.manage")
  end
end


