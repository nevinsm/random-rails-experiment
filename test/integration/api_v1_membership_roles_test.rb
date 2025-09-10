require "test_helper"

class ApiV1MembershipRolesTest < ActionDispatch::IntegrationTest
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

  test "assign and unassign role" do
    admin = @org.roles.find_by!(key: "admin")
    MembershipRole.create!(membership: @membership, role: admin)

    role = @org.roles.create!(name: "Temp", key: "temp")

    post "/api/v1/members/#{@membership.id}/roles.json", params: { role: { id: role.id } }
    assert_response :success

    delete "/api/v1/members/#{@membership.id}/roles/#{role.id}.json"
    assert_response :no_content
  end
end


