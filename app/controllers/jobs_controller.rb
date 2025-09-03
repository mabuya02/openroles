# frozen_string_literal: true

class JobsController < ApplicationController
  before_action :set_jobs_service

  def index
    jobs = @jobs_service.get_filtered_jobs(filters: filter_params)
    @pagy, @jobs = pagy(jobs, limit: params[:per_page] || 20)

    @companies_count = Company.count
    @total_jobs_count = Job.published.count
    @featured_companies = Company.limit(6)

    respond_to do |format|
      format.html
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy) } }
    end
  end

  def show
    @job = Job.published.includes(:company, :tags).find(params[:id])
    @jobs_service.track_job_view(@job)
    @related_jobs = @jobs_service.related_jobs(@job, limit: 6)
  rescue ActiveRecord::RecordNotFound
    redirect_to jobs_path, alert: "Job not found or no longer available."
  end

  def search
    @query = params[:q]
    @location = params[:location]

    @pagy, @jobs = @jobs_service.search_jobs(
      query: @query,
      location: @location,
      page: params[:page],
      per_page: params[:per_page] || 20,
      filters: filter_params
    )

    @search_metadata = @jobs_service.search_metadata(@query, @location)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy), metadata: @search_metadata } }
    end
  end

  def filter
    @pagy, @jobs = @jobs_service.filter_jobs(
      filters: filter_params,
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy) } }
    end
  end

  private

  def set_jobs_service
    @jobs_service = Jobs::BrowsingService.new
  end

  def filter_params
    params.permit(
      :employment_type, :salary_min, :salary_max, :location, :company_id,
      :posted_after, :has_salary, :source, tag_ids: []
    ).to_h.compact_blank
  end
end
