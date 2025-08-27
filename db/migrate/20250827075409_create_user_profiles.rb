class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :resume_url
      t.string :cover_letter_url
      t.string :portfolio_url
      t.string :linkedin_url
      t.string :github_url
      t.text :bio
      t.string :skills
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
