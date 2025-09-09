class MemberPolicy < ApplicationPolicy
  include PermissionCheck

  def index?
    allow?("member.read")
  end

  def create?
    allow?("member.invite")
  end

  def update?
    allow?("member.manage")
  end

  def destroy?
    allow?("member.manage")
  end
end


