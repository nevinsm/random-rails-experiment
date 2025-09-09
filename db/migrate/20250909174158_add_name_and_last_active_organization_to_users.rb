class AddNameAndLastActiveOrganizationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :last_active_organization_id, :bigint
  end
end
