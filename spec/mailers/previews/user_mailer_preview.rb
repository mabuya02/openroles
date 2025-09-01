# Preview all emails at http://localhost:3000/rails/mailers/user_mailer_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer_mailer/email_verification
  def email_verification
    UserMailer.email_verification
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer_mailer/password_reset
  def password_reset
    UserMailer.password_reset
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer_mailer/password_changed
  def password_changed
    UserMailer.password_changed
  end

end
