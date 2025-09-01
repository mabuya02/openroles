class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false, index: { unique: true }
      t.string :phone_number
      t.string :password_digest 
      t.string :company
      t.string :role
      t.text :bio
      t.string :avatar_url
      t.boolean :admin, default: false
      t.string :status, null: false, default: 'inactive'
      t.boolean :email_verified, default: false
      t.boolean :phone_verified, default: false
      t.boolean :two_factor_enabled, default: false
      t.string :two_factor_secret
      t.datetime :last_sign_in_at
      t.string :last_sign_in_ip
      t.datetime :confirmed_at

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :users, :phone_number
    add_index :users, :status
    add_index :users, :admin
  end
end
