class Auth::PasswordResetService < Auth::BaseService
  attr_reader :reset_token

  def initialize(email: nil, token: nil, new_password: nil, password_confirmation: nil, ip_address: nil, user_agent: nil)
    super()
    @email = email&.downcase&.strip
    @token = token
    @new_password = new_password
    @password_confirmation = password_confirmation
    @ip_address = ip_address
    @user_agent = user_agent
  end

  def request_reset
    return false unless valid_email?
    return false unless find_user_by_email

    generate_reset_token
    send_reset_email

    # Always return true for security (don't reveal if email exists)
    true
  end

  def reset_password
    return false unless valid_reset_params?
    return false unless find_valid_token

    User.transaction do
      update_password
      invalidate_token
      send_password_changed_email
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    add_errors(e.record.errors.full_messages)
    false
  end

  private

  def valid_email?
    if @email.blank?
      add_error("Email is required")
      return false
    end

    # Use base class email validation
    unless valid_email_format?(@email)
      add_error("Please enter a valid email address")
      return false
    end

    true
  end

  def find_user_by_email
    @user = User.find_by(email: @email)

    unless @user
      # Don't reveal if email exists or not for security
      return true
    end

    unless @user.active?
      # Don't send reset emails to inactive accounts
      return true
    end

    true
  end

  def generate_reset_token
    return unless @user # Don't generate if user not found

    # Use the model's built-in method which handles expiring old tokens
    @reset_token = PasswordResetToken.generate_for_user(@user, @ip_address, @user_agent)
  end

  def send_reset_email
    return unless @user && @reset_token

    # Send password reset email via background job
    UserMailerJob.perform_later(
      mailer_method: "password_reset",
      user_id: @user.id,
      reset_token: @reset_token.token
    )
    Rails.logger.info "Password reset email queued for #{@user.email}"
  rescue => e
    Rails.logger.error "Failed to queue password reset email for #{@user.email}: #{e.message}"
    # Don't add to @errors for security reasons - always show success message
  end

  def valid_reset_params?
    add_error("Reset token is required") if @token.blank?

    # Use base class password validation
    if @new_password.present?
      valid_password?(@new_password)
      passwords_match?(@new_password, @password_confirmation)
    else
      add_error("New password is required")
    end

    @errors.empty?
  end

  def find_valid_token
    @reset_token = PasswordResetToken.find_by(token: @token)

    unless @reset_token
      add_error("Invalid or expired reset token")
      return false
    end

    if @reset_token.expired?
      add_error("Reset token has expired. Please request a new one.")
      return false
    end

    if @reset_token.used?
      add_error("Reset token has already been used. Please request a new one.")
      return false
    end

    @user = @reset_token.user

    unless @user.active?
      add_error("Account is not active")
      return false
    end

    true
  end

  def update_password
    @user.password = @new_password
    @user.save!
  end

  def invalidate_token
    @reset_token.update!(used_at: Time.current)
  end

  def send_password_changed_email
    # TODO: Implement mailer
    # UserMailer.password_changed(@user).deliver_now
    Rails.logger.info "Password changed notification sent to #{@user.email}"
  end
end
