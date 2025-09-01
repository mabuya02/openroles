class UserMailer < ApplicationMailer
  layout "mailer"

  def email_verification(user, verification_code)
    @user = user
    @verification_code = verification_code
    @verification_url = auth_verify_email_url(
      user_id: @user.id,
      code: @verification_code.code
    )

    mail(
      to: @user.email,
      subject: "Verify your OpenRoles account",
      template_path: "mails",
      template_name: "email_verification"
    )
  end

  def password_reset_instructions(user, verification_code)
    @user = user
    @verification_code = verification_code
    @default_password = "OpenRoles2025!"
    @reset_url = auth_password_reset_url(
      user_id: @user.id,
      code: @verification_code.code
    )

    mail(
      to: @user.email,
      subject: "Welcome to OpenRoles - Set Your Password",
      template_path: "mails",
      template_name: "password_reset_instructions"
    )
  end

  def password_reset(user, reset_token)
    @user = user
    @reset_token = reset_token
    @reset_url = auth_edit_password_url(token: @reset_token)

    mail(
      to: @user.email,
      subject: "Reset your OpenRoles password",
      template_path: "mails",
      template_name: "password_reset"
    )
  end

  def password_changed(user)
    @user = user

    mail(
      to: @user.email,
      subject: "Your OpenRoles password has been changed",
      template_path: "mails",
      template_name: "password_changed"
    )
  end
end
