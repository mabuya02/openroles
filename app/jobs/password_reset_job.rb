class PasswordResetJob < ApplicationJob
  queue_as :default

  def perform(user_id, verification_code_id)
    user = User.find(user_id)
    verification_code = VerificationCode.find(verification_code_id)
    UserMailer.password_reset_instructions(user, verification_code).deliver_now
  end
end
