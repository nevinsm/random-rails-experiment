class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.bigint :owner_id, null: false

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :owner_id
    add_foreign_key :organizations, :users, column: :owner_id
  end
end


