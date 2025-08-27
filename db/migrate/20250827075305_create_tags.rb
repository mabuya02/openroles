class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :description
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
