class AddLastSignInFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add missing columns that should have been in the original migration
    add_column :users, :last_sign_in_at, :datetime, null: true
    add_column :users, :last_sign_in_ip, :string, null: true
    add_column :users, :confirmed_at, :datetime, null: true

    # Add missing boolean columns with defaults
    add_column :users, :phone_verified, :boolean, default: false, null: false
    add_column :users, :admin, :boolean, default: false, null: false

    # Add indexes for performance
    add_index :users, :last_sign_in_at
    add_index :users, :admin
  end
end
