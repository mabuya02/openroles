class Auth::VerificationService < Auth::BaseService
  attr_reader :verification_code

  def initialize(code: nil, user: nil, code_type: "email_verification")
    super()
    @code = code&.strip  # Remove upcase since we're using tokens now
    @user = user
    @code_type = code_type
  end

  def verify_code
    return false unless valid_params?
    return false unless find_verification_code
    return false unless code_valid?

    User.transaction do
      mark_as_verified
      mark_code_as_used
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    add_errors(e.record.errors.full_messages)
    false
  end

  def resend_verification
    return false unless @user
    return false unless can_resend?

    generate_new_code
    send_verification

    true
  end

  private

  def valid_params?
    add_error("Verification link is invalid") if @code.blank?
    add_error("User is required") unless @user

    @errors.empty?
  end

  def find_verification_code
    @verification_code = VerificationCode
      .where(user: @user, code_type: @code_type)
      .where("expires_at > ?", Time.current)
      .where(verified_at: nil)
      .find_by(code: @code)

    unless @verification_code
      add_error("Invalid or expired verification code")
      return false
    end

    true
  end

  def code_valid?
    if @verification_code.expired?
      add_error("Verification code has expired")
      return false
    end

    if @verification_code.max_attempts_reached?
      add_error("Maximum verification attempts reached. Please request a new code.")
      return false
    end

    # Increment attempt count
    @verification_code.increment!(:attempts)

    true
  end

  def mark_as_verified
    case @code_type
    when "email_verification"
      @user.update!(email_verified: true, status: UserStatus::ACTIVE)
    when "phone_verification"
      @user.update!(phone_verified: true) if @user.respond_to?(:phone_verified)
    when "two_factor"
      # For 2FA, we don't update user status, just mark the code as used
    end
  end

  def mark_code_as_used
    @verification_code.update!(verified_at: Time.current)
  end

  def can_resend?
    last_code = VerificationCode
      .where(user: @user, code_type: @code_type)
      .order(created_at: :desc)
      .first

    if last_code && last_code.created_at > 1.minute.ago
      add_error("Please wait before requesting another verification code")
      return false
    end

    case @code_type
    when "email_verification"
      if @user.email_verified?
        add_error("Email is already verified")
        return false
      end
    when "phone_verification"
      if @user.phone_verified?
        add_error("Phone number is already verified")
        return false
      end

      unless @user.phone_number.present?
        add_error("Phone number is required for verification")
        return false
      end
    end

    true
  end

  def generate_new_code
    # Expire existing codes
    VerificationCode
      .where(user: @user, code_type: @code_type, verified_at: nil)
      .update_all(verified_at: Time.current)

    code_value = case @code_type
    when "two_factor"
      SecureRandom.random_number(1000000).to_s.rjust(6, "0")
    else
      SecureRandom.alphanumeric(6).upcase
    end

    @verification_code = VerificationCode.create!(
      user: @user,
      code_type: @code_type,
      code: code_value,
      expires_at: code_expiry
    )
  end

  def send_verification
    case @code_type
    when "email_verification"
      # TODO: Implement mailer
      # UserMailer.email_verification(@user, @verification_code.code).deliver_now
      Rails.logger.info "Email verification code for #{@user.email}: #{@verification_code.code}"
    when "phone_verification"
      # TODO: Implement SMS service
      # SmsService.send_verification(@user.phone_number, @verification_code.code)
      Rails.logger.info "Phone verification code for #{@user.phone_number}: #{@verification_code.code}"
    when "two_factor"
      # TODO: Implement SMS/email for 2FA
      Rails.logger.info "Two-factor code for #{@user.email}: #{@verification_code.code}"
    end
  end

  def code_expiry
    case @code_type
    when "two_factor"
      5.minutes.from_now
    when "phone_verification"
      10.minutes.from_now
    else
      24.hours.from_now
    end
  end
end
