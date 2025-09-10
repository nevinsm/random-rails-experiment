require "test_helper"

class AuthorizationHelperTest < ActionView::TestCase
  include AuthorizationHelper

  def setup
    @user = User.create!(email: "user2@example.com", password: "password")
    @org = Organization.create!(name: "Org2", slug: "org2", owner: @user)
    Current.user = @user
    Current.organization = @org
  end

  def teardown
    Current.reset
  end

  test "owner can? returns true without explicit role" do
    assert can?("member.read")
  end

  test "can? returns true with permission via role" do
    permission = Permission.find_or_create_by!(key: "member.read", name: "Member Read")
    role = Role.create!(organization: @org, name: "Reader", key: "reader")
    RolePermission.create!(role: role, permission: permission)
    membership = Membership.find_or_create_by!(user: @user, organization: @org, status: "active")
    MembershipRole.create!(membership: membership, role: role)

    assert can?("member.read")
  end
end


