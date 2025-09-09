class AuditPolicy < ApplicationPolicy
  include PermissionCheck

  def index?
    allow?("audit.read")
  end
end


