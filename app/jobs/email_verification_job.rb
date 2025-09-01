class EmailVerificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, verification_code_id)
    user = User.find(user_id)
    verification_code = VerificationCode.find(verification_code_id)

    UserMailer.email_verification(user, verification_code).deliver_now
    Rails.logger.info "Email verification code sent to #{user.email} via background job"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "EmailVerificationJob failed: #{e.message}"
  end
end
