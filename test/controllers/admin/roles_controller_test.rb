require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Load permission catalog before org creation so default roles get permissions
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end

    @owner = User.create!(email: "owner@example.com", password: "password")
    @org = Organization.create!(name: "Acme", owner: @owner)
    sign_in @owner, scope: :user
    @owner.update!(last_active_organization_id: @org.id)
    @membership = Membership.create!(user: @owner, organization: @org)
  end

  test "index requires role.manage permission" do
    get admin_roles_path
    assert_response :forbidden

    # Grant owner admin role via membership to allow manage
    membership = @membership
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: membership, role: admin)

    get admin_roles_path
    assert_response :success
  end

  test "create non-system role and assign permissions" do
    membership = @membership
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: membership, role: admin)

    perm_ids = Permission.where(key: %w[member.read org.read]).pluck(:id)
    assert_difference -> { @org.roles.count }, +1 do
      post admin_roles_path, params: { role: { name: "Support", key: "support", permission_ids: perm_ids } }
    end
    role = @org.roles.find_by!(key: "support")
    assert_equal perm_ids.sort, role.permissions.pluck(:id).sort
  end

  test "cannot delete system role" do
    membership = @membership
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: membership, role: admin)

    owner_role = @org.roles.find_by!(key: "owner")
    assert_no_difference -> { @org.roles.count } do
      delete admin_role_path(owner_role)
    end
    assert_redirected_to admin_roles_path
  end

  test "cannot delete role that has memberships" do
    membership = @membership
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: membership, role: admin)

    role = @org.roles.create!(name: "Temp", key: "temp")
    MembershipRole.create!(membership: membership, role: role)

    assert_no_difference -> { @org.roles.count } do
      delete admin_role_path(role)
    end
    assert_redirected_to admin_roles_path
  end
end


