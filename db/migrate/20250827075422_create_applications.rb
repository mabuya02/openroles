class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :job, type: :uuid, null: false, foreign_key: true
      t.references :resume, type: :uuid, foreign_key: { to_table: :user_profiles }
      t.text :cover_letter
      t.string :status, null: false, default: 'applied'
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
