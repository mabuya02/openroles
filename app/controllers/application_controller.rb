class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Add helper methods for authentication (when you implement user authentication)
  private

  def current_user
    # This will be implemented when you add user authentication
    # For now, return nil
    nil
  end

  def user_signed_in?
    # This will be implemented when you add user authentication
    # For now, return false
    false
  end

  # Make these methods available in views
  helper_method :current_user, :user_signed_in?
end
