class MemberMailerPreview < ActionMailer::Preview
  def invitation_email
    user = User.first || User.create!(email: "preview@example.com", password: "password")
    org = Organization.first || Organization.create!(name: "Preview Org", owner: user)
    membership = Membership.first || Membership.create!(user: user, organization: org, status: "invited")
    MemberMailer.invitation_email(membership)
  end
end


