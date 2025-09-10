require "test_helper"

class ApiV1MembersTest < ActionDispatch::IntegrationTest
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

  test "index members paginated" do
    get "/api/v1/members.json", params: { page: 1, per: 1 }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["members"].is_a?(Array)
    assert_equal 1, body["meta"]["per"]
  end

  test "invite new member and update status" do
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)

    post "/api/v1/members.json", params: { member: { email: "new@example.com" } }
    assert_response :created
    member_id = JSON.parse(response.body)["id"]

    patch "/api/v1/members/#{member_id}.json", params: { member: { status: "active" } }
    assert_response :success
    assert_equal "active", JSON.parse(response.body)["status"]
  end
end


