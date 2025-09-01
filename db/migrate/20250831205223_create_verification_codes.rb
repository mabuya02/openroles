class CreateVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :verification_codes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :code, null: false
      t.string :code_type, null: false # email_verification, phone_verification, two_factor
      t.string :contact_method # email or phone number used
      t.datetime :expires_at, null: false
      t.boolean :verified, default: false
      t.datetime :verified_at
      t.integer :attempts, default: 0
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :verification_codes, [ :code, :code_type ], unique: true
    add_index :verification_codes, [ :user_id, :code_type ]
    add_index :verification_codes, :expires_at
    add_index :verification_codes, :verified
  end
end
