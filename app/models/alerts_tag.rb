class AlertsTag < ApplicationRecord
  belongs_to :alert
  belongs_to :tag

  validates :alert_id, uniqueness: { scope: :tag_id }
end
