class NaturalLanguageSearchService
  attr_reader :query, :parsed_data

  def initialize(query)
    @query = query.downcase.strip
    @parsed_data = {}
  end

  def parse_and_search
    parse_query

    # Start with local jobs
    local_jobs = search_local_jobs

    # Add external jobs if needed
    if should_search_external?
      search_external_jobs
      # Re-run local search to include any newly created external jobs
      local_jobs = search_local_jobs
    end

    local_jobs
  end

  def parse_query_only
    parse_query
    self
  end

  private

  def parse_query
    # Extract company name
    if match = @query.match(/at\s+([a-zA-Z0-9\s]+)(?:\s|$)/)
      @parsed_data[:company] = match[1].strip
      @query = @query.gsub(match[0], " ").strip
    end

    # Extract location/remote preferences
    if @query.include?("remote")
      @parsed_data[:remote] = true
      @query = @query.gsub("remote", " ").strip
    end

    # Extract job type keywords
    job_types = %w[full-time part-time contract freelance intern]
    job_types.each do |type|
      if @query.include?(type.gsub("-", " ")) || @query.include?(type)
        @parsed_data[:employment_type] = type.gsub("-", "_")
        @query = @query.gsub(type.gsub("-", " "), " ").gsub(type, " ").strip
      end
    end

    # Extract industry keywords
    industries = [ "tech companies", "technology", "fintech", "healthcare", "education", "marketing" ]
    industries.each do |industry|
      if @query.include?(industry)
        @parsed_data[:industry] = industry.gsub(" companies", "")
        @query = @query.gsub(industry, " ").strip
      end
    end

    # Clean up remaining query for job title/skills
    @parsed_data[:job_title_keywords] = @query.split.reject(&:blank?)
  end

  def search_local_jobs
    jobs = Job.published.includes(:company)

    # Handle company and industry filters separately to avoid conflicts
    # with pg_search joins that create table aliases
    if @parsed_data[:company].present? || @parsed_data[:industry].present?
      company_jobs = Job.published.joins(:company)

      if @parsed_data[:company].present?
        company_jobs = company_jobs.where("companies.name ILIKE ?", "%#{@parsed_data[:company]}%")
      end

      if @parsed_data[:industry].present?
        company_jobs = company_jobs.where("companies.industry ILIKE ?", "%#{@parsed_data[:industry]}%")
      end

      # Get the job IDs and then apply to the main query
      job_ids = company_jobs.pluck(:id)
      jobs = jobs.where(id: job_ids) if job_ids.any?
    end

    # Apply employment type filter
    if @parsed_data[:employment_type].present?
      jobs = jobs.where(employment_type: @parsed_data[:employment_type])
    end

    # Apply remote filter
    if @parsed_data[:remote]
      jobs = jobs.remote_friendly
    end

    # Apply text search on job title/description
    if @parsed_data[:job_title_keywords].any?
      search_terms = @parsed_data[:job_title_keywords].join(" ")
      jobs = jobs.search_jobs(search_terms)
    end

    jobs.limit(50)
  end

  def search_external_jobs
    # If we have specific company or few local results, try external APIs
    return Job.none unless should_search_external?

    external_jobs = []

    # Search RemoteOK API for jobs (especially for remote jobs)
    external_jobs += search_remoteok_api

    # Search Jooble API for more comprehensive job search
    external_jobs += search_jooble_api if ENV["JOOBLE_API_KEY"].present?

    # Process and save external jobs
    process_external_jobs(external_jobs)
  end

  def should_search_external?
    # Search external APIs if:
    # 1. We have a specific company mentioned
    # 2. We have remote preference
    # 3. Local results are limited
    @parsed_data[:company].present? || @parsed_data[:remote] || search_local_jobs.count < 5
  end

  def search_jooble_api
    return [] unless ENV["JOOBLE_API_KEY"].present?

    begin
      service = Api::JoobleService.new(
        keywords: @parsed_data[:job_title_keywords].join(" "),
        location: @parsed_data[:company] || "",
        limit: 10
      )

      jooble_jobs = service.fetch_jobs
      return [] if jooble_jobs.empty?

      jooble_jobs.map do |job_data|
        transform_jooble_job(job_data)
      end
    rescue => e
      Rails.logger.error "Jooble API error: #{e.message}"
      []
    end
  end

  def search_remoteok_api
    begin
      service = Api::RemoteOkService.new(
        keywords: @parsed_data[:job_title_keywords].join(" "),
        location: "",
        limit: 10
      )

      remoteok_jobs = service.fetch_jobs
      return [] if remoteok_jobs.empty?

      # Filter jobs based on our search terms
      relevant_jobs = remoteok_jobs.select do |job_data|
        job_text = "#{job_data['title']} #{job_data['description']}"
        @parsed_data[:job_title_keywords].any? do |keyword|
          job_text.downcase.include?(keyword.downcase)
        end
      end

      relevant_jobs.first(10).map do |job_data|
        transform_remoteok_job(job_data)
      end
    rescue => e
      Rails.logger.error "RemoteOK API error: #{e.message}"
      []
    end
  end

  def transform_themuse_job(job_data)
    {
      title: job_data["name"],
      description: job_data["contents"],
      company_name: job_data.dig("company", "name"),
      company_website: job_data.dig("company", "website"),
      location: job_data.dig("locations", 0, "name") || "Remote",
      employment_type: "full_time",
      apply_url: job_data["refs"]["landing_page"],
      source: "themuse",
      external_id: job_data["id"].to_s,
      posted_at: job_data["publication_date"],
      salary_min: nil,
      salary_max: nil,
      currency: "USD",
      industry: job_data.dig("company", "industries", 0, "name")
    }
  end

  def transform_jooble_job(job_data)
    {
      title: job_data["title"],
      description: job_data["snippet"] || job_data["title"],
      company_name: job_data["company"],
      company_website: nil,
      location: job_data["location"] || "Not specified",
      employment_type: extract_employment_type_from_jooble(job_data),
      apply_url: job_data["link"],
      source: "jooble",
      external_id: job_data["id"]&.to_s || Digest::MD5.hexdigest("#{job_data['title']}-#{job_data['company']}-#{Time.current.to_i}"),
      posted_at: parse_jooble_date(job_data["updated"]) || Time.current,
      salary_min: extract_salary_from_jooble(job_data, :min),
      salary_max: extract_salary_from_jooble(job_data, :max),
      currency: "USD",
      industry: nil
    }
  end

  def transform_remoteok_job(job_data)
    {
      title: job_data["title"] || job_data["position"],
      description: job_data["description"],
      company_name: job_data["company"],
      company_website: job_data["company_logo"] ? "https://#{job_data['company'].downcase.gsub(' ', '')}.com" : nil,
      location: "Remote",
      employment_type: "full_time",
      apply_url: job_data["apply_url"] || job_data["url"],
      source: "remoteok",
      external_id: job_data["id"]&.to_s || Digest::MD5.hexdigest("#{job_data['title']}-#{job_data['company']}-#{Time.current.to_i}"),
      posted_at: parse_remoteok_date(job_data["date"]) || Time.current,
      salary_min: job_data["salary_min"],
      salary_max: job_data["salary_max"],
      currency: "USD",
      industry: job_data["tags"]&.first
    }
  end

  private

  def extract_employment_type_from_jooble(job_data)
    title = job_data["title"]&.downcase || ""
    snippet = job_data["snippet"]&.downcase || ""

    return "part_time" if title.include?("part time") || snippet.include?("part time")
    return "contract" if title.include?("contract") || snippet.include?("contract")
    return "internship" if title.include?("intern") || snippet.include?("intern")

    "full_time"
  end

  def extract_salary_from_jooble(job_data, type = :min)
    snippet = job_data["snippet"]
    return nil unless snippet

    # Look for salary patterns
    salary_match = snippet.match(/[\$£€](\d+(?:,\d{3})*(?:k)?)/i)
    return nil unless salary_match

    salary_str = salary_match[1].gsub(",", "")
    salary = salary_str.include?("k") ? salary_str.to_i * 1000 : salary_str.to_i

    type == :min ? salary : nil
  end

  def parse_jooble_date(date_str)
    return Time.current unless date_str
    Time.parse(date_str) rescue Time.current
  end

  def parse_remoteok_date(date_value)
    return Time.current unless date_value

    case date_value
    when Numeric
      Time.at(date_value)
    when String
      Time.parse(date_value)
    else
      Time.current
    end
  rescue
    Time.current
  end

  def process_external_jobs(external_jobs_data)
    saved_jobs = []

    external_jobs_data.each do |job_data|
      begin
        # Find or create company first
        company = find_or_create_company(job_data)
        next unless company

        # Check if job already exists
        existing_job = Job.find_by(
          source: job_data[:source],
          external_id: job_data[:external_id]
        )

        if existing_job
          saved_jobs << existing_job
          next
        end

        # Create new job
        job = company.jobs.build(
          title: job_data[:title],
          description: job_data[:description],
          location: job_data[:location],
          employment_type: job_data[:employment_type],
          apply_url: job_data[:apply_url],
          source: job_data[:source],
          external_id: job_data[:external_id],
          posted_at: job_data[:posted_at],
          salary_min: job_data[:salary_min],
          salary_max: job_data[:salary_max],
          currency: job_data[:currency],
          status: JobStatus::OPEN
        )

        if job.save
          # Generate metadata automatically
          generate_job_metadata(job)
          saved_jobs << job

          Rails.logger.info "Saved external job: #{job.title} at #{company.name}"
        else
          Rails.logger.error "Failed to save job: #{job.errors.full_messages}"
        end

      rescue => e
        Rails.logger.error "Error processing external job: #{e.message}"
        next
      end
    end

    Job.where(id: saved_jobs.map(&:id))
  end

  def find_or_create_company(job_data)
    company_name = job_data[:company_name]&.strip
    return nil if company_name.blank?

    # Try to find existing company
    company = Company.find_by("name ILIKE ?", company_name)
    return company if company

    # Create new company
    Company.create!(
      name: company_name,
      website: job_data[:company_website],
      industry: job_data[:industry],
      status: "active",
      slug: generate_company_slug(company_name)
    )
  rescue => e
    Rails.logger.error "Error creating company #{company_name}: #{e.message}"
    nil
  end

  def generate_company_slug(name)
    base_slug = name.downcase.gsub(/[^a-z0-9\s]/, "").gsub(/\s+/, "-")
    candidate_slug = base_slug
    counter = 1

    while Company.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate_slug
  end

  def generate_job_metadata(job)
    job.create_job_metadatum!(
      meta_title: "#{job.title} at #{job.company.name}",
      meta_description: job.description&.truncate(155) || "Job opportunity at #{job.company.name}",
      og_title: "#{job.title} - #{job.company.name}",
      og_description: job.description&.truncate(200) || "Join #{job.company.name} as a #{job.title}",
      og_image: job.company.logo_url,
      twitter_card_type: TwitterCardType::SUMMARY,
      canonical_url: Rails.application.routes.url_helpers.job_url(job, host: Rails.application.config.default_host || "localhost:3000")
    )
  rescue => e
    Rails.logger.error "Error generating metadata for job #{job.id}: #{e.message}"
  end
end
