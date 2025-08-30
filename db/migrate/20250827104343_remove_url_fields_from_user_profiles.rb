class RemoveUrlFieldsFromUserProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_profiles, :resume_url, :string
    remove_column :user_profiles, :cover_letter_url, :string
  end
end
