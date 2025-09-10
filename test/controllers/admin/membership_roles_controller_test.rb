require "test_helper"

class Admin::MembershipRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end

    @owner = User.create!(email: "owner3@example.com", password: "password")
    @org = Organization.create!(name: "Gamma", owner: @owner)
    sign_in @owner, scope: :user
    @owner.update!(last_active_organization_id: @org.id)
    @membership = Membership.create!(user: @owner, organization: @org)

    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)

    @role = @org.roles.create!(name: "Support", key: "support")
  end

  test "assign role to membership" do
    assert_difference -> { MembershipRole.count }, +1 do
      post admin_membership_roles_path, params: { membership_id: @membership.id, role_id: @role.id }
    end
    assert_redirected_to admin_members_path
  end

  test "remove role from membership" do
    mr = MembershipRole.create!(membership: @membership, role: @role)
    assert_difference -> { MembershipRole.count }, -1 do
      delete admin_membership_role_path, params: { membership_id: @membership.id, role_id: @role.id }
    end
    assert_redirected_to admin_members_path
  end
end


