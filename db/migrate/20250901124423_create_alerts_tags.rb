class CreateAlertsTags < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts_tags, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :alert, type: :uuid, null: false, foreign_key: true
      t.references :tag, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :alerts_tags, [ :alert_id, :tag_id ], unique: true
  end
end
