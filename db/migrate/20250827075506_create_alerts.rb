class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.jsonb :criteria, default: {}
      t.string :status, null: false, default: 'active'
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
