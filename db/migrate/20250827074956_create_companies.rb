class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :website
      t.string :industry
      t.string :location
      t.string :logo_url
      t.string :status, null: false, default: 'active'
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
