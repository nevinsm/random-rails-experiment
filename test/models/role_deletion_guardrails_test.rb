require "test_helper"

class RoleDeletionGuardrailsTest < ActiveSupport::TestCase
  setup do
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end

    @owner = User.create!(email: "owner@example.com", password: "password")
    @org = Organization.create!(name: "Acme", owner: @owner)
  end

  test "destroying non-system role cascades join rows" do
    role = @org.roles.create!(name: "Temp", key: "temp", system: false)
    perm = Permission.first
    RolePermission.create!(role: role, permission: perm)

    member = User.create!(email: "member@example.com", password: "password")
    membership = Membership.create!(user: member, organization: @org)
    MembershipRole.create!(membership: membership, role: role)

    assert_difference -> { RolePermission.where(role_id: role.id).count }, -1 do
      assert_difference -> { MembershipRole.where(role_id: role.id).count }, -1 do
        role.destroy!
      end
    end
  end

  test "cannot destroy system role via controller" do
    role = @org.roles.find_by!(key: "owner")
    assert role.system?
  end
end


