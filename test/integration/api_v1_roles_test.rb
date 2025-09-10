require "test_helper"

class ApiV1RolesTest < ActionDispatch::IntegrationTest
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
    sign_in @owner, scope: :user
    @owner.update!(last_active_organization_id: @org.id)
    @membership = Membership.create!(user: @owner, organization: @org)
  end

  test "index returns roles with pagination" do
    get "/api/v1/roles.json", params: { page: 1, per: 2 }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["roles"].is_a?(Array)
    assert body["meta"].is_a?(Hash)
    assert_equal 2, body["meta"]["per"]
  end

  test "create role and update role" do
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)

    perm_ids = Permission.where(key: %w[member.read org.read]).pluck(:id)
    post "/api/v1/roles.json", params: { role: { name: "Support", key: "support", permission_ids: perm_ids } }
    assert_response :created
    role_id = JSON.parse(response.body)["id"]

    patch "/api/v1/roles/#{role_id}.json", params: { role: { name: "Support 2" } }
    assert_response :success
    assert_equal "Support 2", JSON.parse(response.body)["name"]
  end

  test "destroy role with constraints" do
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)

    owner_role = @org.roles.find_by!(key: "owner")
    delete "/api/v1/roles/#{owner_role.id}.json"
    assert_response :unprocessable_content
  end
end


