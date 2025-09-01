class Auth::RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create ]

  def new
    # Registration form
  end

  def create
    service = Auth::RegisterService.new(registration_params)

    if service.call
      flash[:success] = "Account created successfully! Please check your email and click the verification link to activate your account."
      redirect_to auth_new_session_path
    else
      flash.now[:error] = service.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :phone_number
    )
  end

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to root_path
    end
  end
end
