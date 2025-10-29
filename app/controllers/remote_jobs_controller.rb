# frozen_string_literal: true

class RemoteJobsController < ApplicationController
  include LiveSearchable
  
  before_action :set_remote_jobs_service

  def index
    jobs = @remote_jobs_service.get_filtered_remote_jobs(filters: filter_params)
    @pagy, @jobs = pagy(jobs, limit: params[:per_page] || 20)

    @total_remote_jobs_count = Job.remote_friendly.published.count
    @remote_companies_count = Company.joins(:jobs).where(jobs: { status: JobStatus::OPEN })
                                     .where("jobs.location ILIKE ? OR jobs.location ILIKE ?", "%remote%", "%worldwide%")
                                     .distinct.count
    @featured_remote_companies = @remote_jobs_service.featured_remote_companies
    @remote_job_trends = @remote_jobs_service.remote_job_trends

    respond_to do |format|
      format.html
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy) } }
    end
  end

  def search
    @query = params[:q]
    @skills = params[:skills]

    if @query.present?
      # Use natural language search service for remote jobs
      search_service = NaturalLanguageSearchService.new(@query)
      jobs = search_service.parse_and_search

      # Filter to only remote-friendly jobs
      jobs = jobs.remote_friendly

      # Apply additional filters
      jobs = apply_remote_filters(jobs, filter_params)

      @pagy, @jobs = pagy(jobs, limit: params[:per_page] || 20)
      @search_metadata = {
        query: @query,
        total_results: @pagy.count,
        parsed_data: search_service.parsed_data,
        external_results: jobs.where.not(source: "internal").count
      }
    else
      # Fallback to service method
      @pagy, @jobs = @remote_jobs_service.search_remote_jobs(
        query: @query,
        skills: @skills,
        page: params[:page],
        per_page: params[:per_page] || 20,
        filters: filter_params
      )
      @search_metadata = @remote_jobs_service.search_metadata(@query, @skills)
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy), metadata: @search_metadata } }
    end
  end

  def live_search
    result = perform_live_search(jobs_scope: Job.remote_friendly.published)
    
    # Add salary info for remote jobs
    result[:suggestions].each do |suggestion|
      job = Job.find(suggestion[:id])
      suggestion[:salary] = job.salary_range_display if job.respond_to?(:salary_range_display)
    end
    
    respond_to do |format|
      format.json { render json: result }
    end
  end

  def filter
    @pagy, @jobs = @remote_jobs_service.filter_remote_jobs(
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

  def set_remote_jobs_service
    @remote_jobs_service = Remote::JobsService.new
  end

  private

  def apply_remote_filters(jobs, params)
    # Apply remote-specific filters - use the scope, not a column
    if params[:remote].present? && params[:remote] != "false"
      jobs = jobs.remote_friendly
    end

    jobs
  end

  def filter_params
    params.permit(
      :employment_type, :salary_min, :salary_max, :company_id, :time_zone,
      :posted_after, :has_salary, :source, :experience_level, tag_ids: []
    ).to_h.compact_blank
  end
end
