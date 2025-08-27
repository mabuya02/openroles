class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs, id: :uuid do |t|
      t.references :company, type: :uuid, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :location
      t.string :employment_type
      t.decimal :salary
      t.string :status, null: false, default: 'draft'
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
