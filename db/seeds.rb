# Idempotent seeds: load permissions catalog and create a demo org with users/roles.

require "yaml"

puts "Seeding permissions catalog..."
catalog_path = Rails.root.join("db", "seeds", "permissions.yml")
if File.exist?(catalog_path)
  yaml = YAML.load_file(catalog_path)
  unless yaml.is_a?(Array)
    raise "Invalid YAML at #{catalog_path}: expected an array"
  end

  yaml.each do |attrs|
    key = attrs["key"] || attrs[:key]
    name = attrs["name"] || attrs[:name]
    description = attrs["description"] || attrs[:description]
    next unless key && name

    permission = Permission.find_or_initialize_by(key: key)
    permission.name = name
    permission.description = description
    permission.save! if permission.changed?
  end
else
  warn "permissions.yml not found at #{catalog_path}; skipping catalog load"
end

puts "Creating demo users and organization..."

owner = User.find_or_create_by!(email: "owner@example.com") do |u|
  u.password = "password"
  u.name = "Owner"
end

org = Organization.find_or_create_by!(slug: "acme-demo") do |o|
  o.name = "Acme Demo"
  o.owner = owner
end

# Ensure default roles exist and are synced with current catalog
if org.roles.blank? || (Permission.count > 0)
  org.send(:seed_default_roles)
end

# Ensure memberships exist
owner_membership = Membership.find_or_create_by!(user: owner, organization: org)

admin_user = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.name = "Admin"
end
member_user = User.find_or_create_by!(email: "member@example.com") do |u|
  u.password = "password"
  u.name = "Member"
end
viewer_user = User.find_or_create_by!(email: "viewer@example.com") do |u|
  u.password = "password"
  u.name = "Viewer"
end

admin_membership = Membership.find_or_create_by!(user: admin_user, organization: org)
member_membership = Membership.find_or_create_by!(user: member_user, organization: org)
viewer_membership = Membership.find_or_create_by!(user: viewer_user, organization: org)

roles_by_key = org.roles.index_by(&:key)

# Assign membership roles idempotently
[
  [owner_membership, roles_by_key["owner"]],
  [admin_membership, roles_by_key["admin"]],
  [member_membership, roles_by_key["member"]],
  [viewer_membership, roles_by_key["viewer"]]
].each do |membership, role|
  next unless membership && role
  MembershipRole.find_or_create_by!(membership: membership, role: role)
end

puts "Seeds complete. Login as owner@example.com / password"
