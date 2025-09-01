class VerificationCode < ApplicationRecord
  belongs_to :user

  validates :code, presence: true
  validates :code_type, presence: true, inclusion: { in: %w[email_verification phone_verification two_factor password_reset] }
  validates :contact_method, presence: true
  validates :expires_at, presence: true
  validates :code, uniqueness: { scope: :code_type }

  scope :active, -> { where(verified: false).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :verified, -> { where(verified: true) }
  scope :by_type, ->(type) { where(code_type: type) }

  before_create :generate_code
  before_create :set_expiry

  MAX_ATTEMPTS = 3
  CODE_LENGTH = 6
  EXPIRY_DURATION = {
    "email_verification" => 24.hours,
    "phone_verification" => 10.minutes,
    "two_factor" => 5.minutes
  }.freeze

  def active?
    !verified? && !expired? && attempts < MAX_ATTEMPTS
  end

  def expired?
    expires_at <= Time.current
  end

  def max_attempts_reached?
    attempts >= MAX_ATTEMPTS
  end

  def verify!(ip_address = nil)
    if active?
      update!(
        verified: true,
        verified_at: Time.current,
        ip_address: ip_address
      )

      # Auto-verify user's email/phone based on code type
      case code_type
      when "email_verification"
        user.confirm_email!
      when "phone_verification"
        user.update!(phone_verified: true)
      end

      true
    else
      false
    end
  end

  def increment_attempts!
    increment!(:attempts)
  end

  def self.find_valid_code(code, type)
    active.by_type(type).find_by(code: code)
  end

  def self.cleanup_expired
    expired.delete_all
  end

  def self.generate_for_user(user, type, contact_method, ip_address = nil, user_agent = nil)
    # Invalidate any existing active codes of this type for this user
    where(user: user, code_type: type).active.update_all(verified: true)

    # Create new verification code
    create!(
      user: user,
      code_type: type,
      contact_method: contact_method,
      ip_address: ip_address,
      user_agent: user_agent
    )
  end

  def self.verify_code(code, type, user = nil)
    verification_code = if user
      user.verification_codes.find_valid_code(code, type)
    else
      find_valid_code(code, type)
    end

    return { success: false, error: "Invalid or expired code" } unless verification_code

    if verification_code.max_attempts_reached?
      return { success: false, error: "Maximum attempts reached" }
    end

    if verification_code.verify!
      { success: true, user: verification_code.user }
    else
      verification_code.increment_attempts!
      { success: false, error: "Code verification failed" }
    end
  end

  private

  def generate_code
    case code_type
    when "two_factor"
      # For 2FA, generate a time-based code (could be TOTP)
      self.code = sprintf("%06d", SecureRandom.random_number(1000000))
    else
      # For email/phone verification, generate a random 6-digit code
      self.code = sprintf("%06d", SecureRandom.random_number(1000000))
    end
  end

  def set_expiry
    duration = EXPIRY_DURATION[code_type] || 10.minutes
    self.expires_at = duration.from_now
  end
end
