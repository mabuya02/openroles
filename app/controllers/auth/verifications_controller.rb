class Auth::VerificationsController < ApplicationController
  before_action :authenticate_user!, except: [ :verify_email ]

  def verify_email
    user = User.find_by(id: params[:user_id])

    unless user
      flash[:error] = "Invalid verification link"
      redirect_to root_path
      return
    end

    service = Auth::VerificationService.new(
      code: params[:code],
      user: user,
      code_type: "email_verification"
    )

    if service.verify_code
      flash[:success] = "Your email has been verified successfully!"
      redirect_to auth_new_session_path
    else
      flash[:error] = service.errors.join(", ")
      redirect_to auth_new_session_path
    end
  end

  def resend_email
    service = Auth::VerificationService.new(
      user: current_user,
      code_type: "email_verification"
    )

    if service.resend_verification
      flash[:success] = "Verification email sent. Please check your inbox."
    else
      flash[:error] = service.errors.join(", ")
    end

    redirect_back(fallback_location: root_path)
  end

  def verify_phone
    service = Auth::VerificationService.new(
      code: params[:code],
      user: current_user,
      code_type: "phone_verification"
    )

    if service.verify_code
      flash[:success] = "Your phone number has been verified successfully!"
      redirect_to profile_path
    else
      flash[:error] = service.errors.join(", ")
      redirect_back(fallback_location: profile_path)
    end
  end

  def resend_phone
    service = Auth::VerificationService.new(
      user: current_user,
      code_type: "phone_verification"
    )

    if service.resend_verification
      flash[:success] = "Verification code sent to your phone."
    else
      flash[:error] = service.errors.join(", ")
    end

    redirect_back(fallback_location: profile_path)
  end
end
