class CreateJobTags < ActiveRecord::Migration[8.0]
  def change
    create_table :job_tags, id: :uuid do |t|
      t.references :job, type: :uuid, null: false, foreign_key: true
      t.references :tag, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
