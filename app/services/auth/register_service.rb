class Auth::RegisterService < Auth::BaseService
  attr_reader :verification_code

  def initialize(user_params)
    super()
    @user_params = user_params.to_h.with_indifferent_access
  end

  def call
    return false unless valid_params?

    User.transaction do
      create_user
      return false unless @user.persisted?

      create_user_profile
      generate_verification_code
      send_verification_email
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    add_errors(e.record.errors.full_messages)
    false
  end

  private

  def valid_params?
    required_fields = %w[email password first_name last_name]

    required_fields.each do |field|
      add_error("#{field.humanize} is required") if @user_params[field].blank?
    end

    # Use base class password validation
    if @user_params[:password].present?
      valid_password?(@user_params[:password])
      passwords_match?(@user_params[:password], @user_params[:password_confirmation])
    end

    if @user_params[:email].present? && User.exists?(email: @user_params[:email].downcase.strip)
      add_error("Email has already been taken")
    end

    @errors.empty?
  end

  def create_user
    @user = User.new(
      email: @user_params[:email].downcase.strip,
      password: @user_params[:password],
      first_name: @user_params[:first_name].strip,
      last_name: @user_params[:last_name].strip,
      phone_number: @user_params[:phone_number]&.strip,
      email_verified: false,
      two_factor_enabled: false
    )
    # Let the User model set the default status via callback

    @user.save!
  end

  def create_user_profile
    UserProfile.create!(
      user: @user,
      bio: nil,
      skills: nil,
      portfolio_url: nil,
      linkedin_url: nil,
      github_url: nil
    )
  end

  def generate_verification_code
    @verification_code = VerificationCode.create!(
      user: @user,
      code_type: "email_verification",
      contact_method: "email",
      code: SecureRandom.urlsafe_base64(32),  # Generate a secure token instead of 6-digit code
      expires_at: 24.hours.from_now
    )
  end

  def send_verification_email
    EmailVerificationJob.perform_later(@user.id, @verification_code.id)
    Rails.logger.info "Email verification job queued for #{@user.email}"
  end
end
