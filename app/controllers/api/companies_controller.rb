class Api::CompaniesController < Api::BaseController
  before_action :set_company, only: [ :show, :jobs ]

  def index
    companies = Company.includes(:jobs)
                      .joins(:jobs)
                      .where(jobs: { status: JobStatus::OPEN })
                      .select("companies.*, COUNT(jobs.id) as jobs_count")
                      .group("companies.id")
                      .order("jobs_count DESC")
                      .limit(params[:limit] || 50)

    render_json_success(
      companies.map { |company| serialize_company_summary(company) },
      message: "Found #{companies.count} companies with active job listings"
    )
  end

  def show
    render_json_success(serialize_company_detailed(@company))
  end

  def jobs
    jobs_query = @company.jobs.published.includes(:company, :tags)

    # Apply filters
    jobs_query = apply_job_filters(jobs_query)

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = [ (params[:per_page] || 20).to_i, 100 ].min # Max 100 per page

    total_count = jobs_query.count
    jobs = jobs_query.offset((page - 1) * per_page).limit(per_page)

    render_json_success({
      jobs: jobs.map { |job| serialize_job(job) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      },
      company: serialize_company_summary(@company)
    })
  end

  private

  def set_company
    # Support both ID and slug lookup
    @company = if params[:id].match?(/\A\d+\z/)
                 Company.find(params[:id])
    else
                 Company.find_by!(slug: params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_json_error("Company not found", status: :not_found)
  end

  def apply_job_filters(jobs_query)
    # Employment type filter
    if params[:employment_type].present?
      jobs_query = jobs_query.where(employment_type: params[:employment_type])
    end

    # Location filter
    if params[:location].present?
      jobs_query = jobs_query.where("location ILIKE ?", "%#{params[:location]}%")
    end

    # Remote filter
    if params[:remote] == "true"
      jobs_query = jobs_query.remote_friendly
    end

    # Salary filter
    if params[:salary_min].present?
      jobs_query = jobs_query.where("salary_min >= ? OR salary_max >= ?",
                                   params[:salary_min], params[:salary_min])
    end

    # Date filter
    if params[:posted_after].present?
      begin
        date = Date.parse(params[:posted_after])
        jobs_query = jobs_query.where("posted_at >= ? OR created_at >= ?", date, date)
      rescue ArgumentError
        # Invalid date format, ignore filter
      end
    end

    # Search query
    if params[:q].present?
      jobs_query = jobs_query.search_jobs(params[:q])
    end

    jobs_query
  end

  def serialize_company_summary(company)
    {
      id: company.id,
      name: company.name,
      slug: company.slug,
      industry: company.industry,
      location: company.location,
      website: company.website,
      logo_url: company.logo_url,
      jobs_count: company.try(:jobs_count) || company.jobs.published.count,
      created_at: company.created_at&.iso8601,
      updated_at: company.updated_at&.iso8601
    }
  end

  def serialize_company_detailed(company)
    base_data = serialize_company_summary(company)

    base_data.merge({
      status: company.status,
      total_jobs_posted: company.jobs.count,
      active_jobs_count: company.jobs.published.count,
      remote_jobs_count: company.jobs.published.remote_friendly.count,
      recent_jobs_count: company.jobs.where("created_at > ?", 30.days.ago).count
    })
  end

  def serialize_job(job)
    {
      id: job.id,
      title: job.title,
      description: job.description,
      location: job.location,
      employment_type: job.employment_type,
      status: job.status,
      salary_min: job.salary_min,
      salary_max: job.salary_max,
      currency: job.currency,
      apply_url: job.apply_url,
      source: job.source,
      posted_at: (job.posted_at || job.created_at)&.iso8601,
      created_at: job.created_at&.iso8601,
      updated_at: job.updated_at&.iso8601,
      company: {
        id: job.company.id,
        name: job.company.name,
        slug: job.company.slug,
        industry: job.company.industry,
        location: job.company.location,
        logo_url: job.company.logo_url
      },
      tags: job.tags.map { |tag| { id: tag.id, name: tag.name } },
      view_url: Rails.application.routes.url_helpers.job_url(job, host: request.host_with_port)
    }
  end
end
