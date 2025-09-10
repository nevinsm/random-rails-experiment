class Api::V1::MembershipRolesController < Api::V1::BaseController
  def create
    membership = Current.organization.memberships.find(params[:id])
    authorize membership, policy_class: MemberPolicy

    role = Current.organization.roles.find(params[:role_id] || params.dig(:role, :id))
    membership_role = MembershipRole.create!(membership: membership, role: role)
    AuditLogger.log(event_type: "member.role_assigned", resource: membership_role, metadata: { after: { membership_id: membership.id, role_id: role.id }, ip: request.remote_ip })

    render json: { ok: true, role_id: role.id }
  end

  def destroy
    membership_role = MembershipRole.find_by!(membership_id: params[:id], role_id: params[:role_id])
    authorize membership_role.membership, policy_class: MemberPolicy

    membership_role.destroy!
    AuditLogger.log(event_type: "member.role_unassigned", resource: membership_role, metadata: { before: { membership_id: membership_role.membership_id, role_id: membership_role.role_id }, ip: request.remote_ip })

    head :no_content
  end
end


