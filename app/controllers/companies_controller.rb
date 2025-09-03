# frozen_string_literal: true

class CompaniesController < ApplicationController
  before_action :set_companies_service

  def index
    companies = @companies_service.get_filtered_companies(filters: filter_params)
    @pagy, @companies = pagy(companies, limit: params[:per_page] || 24)

    @total_companies_count = Company.count
    @companies_with_jobs_count = Company.joins(:jobs).where(jobs: { status: JobStatus::OPEN }).distinct.count
    @featured_industries = @companies_service.featured_industries

    respond_to do |format|
      format.html
      format.json { render json: { companies: @companies, pagination: pagy_metadata(@pagy) } }
    end
  end

  def show
    @company = Company.includes(:jobs).find(params[:id])
    @companies_service.track_company_view(@company)

    @pagy, @company_jobs = @companies_service.company_jobs(
      @company,
      page: params[:page],
      per_page: params[:per_page] || 10
    )

    @company_stats = @companies_service.company_statistics(@company)
    @similar_companies = @companies_service.similar_companies(@company, limit: 6)
  rescue ActiveRecord::RecordNotFound
    redirect_to companies_path, alert: "Company not found."
  end

  def jobs
    @company = Company.find(params[:id])
    @pagy, @jobs = @companies_service.company_jobs(
      @company,
      page: params[:page],
      per_page: params[:per_page] || 20,
      filters: job_filter_params
    )

    respond_to do |format|
      format.html { render :show }
      format.json { render json: { jobs: @jobs, pagination: pagy_metadata(@pagy) } }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to companies_path, alert: "Company not found."
  end

  def search
    @query = params[:q]
    @location = params[:location]

    @pagy, @companies = @companies_service.search_companies(
      query: @query,
      location: @location,
      page: params[:page],
      per_page: params[:per_page] || 24,
      filters: filter_params
    )

    @search_metadata = @companies_service.search_metadata(@query, @location)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { companies: @companies, pagination: pagy_metadata(@pagy), metadata: @search_metadata } }
    end
  end

  private

  def set_companies_service
    @companies_service = Companies::BrowsingService.new
  end

  def filter_params
    params.permit(
      :industry, :location, :size, :has_jobs, :verified
    ).to_h.compact_blank
  end

  def job_filter_params
    params.permit(
      :employment_type, :salary_min, :salary_max, :location,
      :posted_after, :has_salary, tag_ids: []
    ).to_h.compact_blank
  end
end
