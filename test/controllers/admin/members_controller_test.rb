require "test_helper"

class Admin::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    yaml_path = Rails.root.join("db", "seeds", "permissions.yml")
    YAML.load_file(yaml_path).each do |attrs|
      Permission.find_or_create_by!(key: attrs["key"]) do |p|
        p.name = attrs["name"]
        p.description = attrs["description"]
      end
    end

    @owner = User.create!(email: "owner2@example.com", password: "password")
    @org = Organization.create!(name: "Zeta", owner: @owner)
    sign_in @owner, scope: :user
    @owner.update!(last_active_organization_id: @org.id)
    @membership = Membership.create!(user: @owner, organization: @org)

    # grant admin permissions to perform member actions
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)
  end

  test "index succeeds with member.read" do
    get admin_members_path
    assert_response :success
  end

  test "create adds existing user as active member" do
    user = User.create!(email: "member@example.com", password: "password")
    assert_difference -> { @org.memberships.count }, +1 do
      post admin_members_path, params: { member: { email: user.email } }
    end
    assert_redirected_to admin_members_path
    assert_equal "active", @org.memberships.order(created_at: :desc).first.status
  end

  test "create invites non-existent email" do
    assert_difference -> { @org.memberships.count }, +1 do
      post admin_members_path, params: { member: { email: "newperson@example.com" } }
    end
    m = @org.memberships.order(created_at: :desc).first
    assert_equal "invited", m.status
  end

  test "destroy removes membership" do
    user = User.create!(email: "gone@example.com", password: "password")
    m = @org.memberships.create!(user: user)
    assert_difference -> { @org.memberships.count }, -1 do
      delete admin_member_path(m)
    end
  end
end


