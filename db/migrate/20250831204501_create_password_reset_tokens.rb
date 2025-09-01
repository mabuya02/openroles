class CreatePasswordResetTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :password_reset_tokens, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.string :email, null: false
      t.datetime :expires_at, null: false
      t.boolean :used, default: false
      t.datetime :used_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :password_reset_tokens, :token, unique: true
    add_index :password_reset_tokens, :email
    add_index :password_reset_tokens, [ :token, :used ]
    add_index :password_reset_tokens, :expires_at
  end
end
