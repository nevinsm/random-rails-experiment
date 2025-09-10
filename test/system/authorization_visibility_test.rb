require "application_system_test_case"

class AuthorizationVisibilityTest < ApplicationSystemTestCase
  def load_permission_catalog
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end
  end

  def sign_in_as(email, password: "password")
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
  end

  test "viewer sees org overview only; members and roles are forbidden" do
    load_permission_catalog
    owner = User.create!(email: "owner@example.com", password: "password")
    org = Organization.create!(name: "Acme", owner: owner)

    viewer = User.create!(email: "viewer@example.com", password: "password")
    viewer_membership = Membership.create!(user: viewer, organization: org, status: "active")
    viewer_role = org.roles.find_by!(key: "viewer")
    MembershipRole.create!(membership: viewer_membership, role: viewer_role)
    viewer.update!(last_active_organization_id: org.id)

    sign_in_as viewer.email
    visit organizations_path
    assert_text "Organizations"
    assert_no_link "Members"
    assert_no_link "Roles"
    assert_no_link "Audit Logs"

    visit admin_members_path
    assert_text "Action not allowed"

    visit admin_roles_path
    assert_text "Action not allowed"
  end

  test "member can view Members list but cannot invite or change roles" do
    load_permission_catalog
    owner = User.create!(email: "owner2@example.com", password: "password")
    org = Organization.create!(name: "Beta", owner: owner)

    member_user = User.create!(email: "member@example.com", password: "password")
    membership = Membership.create!(user: member_user, organization: org, status: "active")
    member_role = org.roles.find_by!(key: "member")
    MembershipRole.create!(membership: membership, role: member_role)
    member_user.update!(last_active_organization_id: org.id)

    sign_in_as member_user.email

    # Nav shows Members but not Roles/Audit
    visit organizations_path
    assert_link "Members"
    assert_no_link "Roles"
    assert_no_link "Audit Logs"

    visit admin_members_path
    assert_text "Members"
    assert_no_text "Invite/Add"
    assert_no_button "Remove"

    # Cannot access roles via URL
    visit admin_roles_path
    assert_text "Action not allowed"
  end

  test "admin can manage Members and Roles" do
    load_permission_catalog
    owner = User.create!(email: "owner3@example.com", password: "password")
    org = Organization.create!(name: "Gamma", owner: owner)

    admin_user = User.create!(email: "admin@example.com", password: "password")
    membership = Membership.create!(user: admin_user, organization: org, status: "active")
    admin_role = org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: membership, role: admin_role)
    admin_user.update!(last_active_organization_id: org.id)

    sign_in_as admin_user.email

    visit organizations_path
    assert_link "Members"
    assert_link "Roles"
    assert_no_link "Audit Logs" # admin does not have audit.read by default

    visit admin_members_path
    assert_text "Members"
    assert_text "Invite/Add"

    visit admin_roles_path
    assert_text "Roles"
    assert_link "New role"
  end

  test "owner can perform everything including viewing audit logs" do
    load_permission_catalog
    owner = User.create!(email: "owner4@example.com", password: "password")
    org = Organization.create!(name: "Delta", owner: owner)
    Membership.create!(user: owner, organization: org, status: "active")
    owner.update!(last_active_organization_id: org.id)

    sign_in_as owner.email

    visit organizations_path
    assert_link "Members"
    assert_link "Roles"
    assert_link "Audit Logs"

    visit admin_audit_logs_path
    assert_text "Audit Log"
  end
end


