class AddMissingColumnsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :company, :string
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_column :users, :two_factor_enabled, :boolean
    add_column :users, :two_factor_secret, :string
  end
end
