class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false, index: { unique: true }
      t.string :phone_number
      t.string :password_hash
      t.string :status, null: false, default: 'inactive'
      t.boolean :email_verified, default: false
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
