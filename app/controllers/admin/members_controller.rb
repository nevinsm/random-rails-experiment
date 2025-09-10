class Admin::MembersController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :member, policy_class: MemberPolicy

    @memberships = Current.organization
      .memberships
      .includes(:user, :roles)
      .order(created_at: :asc)

    @roles = Current.organization.roles.order(system: :desc, name: :asc)
  end

  def create
    authorize :member, policy_class: MemberPolicy

    email = params.dig(:member, :email).to_s.strip.downcase
    if email.blank?
      return redirect_to admin_members_path, alert: "Email is required."
    end

    user = User.find_by(email: email)
    membership = Current.organization.memberships.find_by(user: user) if user

    ActiveRecord::Base.transaction do
      if membership
        # already a member
        notice = "User is already a member."
      elsif user
        membership = Current.organization.memberships.create!(user: user, status: "active")
        notice = "Member added."
        AuditLogger.log(
          event_type: "member.added",
          resource: membership,
          metadata: { after: { user_id: user.id, organization_id: Current.organization.id }, ip: request.remote_ip }
        )
      else
        # Stub invitation flow: create a user now with random password
        random_password = SecureRandom.base58(16)
        user = User.create!(email: email, password: random_password)
        membership = Current.organization.memberships.create!(user: user, status: "invited", invited_by: current_user)
        MemberMailer.invitation_email(membership).deliver_later
        notice = "Invitation sent (stub)."
        AuditLogger.log(
          event_type: "member.invited",
          resource: membership,
          metadata: { after: { user_id: user.id, organization_id: Current.organization.id }, ip: request.remote_ip }
        )
      end

      respond_to do |format|
        format.html { redirect_to admin_members_path, notice: notice }
        format.turbo_stream do
          @membership = membership
          @roles = Current.organization.roles.order(system: :desc, name: :asc)
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to admin_members_path, alert: e.record.errors.full_messages.to_sentence }
      format.turbo_stream do
        @error_message = e.record.errors.full_messages.to_sentence
        render :index, status: :unprocessable_content
      end
    end
  end

  def update
    @membership = find_membership
    authorize @membership, policy_class: MemberPolicy

    if @membership.update(membership_params)
      respond_to do |format|
        format.html { redirect_to admin_members_path, notice: "Member updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_members_path, alert: @membership.errors.full_messages.to_sentence }
        format.turbo_stream { head :unprocessable_content }
      end
    end
  end

  def destroy
    @membership = find_membership
    authorize @membership, policy_class: MemberPolicy

    before_attrs = @membership.attributes
    @membership.destroy!
    AuditLogger.log(
      event_type: "member.removed",
      resource: @membership,
      metadata: { before: before_attrs, ip: request.remote_ip }
    )
    respond_to do |format|
      format.html { redirect_to admin_members_path, notice: "Member removed." }
      format.turbo_stream
    end
  end

  private

  def find_membership
    Current.organization.memberships.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:status)
  end
end


