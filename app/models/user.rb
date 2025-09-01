class User < ApplicationRecord
  has_secure_password

  # Associations
  has_one :user_profile, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy
  has_many :verification_codes, dependent: :destroy
  has_many :applications, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy
  has_many :jobs, dependent: :destroy

  # Status constants from UserStatus enum
  STATUS_INACTIVE = UserStatus::INACTIVE
  STATUS_ACTIVE = UserStatus::ACTIVE
  STATUS_SUSPENDED = UserStatus::SUSPENDED
  STATUS_DELETED = UserStatus::LOCKED  # Using LOCKED as DELETED equivalent

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, phone_number: true, allow_blank: true
  validates :password, length: { minimum: 8 }, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]).{8,}\z/,
    message: "must be at least 8 characters and include uppercase letter, lowercase letter, number, and special character"
  }, if: -> { new_record? || !password.nil? }
  validates :bio, length: { maximum: 1000 }, allow_blank: true
  validates :status, inclusion: { in: [ STATUS_INACTIVE, STATUS_ACTIVE, STATUS_SUSPENDED, STATUS_DELETED ] }

  # Callbacks
  before_save :normalize_email
  before_save :normalize_phone
  before_validation :set_default_status, on: :create
  after_create :send_verification_email

  # Scopes
  scope :verified, -> { where(email_verified: true) }
  scope :active, -> { where(status: STATUS_ACTIVE) }
  scope :inactive, -> { where(status: STATUS_INACTIVE) }
  scope :suspended, -> { where(status: STATUS_SUSPENDED) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.present? ? full_name : email
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def verified?
    email_verified
  end

  def inactive?
    status == STATUS_INACTIVE
  end

  def active?
    status == STATUS_ACTIVE
  end

  def suspended?
    status == STATUS_SUSPENDED
  end

  def deleted?
    status == STATUS_DELETED
  end

  def can_login?
    active? && verified?
  end

  def blocked?
    suspended?
  end

  def two_factor_setup?
    two_factor_enabled && two_factor_secret.present?
  end

  def confirm_email!
    update!(
      email_verified: true,
      status: STATUS_ACTIVE
    )
  end

  def suspend!
    update!(status: STATUS_SUSPENDED)
  end

  def activate!
    update!(status: STATUS_ACTIVE)
  end

  def soft_delete!
    update!(
      status: STATUS_DELETED,
      deleted_at: Time.current
    )
  end

  def has_profile?
    user_profile.present?
  end

  def has_resume?
    user_profile&.resume_attached?
  end

  def profile_complete?
    has_profile? && user_profile.bio.present? && user_profile.skills.present?
  end

  def phone_number_formatted
    return nil unless phone_number.present?
    parsed_phone = Phonelib.parse(phone_number)
    parsed_phone.valid? ? parsed_phone.international : phone_number
  end

  def phone_number_country
    return nil unless phone_number.present?
    parsed_phone = Phonelib.parse(phone_number)
    parsed_phone.valid? ? parsed_phone.country : nil
  end

  private

  def set_default_status
    self.status ||= STATUS_INACTIVE
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def normalize_phone
    if phone_number.present?
      parsed_phone = Phonelib.parse(phone_number)
      self.phone_number = parsed_phone.valid? ? parsed_phone.international : phone_number
    end
  end

  def send_verification_email
    # Will be implemented when we create the mailer
    # AuthMailer.email_verification(self).deliver_later
  end
end
