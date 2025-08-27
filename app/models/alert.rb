class Alert < ApplicationRecord
  belongs_to :user

  validates :status, inclusion: { in: AlertStatus::VALUES }
  validates :criteria, presence: true
end
