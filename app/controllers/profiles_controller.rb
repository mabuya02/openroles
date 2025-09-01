class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_profile

  def show
    # Display user profile
  end

  def edit
    # Edit user profile form
  end

  def update
    service = ProfileService.new(@user_profile)

    if service.update_profile(user_profile_params)
      flash[:success] = "Profile updated successfully!"
      redirect_to profile_path
    else
      flash.now[:error] = "Failed to update profile. Please check the errors below."
      render :edit, status: :unprocessable_entity
    end
  rescue => e
    flash.now[:error] = "An error occurred: #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def remove_attachment
    attachment_id = params[:attachment_id]
    attachment_type = params[:attachment_type]

    service = ProfileService.new(@user_profile)
    result = service.remove_attachment(attachment_id, attachment_type)

    respond_to do |format|
      if result[:success]
        flash[:success] = result[:message]
        format.html { redirect_to profile_path }
        format.json { render json: { success: true, message: result[:message], redirect_url: profile_path } }
      else
        flash[:error] = result[:message]
        format.html { redirect_to profile_path }
        format.json { render json: { success: false, message: result[:message] }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user_profile
    @user_profile = ProfileService.find_or_create_for_user(current_user)
  end

  def user_profile_params
    params.require(:user_profile).permit(
      :bio, :linkedin_url, :github_url, :portfolio_url, :skills,
      :profile_picture, :resume, portfolio_files: [], certificates: []
    )
  end
end
