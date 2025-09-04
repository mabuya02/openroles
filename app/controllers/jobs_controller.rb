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
    @query = params[:q]&.strip
    @location = params[:location]

    if @query.present?
      # Use natural language search service
      search_service = NaturalLanguageSearchService.new(@query)
      jobs = search_service.parse_and_search

      # Apply additional location filter if specified
      if @location.present?
        jobs = jobs.where("location ILIKE ?", "%#{@location}%")
      end

      @pagy, @jobs = pagy(jobs, limit: params[:per_page] || 20)
      @search_metadata = {
        query: @query,
        location: @location,
        total_results: @pagy.count,
        parsed_data: search_service.parsed_data,
        external_results: jobs.where.not(source: "internal").count
      }
    else
      # Fallback to regular filtering
      jobs = @jobs_service.get_filtered_jobs(filters: filter_params)
      @pagy, @jobs = pagy(jobs, limit: params[:per_page] || 20)
      @search_metadata = @jobs_service.search_metadata(@query, @location)
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy), metadata: @search_metadata } }
    end
  end

  def live_search
    @query = params[:q]&.strip

    if @query.present? && @query.length >= 2
      # Use natural language search service for live search
      search_service = NaturalLanguageSearchService.new(@query)
      jobs = search_service.parse_and_search.limit(10)

      @suggestions = jobs.includes(:company).map do |job|
        {
          id: job.id,
          title: job.title,
          company: job.company.name,
          location: job.location,
          employment_type: job.employment_type&.humanize,
          url: job_path(job),
          company_url: company_path(job.company)
        }
      end

      # Add intelligent suggestions based on parsed query
      @search_metadata = {
        parsed_data: search_service.parsed_data,
        suggestions_count: @suggestions.length
      }
    else
      @suggestions = []
      @search_metadata = {}
    end

    respond_to do |format|
      format.json { render json: { suggestions: @suggestions, metadata: @search_metadata } }
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
