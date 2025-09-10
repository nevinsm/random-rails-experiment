class Api::V1::MembersController < Api::V1::BaseController
  def index
    authorize :member, policy_class: MemberPolicy

    memberships = Current.organization.memberships.includes(:user, :roles).order(created_at: :asc)
    total = memberships.count
    memberships = paginate(memberships)

    render json: {
      members: memberships.map { |m| serialize_membership(m) },
      meta: pagination_meta(total: total, page: (params[:page] || 1).to_i, per: ((params[:per] || 25).to_i.clamp(1, 100)))
    }
  end

  # Invite or add existing user
  def create
    authorize :member, policy_class: MemberPolicy

    email = params.dig(:member, :email).to_s.strip.downcase
    return render json: { error: "Email is required." }, status: :unprocessable_content if email.blank?

    user = User.find_by(email: email)
    membership = Current.organization.memberships.find_by(user: user) if user

    ActiveRecord::Base.transaction do
      if membership
        # already a member, respond ok idempotently
        return render json: serialize_membership(membership)
      elsif user
        membership = Current.organization.memberships.create!(user: user, status: "active")
        AuditLogger.log(event_type: "member.added", resource: membership, metadata: { after: { user_id: user.id, organization_id: Current.organization.id }, ip: request.remote_ip })
        return render json: serialize_membership(membership), status: :created
      else
        random_password = SecureRandom.base58(16)
        user = User.create!(email: email, password: random_password)
        membership = Current.organization.memberships.create!(user: user, status: "invited", invited_by: current_user)
        MemberMailer.invitation_email(membership).deliver_later
        AuditLogger.log(event_type: "member.invited", resource: membership, metadata: { after: { user_id: user.id, organization_id: Current.organization.id }, ip: request.remote_ip })
        return render json: serialize_membership(membership), status: :created
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end

  def update
    membership = find_membership
    authorize membership, policy_class: MemberPolicy

    if membership.update(membership_params)
      render json: serialize_membership(membership)
    else
      render json: { error: membership.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end

  private

  def find_membership
    Current.organization.memberships.find(params[:id])
  end

  def membership_params
    params.require(:member).permit(:status)
  end

  def serialize_membership(membership)
    { id: membership.id, user_id: membership.user_id, email: membership.user.email, status: membership.status, role_ids: membership.roles.pluck(:id) }
  end
end


