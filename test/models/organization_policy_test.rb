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

  test "owner can show? without explicit permission" do
    policy = OrganizationPolicy.new(@user, @org)
    assert policy.show?
  end
end


