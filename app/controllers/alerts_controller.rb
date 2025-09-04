class AlertsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_alert, only: [ :show, :edit, :update, :toggle_status, :unsubscribe_confirmation, :unsubscribe_alert ]

  # Temporarily skip CSRF protection to debug the issue
  skip_before_action :verify_authenticity_token, only: [ :update ]

  def index
    @alerts = current_user.alerts.order(created_at: :desc)
  end

  def show
    @matching_jobs = @alert.matching_jobs.includes(:company).limit(20)
  end

  def new
    @alert = current_user.alerts.build

    # Pre-populate with search query if coming from search
    if params[:query].present?
      @alert.criteria = { "natural_query" => params[:query] }
    end
  end

  def create
    @alert = current_user.alerts.build(alert_params)

    # Process natural language query
    if params[:alert][:natural_query].present?
      @alert.criteria = process_natural_query(params[:alert][:natural_query])
    end

    if @alert.save
      redirect_to alerts_path, notice: "Job alert created successfully! You will receive notifications based on your selected frequency."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Process natural language query if provided
    if params[:alert][:natural_query].present?
      updated_criteria = process_natural_query(params[:alert][:natural_query])
      @alert.criteria = updated_criteria
    end

    # Update other attributes
    @alert.assign_attributes(alert_params)

    if @alert.save
      redirect_to @alert, notice: "Job alert updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def unsubscribe_confirmation
    # Just render the confirmation page
  end

  def unsubscribe_alert
    @alert.unsubscribe!
    alert_description = @alert.criteria&.dig("natural_query") || "Job Alert"
    redirect_to alerts_path, notice: "You have successfully unsubscribed from \"#{alert_description}\". You can reactivate it anytime from your alerts page."
  end

  def toggle_status
    new_status = @alert.status == AlertStatus::ACTIVE ? AlertStatus::INACTIVE : AlertStatus::ACTIVE
    @alert.update(status: new_status)

    status_text = new_status == AlertStatus::ACTIVE ? "activated" : "deactivated"
    redirect_to alerts_path, notice: "Job alert #{status_text} successfully."
  end

  def unsubscribe
    @alert = Alert.find_by(unsubscribe_token: params[:token])

    if @alert
      @alert.unsubscribe!
      render :unsubscribed, layout: "minimal"
    else
      render :invalid_unsubscribe_link, layout: "minimal", status: :not_found
    end
  end

  def test_alert
    @alert = current_user.alerts.find(params[:id])
    @matching_jobs = @alert.matching_jobs.includes(:company).limit(10)

    if @matching_jobs.any?
      # Send test email - convert relation to array to avoid query issues in email template
      jobs_array = @matching_jobs.to_a
      AlertMailer.job_alert_notification(@alert, jobs_array).deliver_now
      redirect_to @alert, notice: "Test alert sent successfully! Check your email."
    else
      redirect_to @alert, alert: "No matching jobs found for your alert criteria."
    end
  end

  private

  def set_alert
    @alert = current_user.alerts.find(params[:id])
  end

  def alert_params
    params.require(:alert).permit(:frequency, tag_ids: [])
  end

  def process_natural_query(query)
    search_service = NaturalLanguageSearchService.new(query)
    search_service.parse_query_only

    criteria = { "natural_query" => query }

    # Add parsed data to criteria for better filtering
    if search_service.parsed_data[:company].present?
      criteria["company_name"] = search_service.parsed_data[:company]
    end

    if search_service.parsed_data[:employment_type].present?
      criteria["employment_type"] = search_service.parsed_data[:employment_type]
    end

    if search_service.parsed_data[:remote]
      criteria["remote_only"] = true
    end

    if search_service.parsed_data[:job_title_keywords].any?
      criteria["keywords"] = search_service.parsed_data[:job_title_keywords].join(" ")
    end

    criteria
  end

  def authenticate_user!
    unless current_user
      redirect_to auth_new_session_path, alert: "Please sign in to manage job alerts."
    end
  end
end
