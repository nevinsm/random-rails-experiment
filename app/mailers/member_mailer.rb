class MemberMailer < ApplicationMailer
  default from: "no-reply@example.com"

  def invitation_email(membership)
    @membership = membership
    @organization = membership.organization
    @user = membership.user
    mail(to: @user.email, subject: "You're invited to join #{@organization.name}")
  end
end


