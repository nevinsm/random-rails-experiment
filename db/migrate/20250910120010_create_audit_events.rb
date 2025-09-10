class CreateAuditEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      # Use json for SQLite; jsonb on Postgres. Rails maps to appropriate type per adapter.
      t.json :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :audit_events, [:organization_id, :created_at]
    add_index :audit_events, [:resource_type, :resource_id]
    add_index :audit_events, :event_type
  end
end


