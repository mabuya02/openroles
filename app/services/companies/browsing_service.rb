# frozen_string_literal: true

module Companies
  class BrowsingService
    include JobFetchingConfig

    def get_filtered_companies(filters: {})
      companies = apply_filters(base_companies_query, filters)
      companies.order(:name)
    end

    def list_companies(page: 1, per_page: 24, filters: {})
      companies = get_filtered_companies(filters: filters)

      paginate_results(companies, page: page, per_page: per_page)
    end

    def search_companies(query:, location: nil, page: 1, per_page: 24, filters: {})
      companies = base_companies_query

      if query.present?
        companies = companies.where("name ILIKE ? OR industry ILIKE ?", "%#{query}%", "%#{query}%")
      end

      if location.present?
        companies = companies.where("location ILIKE ?", "%#{location}%")
      end

      companies = apply_filters(companies, filters)
      companies = companies.order(:name)

      paginate_results(companies, page: page, per_page: per_page)
    end

    def company_jobs(company, page: 1, per_page: 10, filters: {})
      jobs = company.jobs.published.includes(:tags, :job_metadatum)
      jobs = apply_job_filters(jobs, filters) if filters.present?
      jobs = jobs.order(created_at: :desc)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def company_statistics(company)
      jobs = company.jobs.published

      {
        total_jobs: jobs.count,
        recent_jobs: jobs.where("created_at >= ?", 1.month.ago).count,
        employment_types: jobs.group(:employment_type).count,
        average_salary: calculate_average_salary(jobs),
        top_skills: top_skills_for_company(company),
        job_locations: jobs.group(:location).count.sort_by(&:last).reverse.first(5).to_h
      }
    end

    def similar_companies(company, limit: 6)
      # Find companies in same industry or location
      Company.where.not(id: company.id)
             .where(industry: company.industry)
             .or(Company.where(location: company.location))
             .joins(:jobs)
             .where(jobs: { status: JobStatus::OPEN })
             .group("companies.id")
             .order(Arel.sql("COUNT(jobs.id) DESC"))
             .limit(limit)
    end

    def featured_industries
      Company.joins(:jobs)
             .where(jobs: { status: JobStatus::OPEN })
             .group(:industry)
             .order(Arel.sql("COUNT(jobs.id) DESC"))
             .limit(8)
             .pluck(:industry)
             .compact
    end

    def search_metadata(query, location)
      {
        query: query,
        location: location,
        total_results: search_companies(query: query, location: location, per_page: 1).last.count,
        suggested_industries: suggested_industries(query),
        suggested_locations: suggested_locations(location)
      }
    end

    def track_company_view(company)
      Rails.logger.info "Company viewed: #{company.id} - #{company.name}"
    end

    private

    def base_companies_query
      Company.joins(:jobs)
             .where(jobs: { status: JobStatus::OPEN })
             .distinct
    end

    def apply_filters(companies, filters)
      return companies if filters.blank?

      companies = companies.where(industry: filters[:industry]) if filters[:industry]
      companies = companies.where("location ILIKE ?", "%#{filters[:location]}%") if filters[:location]

      if filters[:size].present?
        case filters[:size]
        when "startup"
          companies = companies.where("companies.size <= ?", 50)
        when "small"
          companies = companies.where("companies.size BETWEEN ? AND ?", 51, 200)
        when "medium"
          companies = companies.where("companies.size BETWEEN ? AND ?", 201, 1000)
        when "large"
          companies = companies.where("companies.size > ?", 1000)
        end
      end

      if filters[:verified] == "true"
        companies = companies.where(verified: true)
      end

      if filters[:has_jobs] == "true"
        companies = companies.having("COUNT(jobs.id) > 0")
      end

      companies
    end

    def apply_job_filters(jobs, filters)
      jobs = jobs.where(employment_type: filters[:employment_type]) if filters[:employment_type]
      jobs = jobs.where("location ILIKE ?", "%#{filters[:location]}%") if filters[:location]

      if filters[:salary_min]
        jobs = jobs.where("salary_min >= ? OR salary_max >= ?", filters[:salary_min], filters[:salary_min])
      end

      if filters[:posted_after]
        jobs = jobs.posted_after(Date.parse(filters[:posted_after]))
      end

      if filters[:has_salary] == "true"
        jobs = jobs.with_salary
      end

      if filters[:tag_ids].present?
        jobs = jobs.joins(:tags).where(tags: { id: filters[:tag_ids] }).distinct
      end

      jobs
    end

    def paginate_results(records, page:, per_page:)
      pagy = Pagy.new(count: records.count, page: page, limit: per_page)
      records = records.offset(pagy.offset).limit(pagy.limit)

      [ pagy, records ]
    end

    def calculate_average_salary(jobs)
      salaries = jobs.where.not(salary_min: nil).or(jobs.where.not(salary_max: nil))
      return nil if salaries.empty?

      total = salaries.sum do |job|
        if job.salary_min && job.salary_max
          (job.salary_min + job.salary_max) / 2
        elsif job.salary_min
          job.salary_min
        else
          job.salary_max
        end
      end

      (total / salaries.count).round
    end

    def top_skills_for_company(company)
      Tag.joins(jobs: :company)
         .where(companies: { id: company.id })
         .where(jobs: { status: JobStatus::OPEN })
         .group(:name)
         .order(Arel.sql("COUNT(jobs.id) DESC"))
         .limit(10)
         .pluck(:name)
    end

    def suggested_industries(query)
      return [] unless query.present?

      Company.where("industry ILIKE ?", "%#{query}%")
             .group(:industry)
             .order(Arel.sql("COUNT(*) DESC"))
             .limit(5)
             .pluck(:industry)
             .compact
    end

    def suggested_locations(location)
      return [] unless location.present?

      Company.where("location ILIKE ?", "%#{location}%")
             .group(:location)
             .order(Arel.sql("COUNT(*) DESC"))
             .limit(5)
             .pluck(:location)
             .compact
    end
  end
end
