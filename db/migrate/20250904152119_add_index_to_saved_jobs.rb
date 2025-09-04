class AddIndexToSavedJobs < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for faster lookups of user-job combinations
    add_index :saved_jobs, [ :user_id, :job_id ], unique: true, name: 'index_saved_jobs_on_user_and_job'
  end
end
