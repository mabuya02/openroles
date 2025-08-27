class RemovePasswordHashFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :password_hash, :string
  end
end
