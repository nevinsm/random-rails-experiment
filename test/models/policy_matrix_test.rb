require "test_helper"

class PolicyMatrixTest < ActiveSupport::TestCase
  def load_permission_catalog
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end
  end

  setup do
    load_permission_catalog
    @owner = User.create!(email: "owner@example.com", password: "password")
    @org = Organization.create!(name: "Acme", owner: @owner)
    Current.organization = @org
  end

  teardown do
    Current.reset
  end

  def assign_role(email, role_key)
    user = User.find_or_create_by!(email: email) { |u| u.password = "password" }
    membership = Membership.find_or_create_by!(user: user, organization: @org)
    role = @org.roles.find_by!(key: role_key)
    MembershipRole.find_or_create_by!(membership: membership, role: role)
    user
  end

  test "OrganizationPolicy matrix" do
    viewer = assign_role("viewer@example.com", "viewer")
    member = assign_role("member@example.com", "member")
    admin = assign_role("admin@example.com", "admin")

    assert Pundit.policy!(@owner, @org).show?
    assert Pundit.policy!(@owner, @org).update?

    assert Pundit.policy!(admin, @org).show?
    assert_not Pundit.policy!(admin, @org).update?

    assert_not Pundit.policy!(member, @org).show?
    assert_not Pundit.policy!(member, @org).update?

    assert Pundit.policy!(viewer, @org).show?
    assert_not Pundit.policy!(viewer, @org).update?
  end

  test "RolePolicy matrix" do
    viewer = assign_role("viewer2@example.com", "viewer")
    member = assign_role("member2@example.com", "member")
    admin = assign_role("admin2@example.com", "admin")

    role_record = @org.roles.find_by!(key: "admin")

    assert Pundit.policy!(@owner, Role).index?
    assert Pundit.policy!(@owner, role_record).show?
    assert Pundit.policy!(@owner, Role).create?
    assert_not Pundit.policy!(@owner, role_record).update? if role_record.system?

    assert Pundit.policy!(admin, Role).index?
    assert Pundit.policy!(admin, role_record).show?
    assert Pundit.policy!(admin, Role).create?
    assert_not Pundit.policy!(admin, role_record).update? if role_record.system?

    assert_not Pundit.policy!(member, Role).index?
    assert_not Pundit.policy!(member, role_record).show?
    assert_not Pundit.policy!(member, Role).create?

    assert_not Pundit.policy!(viewer, Role).index?
    assert_not Pundit.policy!(viewer, role_record).show?
    assert_not Pundit.policy!(viewer, Role).create?
  end

  test "MemberPolicy matrix" do
    viewer = assign_role("viewer3@example.com", "viewer")
    member = assign_role("member3@example.com", "member")
    admin = assign_role("admin3@example.com", "admin")
    membership_record = @org.memberships.first

    assert MemberPolicy.new(@owner, Current.organization).index?
    assert MemberPolicy.new(@owner, membership_record).update?
    assert MemberPolicy.new(@owner, Current.organization).create?
    assert MemberPolicy.new(@owner, membership_record).destroy?

    assert MemberPolicy.new(admin, Current.organization).index?
    assert MemberPolicy.new(admin, membership_record).update?
    assert MemberPolicy.new(admin, Current.organization).create?
    assert MemberPolicy.new(admin, membership_record).destroy?

    assert MemberPolicy.new(member, Current.organization).index?
    assert_not MemberPolicy.new(member, membership_record).update?
    assert_not MemberPolicy.new(member, Current.organization).create?
    assert_not MemberPolicy.new(member, membership_record).destroy?

    assert_not MemberPolicy.new(viewer, Current.organization).index?
    assert_not MemberPolicy.new(viewer, membership_record).update?
    assert_not MemberPolicy.new(viewer, Current.organization).create?
    assert_not MemberPolicy.new(viewer, membership_record).destroy?
  end

  test "AuditPolicy matrix" do
    viewer = assign_role("viewer4@example.com", "viewer")
    admin = assign_role("admin4@example.com", "admin")
    assert AuditPolicy.new(@owner, nil).index?
    assert_not AuditPolicy.new(admin, nil).index?
    assert_not AuditPolicy.new(viewer, nil).index?
  end
end


