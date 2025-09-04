class DropSavedJobs < ActiveRecord::Migration[8.0]
  def up
    drop_table :saved_jobs
  end

  def down
    create_table :saved_jobs, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :job, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :saved_jobs, [ :user_id, :job_id ], unique: true, name: 'index_saved_jobs_on_user_and_job'
  end
end
