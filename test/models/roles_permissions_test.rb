require "test_helper"

class RolesPermissionsTest < ActiveSupport::TestCase
  def load_permission_catalog
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    catalog = YAML.load_file(yaml_path)
    catalog.each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end
  end

  setup do
    load_permission_catalog
  end

  test "catalog is present and unique by key" do
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    catalog = YAML.load_file(yaml_path)
    unique_keys = catalog.map { |h| h["key"] }.uniq

    assert_equal unique_keys.size, Permission.count

    dup = Permission.new(key: unique_keys.first, name: "Dup")
    assert_not dup.valid?
    assert_includes dup.errors[:key], "has already been taken"
  end

  test "default roles appear on org creation with mapped permissions" do
    owner = User.create!(email: "owner@example.com", password: "password")
    org = Organization.create!(name: "Acme", owner: owner)

    role_keys = org.roles.pluck(:key)
    assert_equal %w[admin member owner viewer].sort, role_keys.sort

    catalog_keys = Permission.pluck(:key)
    admin_expected = %w[role.manage role.read member.manage member.invite member.read org.read] & catalog_keys

    assert_equal catalog_keys.sort, org.roles.find_by!(key: "owner").permissions.pluck(:key).sort
    assert_equal admin_expected.sort, org.roles.find_by!(key: "admin").permissions.pluck(:key).sort
    assert_equal ["member.read"], org.roles.find_by!(key: "member").permissions.pluck(:key)
    assert_equal ["org.read"], org.roles.find_by!(key: "viewer").permissions.pluck(:key)
  end

  test "User#has_permission? resolves through membership roles" do
    owner = User.create!(email: "owner2@example.com", password: "password")
    user = User.create!(email: "user@example.com", password: "password")
    org = Organization.create!(name: "Beta", owner: owner)

    membership = Membership.create!(user: user, organization: org)

    viewer = org.roles.find_by!(key: "viewer")
    admin = org.roles.find_by!(key: "admin")

    MembershipRole.create!(membership: membership, role: viewer)

    assert user.has_permission?("org.read", organization: org)
    assert_not user.has_permission?("member.manage", organization: org)

    # Upgrade to admin
    MembershipRole.where(membership: membership).delete_all
    MembershipRole.create!(membership: membership, role: admin)

    assert user.has_permission?("member.manage", organization: org)
    assert user.has_permission?("role.read", organization: org)
    assert_not user.has_permission?("audit.read", organization: org) unless Permission.exists?(key: "audit.read")
  end
end


