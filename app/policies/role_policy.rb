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
    return false if record.system?
    allow?("role.manage")
  end

  def destroy?
    # Allow access to the action; controller enforces system-role guardrails
    allow?("role.manage")
  end
end


