# frozen_string_literal: true

module Jobs
  class BrowsingService
    include JobFetchingConfig

    def get_filtered_jobs(filters: {})
      jobs = apply_filters(base_jobs_query, filters)
      jobs.order(created_at: :desc)
    end

    def list_jobs(page: 1, per_page: 20, filters: {})
      jobs = get_filtered_jobs(filters: filters)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def search_jobs(query:, location: nil, page: 1, per_page: 20, filters: {})
      jobs = base_jobs_query

      if query.present?
        jobs = jobs.search(query)
      end

      if location.present?
        jobs = jobs.where("location ILIKE ?", "%#{location}%")
      end

      jobs = apply_filters(jobs, filters)
      jobs = jobs.order(created_at: :desc)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def filter_jobs(filters:, page: 1, per_page: 20)
      jobs = apply_filters(base_jobs_query, filters)
      jobs = jobs.order(created_at: :desc)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def related_jobs(job, limit: 6)
      # Find jobs with similar tags or from same company
      related = Job.published
                   .includes(:company, :tags)
                   .where.not(id: job.id)
                   .joins(:tags)
                   .where(tags: { id: job.tag_ids })
                   .or(Job.published.where(company: job.company))
                   .distinct
                   .limit(limit)

      # If not enough related jobs, fill with recent jobs
      if related.size < limit
        additional_jobs = Job.published
                             .includes(:company, :tags)
                             .where.not(id: [ job.id ] + related.pluck(:id))
                             .order(created_at: :desc)
                             .limit(limit - related.size)
        related = (related + additional_jobs).uniq
      end

      related
    end

    def search_metadata(query, location)
      {
        query: query,
        location: location,
        total_results: search_jobs(query: query, location: location, per_page: 1).last.count,
        suggested_locations: suggested_locations(location),
        suggested_skills: suggested_skills(query)
      }
    end

    def track_job_view(job)
      # Could implement analytics tracking here
      Rails.logger.info "Job viewed: #{job.id} - #{job.title} at #{job.company.name}"
    end

    private

    def base_jobs_query
      Job.published
         .includes(:company, :tags, :job_metadatum)
         .joins(:company)
    end

    def apply_filters(jobs, filters)
      return jobs if filters.blank?

      jobs = jobs.where(employment_type: filters[:employment_type]) if filters[:employment_type]
      jobs = jobs.where(company_id: filters[:company_id]) if filters[:company_id]
      jobs = jobs.where(source: filters[:source]) if filters[:source]

      if filters[:salary_min]
        jobs = jobs.where("salary_min >= ? OR salary_max >= ?", filters[:salary_min], filters[:salary_min])
      end

      if filters[:salary_max]
        jobs = jobs.where("salary_max <= ? OR salary_min <= ?", filters[:salary_max], filters[:salary_max])
      end

      if filters[:location]
        jobs = jobs.where("location ILIKE ?", "%#{filters[:location]}%")
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

    def paginate_results(jobs, page:, per_page:)
      pagy = Pagy.new(count: jobs.count, page: page, limit: per_page)
      jobs = jobs.offset(pagy.offset).limit(pagy.limit)

      [ pagy, jobs ]
    end

    def suggested_locations(location)
      return [] unless location.present?

      Job.published
         .where("location ILIKE ?", "%#{location}%")
         .group(:location)
         .order(Arel.sql("COUNT(*) DESC"))
         .limit(5)
         .pluck(:location)
         .compact
    end

    def suggested_skills(query)
      return [] unless query.present?

      Tag.joins(:jobs)
         .where("tags.name ILIKE ?", "%#{query}%")
         .where(jobs: { status: JobStatus::OPEN })
         .group(:name)
         .order(Arel.sql("COUNT(jobs.id) DESC"))
         .limit(5)
         .pluck(:name)
    end
  end
end
