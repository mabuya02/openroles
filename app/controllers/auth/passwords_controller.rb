class Auth::PasswordsController < ApplicationController
  def new
    # Request password reset form
  end

  def create
    service = Auth::PasswordResetService.new(
      email: params[:email],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if service.request_reset
      flash[:success] = "If an account with that email exists, you will receive password reset instructions shortly."
    else
      flash[:error] = service.errors.join(", ")
    end

    redirect_to auth_new_password_path
  end

  def edit
    @token = params[:token]

    unless @token
      flash[:error] = "Invalid reset link"
      redirect_to auth_new_password_path
    end
  end

  def update
    service = Auth::PasswordResetService.new(
      token: params[:token],
      new_password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if service.reset_password
      flash[:success] = "Your password has been reset successfully. Please log in."
      redirect_to auth_new_session_path
    else
      flash.now[:error] = service.errors.join(", ")
      @token = params[:token]
      render :edit, status: :unprocessable_entity
    end
  end
end
