class CreateSavedJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_jobs, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :job, type: :uuid, null: false, foreign_key: true
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
