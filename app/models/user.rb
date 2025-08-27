class User < ApplicationRecord
  # Secure password
  has_secure_password

  # Associations
  has_one :user_profile, dependent: :destroy
  has_many :applications, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :status, inclusion: { in: UserStatus::VALUES }

  scope :active, -> { where(status: UserStatus::ACTIVE) }
  scope :inactive, -> { where(status: UserStatus::INACTIVE) }

  # Helper methods
  def status_enum
    UserStatus::VALUES.include?(status) ? status : UserStatus::INACTIVE
  end

  def can_login?
    status == UserStatus::ACTIVE
  end

  def blocked?
    [ UserStatus::SUSPENDED, UserStatus::LOCKED ].include?(status)
  end
end
