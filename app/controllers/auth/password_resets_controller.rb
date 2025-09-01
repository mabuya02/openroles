class Auth::PasswordResetsController < ApplicationController
  before_action :find_user_and_verification_code

  def new
    # Show password reset form
  end

  def update
    if @verification_code.expired?
      flash[:error] = "Password reset link has expired. Please request a new one."
      redirect_to auth_new_registration_path
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:error] = "Passwords don't match"
      render :new, status: :unprocessable_entity
      return
    end

    if params[:password].length < 8
      flash.now[:error] = "Password must be at least 8 characters long"
      render :new, status: :unprocessable_entity
      return
    end

    # Update user password and mark as verified
    if @user.update(
      password: params[:password],
      email_verified: true,  # Now they can log in
      status: UserStatus::ACTIVE  # Activate the account
    )
      # Mark verification code as used
      @verification_code.update(verified: true, verified_at: Time.current)

      flash[:success] = "Password set successfully! You can now log in."
      redirect_to auth_new_session_path
    else
      flash.now[:error] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_user_and_verification_code
    @user = User.find(params[:user_id])
    @verification_code = @user.verification_codes
                             .where(code: params[:code], code_type: "password_reset")
                             .first

    unless @verification_code
      flash[:error] = "Invalid password reset link"
      redirect_to auth_new_registration_path
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "User not found"
    redirect_to auth_new_registration_path
  end
end
