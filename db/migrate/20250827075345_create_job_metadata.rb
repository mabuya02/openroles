class CreateJobMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :job_metadata, id: :uuid do |t|
      t.references :job, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.string :meta_title
      t.text :meta_description
      t.string :meta_keywords
      t.string :slug
      t.string :canonical_url
      t.string :og_title
      t.text :og_description
      t.string :og_image_url
      t.string :twitter_card_type
      t.json :schema_markup
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
