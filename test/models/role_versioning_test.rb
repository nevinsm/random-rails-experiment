require "test_helper"

class RoleVersioningTest < ActiveSupport::TestCase
  setup do
    # Load permission catalog
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

  test "editing a role records a paper_trail version with whodunnit" do
    role = @org.roles.create!(name: "Support", key: "support", system: false)
    PaperTrail.request(whodunnit: @owner.id) do
      role.update!(name: "Support Plus")
    end

    version = role.versions.last
    assert_equal @owner.id.to_s, version.whodunnit
    assert_equal "update", version.event
  end
end


