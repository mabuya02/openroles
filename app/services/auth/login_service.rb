class Auth::LoginService < Auth::BaseService
  def initialize(email:, password:)
    super()
    @email = email.to_s.downcase.strip
    @password = password.to_s
  end

  def call
    return false unless valid_params?
    return false unless authenticate_user
    return false unless user_can_login?

    true
  end

  private

  def valid_params?
    add_error("Email is required") if @email.blank?
    add_error("Password is required") if @password.blank?

    @errors.empty?
  end

  def authenticate_user
    @user = User.find_by(email: @email)

    unless @user&.authenticate(@password)
      add_error("Invalid email or password")
      return false
    end

    true
  end

  def user_can_login?
    unless @user.active?
      add_error("Your account is not active. Please contact support.")
      return false
    end

    if @user.suspended?
      add_error("Your account has been suspended. Please contact support.")
      return false
    end

    unless @user.email_verified?
      add_error("Please verify your email address before logging in.")
      return false
    end

    true
  end
end
