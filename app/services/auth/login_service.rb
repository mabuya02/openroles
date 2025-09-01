class Auth::LoginService
  attr_reader :user, :errors

  def initialize(email:, password:)
    @email = email.to_s.downcase.strip
    @password = password.to_s
    @errors = []
  end

  def call
    return false unless valid_params?
    return false unless authenticate_user
    return false unless user_can_login?

    true
  end

  def success?
    @user.present? && @errors.empty?
  end

  private

  def valid_params?
    if @email.blank?
      @errors << "Email is required"
    end

    if @password.blank?
      @errors << "Password is required"
    end

    @errors.empty?
  end

  def authenticate_user
    @user = User.find_by(email: @email)

    unless @user&.authenticate(@password)
      @errors << "Invalid email or password"
      return false
    end

    true
  end

  def user_can_login?
    unless @user.active?
      @errors << "Your account is not active. Please contact support."
      return false
    end

    if @user.suspended?
      @errors << "Your account has been suspended. Please contact support."
      return false
    end

    unless @user.email_verified?
      @errors << "Please verify your email address before logging in."
      return false
    end

    true
  end
end
