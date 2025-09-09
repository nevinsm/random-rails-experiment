module AuthorizationHelper
  # Usage: can?("member.manage")
  def can?(permission_key, record: nil)
    actor = respond_to?(:current_user) ? current_user : Current.user
    return false unless actor

    organization = if record.respond_to?(:organization)
      record.organization
    else
      Current.organization
    end

    actor.has_permission?(permission_key, organization: organization)
  end

  # Passthrough to Pundit policy for views
  def policy(record)
    actor = respond_to?(:current_user) ? current_user : Current.user
    Pundit.policy!(actor, record)
  end
end


