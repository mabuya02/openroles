class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :email, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(used: false).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used, -> { where(used: true) }

  before_create :generate_token
  before_create :set_expiry

  def active?
    !used? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def mark_as_used!(ip_address = nil)
    update!(
      used: true,
      used_at: Time.current,
      ip_address: ip_address
    )
  end

  def self.find_valid_token(token)
    active.find_by(token: token)
  end

  def self.cleanup_expired
    expired.delete_all
  end

  def self.generate_for_user(user, ip_address = nil, user_agent = nil)
    # Invalidate any existing tokens for this user
    where(user: user).update_all(used: true)

    # Generate unique token
    token = nil
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break unless exists?(token: token)
    end

    # Create new token with explicit values
    create!(
      user: user,
      email: user.email,
      token: token,
      expires_at: 1.hour.from_now,
      ip_address: ip_address,
      user_agent: user_agent
    )
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at = 1.hour.from_now
  end
end
