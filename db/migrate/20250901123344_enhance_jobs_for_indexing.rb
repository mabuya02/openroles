class EnhanceJobsForIndexing < ActiveRecord::Migration[8.0]
  def change
    # Add fields for imports, deduplication, and metadata
    add_column :jobs, :external_id, :string
    add_column :jobs, :source, :string
    add_column :jobs, :fingerprint, :string
    add_column :jobs, :posted_at, :datetime
    add_column :jobs, :apply_url, :string
    add_column :jobs, :raw_payload, :jsonb, default: {}
    add_column :jobs, :salary_min, :decimal, precision: 12, scale: 2
    add_column :jobs, :salary_max, :decimal, precision: 12, scale: 2

    # Add indexes for deduplication and performance
    add_index :jobs, [ :source, :external_id ], unique: true, where: "external_id IS NOT NULL"
    add_index :jobs, :fingerprint, unique: true, where: "fingerprint IS NOT NULL"
    add_index :jobs, :posted_at
    add_index :jobs, [ :salary_min, :salary_max ]
  end
end
