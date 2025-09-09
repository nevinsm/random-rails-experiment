class Organization < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :roles, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :ensure_slug
  after_create :seed_default_roles

  private

  def ensure_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end

  def seed_default_roles
    # Ensure permissions catalog exists
    Permission.count # triggers autoload, no-op

    catalog_keys = Permission.pluck(:key)

    # Role definitions
    # Admin: manage roles/members but not transfer ownership (we have no explicit transfer permission yet),
    # so restrict to role.manage, role.read, member.manage, member.invite, member.read, org.read
    admin_keys = %w[role.manage role.read member.manage member.invite member.read org.read]
    roles_definitions = [
      { name: "Owner", key: "owner", system: true, permission_keys: catalog_keys },
      { name: "Admin", key: "admin", system: true, permission_keys: admin_keys & catalog_keys },
      { name: "Member", key: "member", system: true, permission_keys: ["member.read"] },
      { name: "Viewer", key: "viewer", system: true, permission_keys: ["org.read"] }
    ]

    permission_by_key = Permission.all.index_by(&:key)

    roles_definitions.each do |attrs|
      role = roles.find_or_create_by!(name: attrs[:name], key: attrs[:key], system: attrs[:system])
      next unless attrs[:permission_keys]

      desired_permission_ids = attrs[:permission_keys].map { |k| permission_by_key[k] }.compact.map(&:id)
      existing_permission_ids = role.permissions.pluck(:id)
      to_add = desired_permission_ids - existing_permission_ids
      to_remove = existing_permission_ids - desired_permission_ids

      RolePermission.insert_all!(to_add.map { |pid| { role_id: role.id, permission_id: pid, created_at: Time.current, updated_at: Time.current } }) if to_add.any?
      RolePermission.where(role_id: role.id, permission_id: to_remove).delete_all if to_remove.any?
    end
  end
end


