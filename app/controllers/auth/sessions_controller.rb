class Auth::SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create ]
  before_action :authenticate_user!, only: [ :destroy, :status, :logout_confirmation ]

  def new
    # Login form
  end

  def create
    service = Auth::LoginService.new(
      email: params[:email],
      password: params[:password]
    )

    if service.call
      sign_in_user(service.user)
      flash[:success] = "Welcome back, #{service.user.first_name}! 🎉"
      redirect_to after_sign_in_path
    else
      flash.now[:error] = service.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def logout_confirmation
    # Show logout confirmation page for GET requests to /auth/logout
  end

  def destroy
    # Get user name before destroying session
    user_name = current_user&.first_name || "User"

    # Clear any remember me tokens if they exist
    clear_remember_me_tokens if respond_to?(:clear_remember_me_tokens, true)

    # Sign out the user
    sign_out_user

    # Set flash message
    flash[:success] = "#{user_name}, you have been logged out successfully. Thank you for using OpenRoles! 👋"

    # Respond based on request format
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: { success: true, message: "Logged out successfully" } }
      format.js { redirect_to root_path }
    end
  end

  def status
    # Endpoint to check session status
    respond_to do |format|
      format.json do
        render json: {
          authenticated: user_signed_in?,
          user: current_user ? {
            id: current_user.id,
            name: current_user.full_name,
            email: current_user.email,
            email_verified: current_user.email_verified?
          } : nil,
          session_info: {
            signed_in_at: session[:signed_in_at],
            last_activity: session[:last_activity]
          }
        }
      end
    end
  end

  private

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to after_sign_in_path
    end
  end

  def after_sign_in_path
    stored_location_for_user || root_path
  end
end
