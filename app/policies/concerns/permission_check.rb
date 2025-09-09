module PermissionCheck
  extend ActiveSupport::Concern

  included do
    # nothing here yet
  end

  private

  def allow?(permission_key, record: nil)
    return false if permission_key.blank?

    organization = resolve_organization_from(record || try_record)
    actor = context_user
    return false unless actor && organization

    actor.has_permission?(permission_key, organization: organization)
  end

  # For controllers using as a mixin to gate actions directly
  def require_permission!(permission_key, record: nil)
    allowed = allow?(permission_key, record: record)
    raise Pundit::NotAuthorizedError unless allowed
    true
  end

  def context_user
    if defined?(user)
      user
    elsif respond_to?(:current_user)
      current_user
    else
      Current.user
    end
  end

  def try_record
    return record if defined?(record)
    nil
  end

  def resolve_organization_from(target)
    return Current.organization if Current.respond_to?(:organization) && Current.organization

    case target
    when Organization
      target
    when Role
      target.organization
    when Membership
      target.organization
    when nil
      Current.organization
    else
      if target.respond_to?(:organization)
        target.organization
      elsif target.respond_to?(:organization_id)
        Organization.find_by(id: target.organization_id)
      else
        Current.organization
      end
    end
  end
end


