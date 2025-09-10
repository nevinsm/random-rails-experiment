class Admin::RolesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Role

    @roles = Current.organization
      .roles
      .includes(:permissions)
      .order(system: :desc, name: :asc)
  end

  def show
    @role = find_role
    authorize @role
  end

  def new
    authorize Role
    @role = Current.organization.roles.new
  end

  def create
    authorize Role
    @role = Current.organization.roles.new(role_params.merge(system: false))

    if @role.save
      assign_permissions(@role)
      AuditLogger.log(
        event_type: "role.created",
        resource: @role,
        metadata: { after: @role.attributes, ip: request.remote_ip }
      )
      respond_to do |format|
        format.html { redirect_to admin_roles_path, notice: "Role created." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @role = find_role
    authorize @role
  end

  def update
    @role = find_role
    authorize @role

    before_attrs = @role.attributes
    if @role.update(role_params.except(:permission_ids))
      assign_permissions(@role)
      AuditLogger.log(
        event_type: "role.updated",
        resource: @role,
        metadata: { before: before_attrs, after: @role.attributes, ip: request.remote_ip }
      )
      respond_to do |format|
        format.html { redirect_to admin_roles_path, notice: "Role updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @role = find_role
    authorize @role

    if @role.system?
      return redirect_to admin_roles_path, alert: "System roles cannot be deleted."
    end

    if @role.memberships.exists?
      return redirect_to admin_roles_path, alert: "Role is assigned to members and cannot be deleted."
    end

    before_attrs = @role.attributes
    @role.destroy!
    AuditLogger.log(
      event_type: "role.deleted",
      resource: @role,
      metadata: { before: before_attrs, ip: request.remote_ip }
    )
    respond_to do |format|
      format.html { redirect_to admin_roles_path, notice: "Role deleted." }
      format.turbo_stream
    end
  end

  private

  def find_role
    Current.organization.roles.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :key, :system, permission_ids: [])
  end

  def assign_permissions(role)
    ids = Array(role_params[:permission_ids]).reject(&:blank?).map(&:to_i)
    role.role_permissions.where.not(permission_id: ids).delete_all
    new_ids = ids - role.permissions.pluck(:id)
    RolePermission.insert_all!(
      new_ids.map { |pid| { role_id: role.id, permission_id: pid, created_at: Time.current, updated_at: Time.current } }
    ) if new_ids.any?
  end
end


