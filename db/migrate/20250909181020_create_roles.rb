class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key, null: false
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :roles, [:organization_id, :key], unique: true
    add_index :roles, [:organization_id, :name], unique: true
  end
end


