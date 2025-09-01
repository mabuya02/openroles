class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Authentication methods
  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = authenticate_with_session
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      store_user_location!
      flash[:error] = "You need to sign in to access this page."
      redirect_to auth_new_session_path
    end
  end

  def authenticate_with_session
    user_id = session[:user_id]
    return nil unless user_id

    # Check for session timeout (24 hours)
    signed_in_at = session[:signed_in_at]
    if signed_in_at && Time.current.to_i - signed_in_at.to_i > 24.hours.to_i
      sign_out_user
      return nil
    end

    user = User.find_by(id: user_id)
    return nil unless user&.active?

    # Update last activity timestamp
    session[:last_activity] = Time.current.to_i

    user
  end

  def sign_in_user(user)
    session[:user_id] = user.id
    session[:signed_in_at] = Time.current.to_i
    session[:last_activity] = Time.current.to_i

    # Update user's last sign in information
    begin
      user.update_columns(
        last_sign_in_at: Time.current,
        last_sign_in_ip: request.remote_ip
      )
    rescue => e
      # Log the error but don't fail the login process
      Rails.logger.warn "Failed to update user sign-in info: #{e.message}"
    end
  end

  def sign_out_user
    session.delete(:user_id)
    session.delete(:signed_in_at)
    session.delete(:last_activity)
    reset_session
  end

  def store_user_location!
    # Store the location the user was trying to access if it's a GET request
    if request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
      session[:user_return_to] = request.fullpath
    end
  end

  def stored_location_for_user
    session.delete(:user_return_to)
  end

  def is_navigational_format?
    Mime::Type.lookup_by_extension(:html).nil? ? false : request.format.html?
  end

  def devise_controller?
    # Check if this is an auth controller (similar to devise)
    controller_path.start_with?("auth/")
  end

  # Make these methods available in views
  helper_method :current_user, :user_signed_in?
end
