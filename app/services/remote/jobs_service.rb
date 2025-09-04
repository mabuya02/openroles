# frozen_string_literal: true

module Remote
  class JobsService
    include JobFetchingConfig

    def get_filtered_remote_jobs(filters: {})
      jobs = apply_filters(base_remote_jobs_query, filters)
      jobs.order("jobs.created_at": :desc)
    end

    def list_remote_jobs(page: 1, per_page: 20, filters: {})
      jobs = get_filtered_remote_jobs(filters: filters)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def search_remote_jobs(query:, skills: nil, page: 1, per_page: 20, filters: {})
      jobs = base_remote_jobs_query

      if query.present?
        jobs = jobs.search_jobs(query)
      end

      if skills.present?
        skill_tags = Tag.where("name ILIKE ANY (ARRAY[?])", skills.split(",").map { |s| "%#{s.strip}%" })
        jobs = jobs.joins(:tags).where(tags: { id: skill_tags.ids }).distinct if skill_tags.any?
      end

      jobs = apply_filters(jobs, filters)
      jobs = jobs.order("jobs.created_at": :desc)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def filter_remote_jobs(filters:, page: 1, per_page: 20)
      jobs = apply_filters(base_remote_jobs_query, filters)
      jobs = jobs.order("jobs.created_at": :desc)

      paginate_results(jobs, page: page, per_page: per_page)
    end

    def featured_remote_companies
      Company.joins(:jobs)
             .where(jobs: { status: JobStatus::OPEN })
             .where("jobs.location ILIKE ? OR jobs.location ILIKE ?", "%remote%", "%worldwide%")
             .group("companies.id")
             .order(Arel.sql("COUNT(jobs.id) DESC"))
             .limit(8)
    end

    def remote_job_trends
      # Get trending remote job categories
      remote_jobs = base_remote_jobs_query

      {
        top_skills: top_remote_skills,
        employment_types: remote_jobs.group(:employment_type).count,
        salary_ranges: calculate_salary_ranges(remote_jobs),
        growth_rate: calculate_growth_rate,
        popular_time_zones: extract_time_zones(remote_jobs)
      }
    end

    def search_metadata(query, skills)
      {
        query: query,
        skills: skills,
        total_results: search_remote_jobs(query: query, skills: skills, per_page: 1).last.count,
        suggested_skills: suggested_remote_skills(query),
        trending_remote_locations: trending_remote_locations
      }
    end

    private

    def base_remote_jobs_query
      Job.remote_friendly
         .published
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

      if filters[:posted_after]
        jobs = jobs.posted_after(Date.parse(filters[:posted_after]))
      end

      if filters[:has_salary] == "true"
        jobs = jobs.with_salary
      end

      if filters[:time_zone].present?
        jobs = jobs.where("description ILIKE ? OR raw_payload::text ILIKE ?",
                         "%#{filters[:time_zone]}%", "%#{filters[:time_zone]}%")
      end

      if filters[:experience_level].present?
        case filters[:experience_level]
        when "entry"
          jobs = jobs.where("title ILIKE ? OR description ILIKE ?", "%junior%", "%entry%")
        when "mid"
          jobs = jobs.where("title ILIKE ? OR description ILIKE ?", "%mid%", "%intermediate%")
        when "senior"
          jobs = jobs.where("title ILIKE ? OR description ILIKE ?", "%senior%", "%lead%")
        end
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

    def top_remote_skills
      Tag.joins(:jobs)
         .where(jobs: { status: JobStatus::OPEN })
         .where("jobs.location ILIKE ? OR jobs.location ILIKE ?", "%remote%", "%worldwide%")
         .group(:name)
         .order(Arel.sql("COUNT(jobs.id) DESC"))
         .limit(15)
         .pluck(:name)
    end

    def calculate_salary_ranges(jobs)
      jobs_with_salary = jobs.with_salary

      return {} if jobs_with_salary.empty?

      salaries = jobs_with_salary.map do |job|
        if job.salary_min && job.salary_max
          (job.salary_min + job.salary_max) / 2
        elsif job.salary_min
          job.salary_min
        else
          job.salary_max
        end
      end.compact

      {
        min: salaries.min&.round,
        max: salaries.max&.round,
        median: calculate_median(salaries)&.round,
        average: (salaries.sum / salaries.size).round
      }
    end

    def calculate_growth_rate
      # Calculate job growth over the last 3 months
      current_month = base_remote_jobs_query.where("jobs.created_at >= ?", 1.month.ago).count
      previous_month = base_remote_jobs_query.where("jobs.created_at BETWEEN ? AND ?", 2.months.ago, 1.month.ago).count

      return 0 if previous_month.zero?

      ((current_month - previous_month).to_f / previous_month * 100).round(1)
    end

    def extract_time_zones(jobs)
      # Extract common time zone mentions from job descriptions
      time_zone_patterns = %w[UTC EST PST GMT CET UTC+1 UTC-5 UTC-8 UTC+0]

      time_zone_counts = Hash.new(0)
      jobs.find_each do |job|
        description_text = "#{job.title} #{job.description}"
        time_zone_patterns.each do |tz|
          time_zone_counts[tz] += 1 if description_text.include?(tz)
        end
      end

      time_zone_counts.sort_by(&:last).reverse.first(5).to_h
    end

    def suggested_remote_skills(query)
      return [] unless query.present?

      Tag.joins(:jobs)
         .where("tags.name ILIKE ?", "%#{query}%")
         .where(jobs: { status: JobStatus::OPEN })
         .where("jobs.location ILIKE ? OR jobs.location ILIKE ?", "%remote%", "%worldwide%")
         .group(:name)
         .order(Arel.sql("COUNT(jobs.id) DESC"))
         .limit(8)
         .pluck(:name)
    end

    def trending_remote_locations
      Job.remote_friendly
         .published
         .where("jobs.created_at >= ?", 1.month.ago)
         .group("jobs.location")
         .order(Arel.sql("COUNT(*) DESC"))
         .limit(10)
         .pluck("jobs.location")
         .compact
    end

    def calculate_median(array)
      return nil if array.empty?

      sorted = array.sort
      mid = sorted.length / 2

      if sorted.length.odd?
        sorted[mid]
      else
        (sorted[mid - 1] + sorted[mid]) / 2.0
      end
    end
  end
end
