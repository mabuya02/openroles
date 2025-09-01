class EnhanceAlertsForPersonalization < ActiveRecord::Migration[8.0]
  def change
    add_column :alerts, :frequency, :string, default: "daily"
    add_column :alerts, :last_notified_at, :datetime
    add_column :alerts, :unsubscribe_token, :string

    add_index :alerts, :unsubscribe_token, unique: true
    add_index :alerts, :frequency
    add_index :alerts, :last_notified_at
  end
end
