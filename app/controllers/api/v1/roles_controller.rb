class Api::V1::RolesController < Api::V1::BaseController
  def index
    authorize Role

    roles = Current.organization.roles.order(system: :desc, name: :asc)
    total = roles.count
    roles = paginate(roles)

    render json: {
      roles: roles.map { |r| serialize_role(r) },
      meta: pagination_meta(total: total, page: (params[:page] || 1).to_i, per: ((params[:per] || 25).to_i.clamp(1, 100)))
    }
  end

  def create
    authorize Role

    role = Current.organization.roles.new(role_params.merge(system: false))
    if role.save
      assign_permissions(role)
      AuditLogger.log(event_type: "role.created", resource: role, metadata: { after: role.attributes, ip: request.remote_ip })
      render json: serialize_role(role), status: :created
    else
      render json: { error: role.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  def update
    role = find_role
    authorize role

    before_attrs = role.attributes
    if role.update(role_params.except(:permission_ids))
      assign_permissions(role)
      AuditLogger.log(event_type: "role.updated", resource: role, metadata: { before: before_attrs, after: role.attributes, ip: request.remote_ip })
      render json: serialize_role(role)
    else
      render json: { error: role.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  def destroy
    role = find_role
    authorize role

    if role.system?
      return render json: { error: "System roles cannot be deleted." }, status: :unprocessable_content
    end
    if role.memberships.exists?
      return render json: { error: "Role is assigned to members and cannot be deleted." }, status: :unprocessable_content
    end

    before_attrs = role.attributes
    role.destroy!
    AuditLogger.log(event_type: "role.deleted", resource: role, metadata: { before: before_attrs, ip: request.remote_ip })
    head :no_content
  end

  private

  def find_role
    Current.organization.roles.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :key, permission_ids: [])
  end

  def assign_permissions(role)
    ids = Array(role_params[:permission_ids]).reject(&:blank?).map(&:to_i)
    role.role_permissions.where.not(permission_id: ids).delete_all
    new_ids = ids - role.permissions.pluck(:id)
    RolePermission.insert_all!(new_ids.map { |pid| { role_id: role.id, permission_id: pid, created_at: Time.current, updated_at: Time.current } }) if new_ids.any?
  end

  def serialize_role(role)
    { id: role.id, name: role.name, key: role.key, system: role.system }
  end
end


