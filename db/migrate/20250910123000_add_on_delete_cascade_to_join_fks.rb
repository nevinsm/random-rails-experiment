class AddOnDeleteCascadeToJoinFks < ActiveRecord::Migration[8.0]
  def up
    # membership_roles: cascade when membership or role is deleted
    remove_foreign_key :membership_roles, :memberships
    add_foreign_key :membership_roles, :memberships, on_delete: :cascade

    remove_foreign_key :membership_roles, :roles
    add_foreign_key :membership_roles, :roles, on_delete: :cascade

    # role_permissions: cascade when role or permission is deleted
    remove_foreign_key :role_permissions, :roles
    add_foreign_key :role_permissions, :roles, on_delete: :cascade

    remove_foreign_key :role_permissions, :permissions
    add_foreign_key :role_permissions, :permissions, on_delete: :cascade
  end

  def down
    remove_foreign_key :membership_roles, :memberships
    add_foreign_key :membership_roles, :memberships

    remove_foreign_key :membership_roles, :roles
    add_foreign_key :membership_roles, :roles

    remove_foreign_key :role_permissions, :roles
    add_foreign_key :role_permissions, :roles

    remove_foreign_key :role_permissions, :permissions
    add_foreign_key :role_permissions, :permissions
  end
end


