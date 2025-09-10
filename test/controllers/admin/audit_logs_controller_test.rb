require "test_helper"

class Admin::AuditLogsControllerTest < ActionDispatch::IntegrationTest
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
    Membership.create!(user: @owner, organization: @org)
  end

  test "index lists audit events scoped to org and filters by event_type" do
    role = @org.roles.create!(name: "Support", key: "support", system: false)
    AuditEvent.create!(organization: @org, actor: @owner, event_type: "role.created", resource_type: "Role", resource_id: role.id, metadata: {})
    AuditEvent.create!(organization: @org, actor: @owner, event_type: "member.added", resource_type: "Membership", resource_id: 123, metadata: {})

    get admin_audit_logs_path, params: { event_type: "role.created" }
    assert_response :success
    assert_select "table tbody tr", 1
  end
end


