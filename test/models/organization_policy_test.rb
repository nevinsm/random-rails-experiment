require "test_helper"

class OrganizationPolicyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "user@example.com", password: "password")
    @org = Organization.create!(name: "Org", slug: "org", owner: @user)
    Current.user = @user
    Current.organization = @org
  end

  def teardown
    Current.reset
  end

  test "create? allows any signed-in user" do
    policy = OrganizationPolicy.new(@user, Organization)
    assert policy.create?
  end

  test "show? requires org.read permission" do
    policy = OrganizationPolicy.new(@user, @org)
    refute policy.show?

    # Grant permission via role
    permission = Permission.find_or_create_by!(key: "org.read", name: "Org Read")
    role = Role.create!(organization: @org, name: "Reader", key: "reader")
    RolePermission.create!(role: role, permission: permission)
    membership = Membership.find_or_create_by!(user: @user, organization: @org, status: "active")
    MembershipRole.create!(membership: membership, role: role)

    assert OrganizationPolicy.new(@user, @org).show?
  end
end


