class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  include SetsCurrentOrganization

  def index
    @organizations = Organization.joins(:memberships).where(memberships: { user_id: current_user.id }).distinct
  end

  def new
    authorize Organization
    @organization = Organization.new
  end

  def create
    authorize Organization
    @organization = Organization.new(organization_params)
    @organization.owner = current_user

    if @organization.save
      Membership.create!(user: current_user, organization: @organization, status: "active", invited_by_id: current_user.id)
      current_user.update!(last_active_organization_id: @organization.id)
      redirect_to organizations_path(organization_id: @organization.id), notice: "Organization created."
    else
      flash.now[:alert] = "Could not create organization."
      render :new, status: :unprocessable_content
    end
  end

  def switch
    organization = Organization.find_by(id: params[:organization_id]) || Organization.find_by(slug: params[:organization_id])
    if organization && Membership.exists?(user: current_user, organization: organization)
      current_user.update!(last_active_organization_id: organization.id)
      redirect_to organizations_path(organization_id: organization.id), notice: "Switched organization."
    else
      redirect_to organizations_path, alert: "Organization not found or access denied."
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :slug)
  end
end


