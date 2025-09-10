class Admin::MembershipRolesController < ApplicationController
  before_action :authenticate_user!

  def create
    membership = Current.organization.memberships.find(params[:membership_id])
    authorize membership, policy_class: MemberPolicy

    role = Current.organization.roles.find(params[:role_id])
    MembershipRole.create!(membership: membership, role: role)

    respond_to do |format|
      format.html { redirect_to admin_members_path, notice: "Role assigned." }
      format.turbo_stream do
        @membership = membership
        @roles = Current.organization.roles.order(system: :desc, name: :asc)
      end
    end
  end

  def destroy
    membership_role = MembershipRole.find_by!(membership_id: params[:membership_id], role_id: params[:role_id])
    authorize membership_role.membership, policy_class: MemberPolicy

    membership_role.destroy!
    respond_to do |format|
      format.html { redirect_to admin_members_path, notice: "Role removed." }
      format.turbo_stream do
        @membership = membership_role.membership
        @roles = Current.organization.roles.order(system: :desc, name: :asc)
      end
    end
  end
end


