class ProfileService
  def initialize(user_profile)
    @user_profile = user_profile
  end

  def update_profile(params)
    # Get sanitized parameters
    profile_params = extract_profile_params(params)

    # Handle file attachments separately
    handle_portfolio_files(params[:portfolio_files]) if params[:portfolio_files].present?
    handle_certificates(params[:certificates]) if params[:certificates].present?

    # Remove file parameters from profile params to avoid conflicts
    profile_params = profile_params.except(:portfolio_files, :certificates)

    # Update the profile
    @user_profile.update(profile_params)
  end

  def remove_attachment(attachment_id, attachment_type)
    attachment = find_attachment(attachment_id, attachment_type)
    return { success: false, message: "File not found!" } unless attachment

    begin
      attachment.purge
      { success: true, message: "File removed successfully!" }
    rescue => e
      { success: false, message: "Error removing file: #{e.message}" }
    end
  end

  def self.find_or_create_for_user(user)
    user.user_profile || user.create_user_profile!
  end

  private

  def extract_profile_params(params)
    params.permit(
      :bio, :linkedin_url, :github_url, :portfolio_url, :skills,
      :profile_picture, :resume, portfolio_files: [], certificates: []
    )
  end

  def handle_portfolio_files(files)
    new_files = files.reject(&:blank?)
    @user_profile.portfolio_files.attach(new_files) if new_files.any?
  end

  def handle_certificates(files)
    new_files = files.reject(&:blank?)
    @user_profile.certificates.attach(new_files) if new_files.any?
  end

  def find_attachment(attachment_id, attachment_type)
    case attachment_type
    when "portfolio_file"
      @user_profile.portfolio_files.find_by(id: attachment_id)
    when "certificate"
      @user_profile.certificates.find_by(id: attachment_id)
    when "resume"
      @user_profile.resume if @user_profile.resume.attached?
    when "profile_picture"
      @user_profile.profile_picture if @user_profile.profile_picture.attached?
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
