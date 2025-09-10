module SetsCurrentOrganization
  extend ActiveSupport::Concern

  included do
    before_action :set_current_organization
  end

  private

  def set_current_organization(*_args, **_kwargs, &_block)
    return unless current_user

    organization = find_organization_from_params || find_organization_from_user

    if organization
      ensure_membership!(current_user, organization)
    end

    Current.organization = organization
  end

  def find_organization_from_params
    org_id = params[:organization_id] || params[:org_id] || params[:slug]
    return nil if org_id.blank?

    Organization.find_by(id: org_id) || Organization.find_by(slug: org_id)
  end

  def find_organization_from_user
    return nil if current_user.last_active_organization_id.blank?
    Organization.find_by(id: current_user.last_active_organization_id)
  end

  def ensure_membership!(user, organization)
    Membership.find_or_create_by!(user: user, organization: organization) do |m|
      m.status = "active"
      m.invited_by_id = organization.owner_id
    end
  end
end


