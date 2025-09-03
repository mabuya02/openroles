class Api::BaseJobFetcherService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :page, :integer, default: 1
  attribute :limit, :integer, default: 50
  attribute :keywords, :string
  attribute :location, :string
  attribute :country, :string, default: "us"

  class APIError < StandardError; end
  class RateLimitError < APIError; end
  class AuthenticationError < APIError; end

  def initialize(attributes = {})
    super
    @http_client = setup_http_client
  end

  def fetch_jobs
    raise NotImplementedError, "Subclasses must implement #fetch_jobs"
  end

  def process_and_save_jobs
    Rails.logger.info "Starting job fetch from #{api_name}"

    begin
      raw_jobs = fetch_jobs
      return { success: false, error: "No jobs returned" } if raw_jobs.blank?

      processed_jobs = process_jobs_batch(raw_jobs)
      saved_count = save_jobs_batch(processed_jobs)

      Rails.logger.info "#{api_name}: Processed #{processed_jobs.count}, Saved #{saved_count} jobs"

      {
        success: true,
        total_fetched: raw_jobs.count,
        total_processed: processed_jobs.count,
        total_saved: saved_count,
        api_source: api_name.downcase
      }
    rescue => e
      Rails.logger.error "#{api_name} API Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end
  end

  protected

  def api_name
    self.class.name.demodulize.gsub("Service", "").gsub("Fetcher", "")
  end

  def setup_http_client
    Faraday.new do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = 30
      f.options.open_timeout = 10
    end
  end

  def process_jobs_batch(raw_jobs)
    raw_jobs.filter_map do |job_data|
      normalized_job = normalize_job_data(job_data)
      next if normalized_job.blank? || invalid_job?(normalized_job)

      normalized_job
    end
  end

  def normalize_job_data(job_data)
    raise NotImplementedError, "Subclasses must implement #normalize_job_data"
  end

  def invalid_job?(job_data)
    job_data[:title].blank? ||
    job_data[:company_name].blank? ||
    job_data[:description].blank?
  end

  def save_jobs_batch(processed_jobs)
    saved_count = 0

    ActiveRecord::Base.transaction do
      processed_jobs.each do |job_data|
        if save_job(job_data)
          saved_count += 1
        end
      end
    end

    saved_count
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Batch save error: #{e.message}"
    0
  end

  def save_job(job_data)
    # Check for duplicates using fingerprint
    fingerprint = generate_fingerprint(job_data)
    existing_job = Job.find_by(fingerprint: fingerprint)

    if existing_job
      Rails.logger.debug "Skipping duplicate job: #{job_data[:title]} at #{job_data[:company_name]}"
      return false
    end

    company = find_or_create_company(job_data[:company_name], job_data[:company_website])
    return false unless company

    job = create_job(company, job_data, fingerprint)
    return false unless job

    # Create associated records
    create_job_metadata(job, job_data[:metadata]) if job_data[:metadata].present?
    create_job_tags(job, job_data[:tags]) if job_data[:tags].present?

    Rails.logger.debug "Saved job: #{job.title} at #{company.name}"
    true
  rescue => e
    Rails.logger.error "Error saving job #{job_data[:title]}: #{e.message}"
    false
  end

  private

  def generate_fingerprint(job_data)
    content = [
      job_data[:title],
      job_data[:company_name],
      job_data[:location],
      job_data[:description]&.truncate(100)
    ].compact.join("|")

    Digest::SHA256.hexdigest(content)
  end

  def find_or_create_company(company_name, website = nil)
    return nil if company_name.blank?

    # First try to find by name (case insensitive)
    company = Company.find_by("LOWER(name) = ?", company_name.downcase.strip)

    return company if company

    # Create new company
    Company.create!(
      name: company_name.strip,
      website: normalize_website(website),
      status: CompanyStatus::ACTIVE
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Error creating company #{company_name}: #{e.message}"
    nil
  end

  def create_job(company, job_data, fingerprint)
    Job.create!(
      company: company,
      title: job_data[:title],
      description: job_data[:description],
      location: job_data[:location],
      employment_type: normalize_employment_type(job_data[:employment_type]),
      salary_min: job_data[:salary_min],
      salary_max: job_data[:salary_max],
      salary_currency: job_data[:salary_currency] || "USD",
      apply_url: job_data[:apply_url],
      external_id: job_data[:external_id],
      source: api_name.downcase,
      fingerprint: fingerprint,
      posted_at: job_data[:posted_at] || Time.current,
      status: JobStatus::OPEN
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Error creating job: #{e.message}"
    nil
  end

  def create_job_metadata(job, metadata)
    return unless metadata.is_a?(Hash)

    JobMetadatum.create!(
      job: job,
      experience_level: metadata[:experience_level],
      remote_allowed: metadata[:remote_allowed] || false,
      visa_sponsorship: metadata[:visa_sponsorship] || false,
      benefits: metadata[:benefits],
      requirements: metadata[:requirements]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Error creating job metadata for job #{job.id}: #{e.message}"
  end

  def create_job_tags(job, tag_names)
    return unless tag_names.is_a?(Array)

    tag_names.each do |tag_name|
      next if tag_name.blank?

      tag = find_or_create_tag(tag_name.strip)
      next unless tag

      JobTag.find_or_create_by(job: job, tag: tag)
    end
  rescue => e
    Rails.logger.error "Error creating tags for job #{job.id}: #{e.message}"
  end

  def find_or_create_tag(tag_name)
    Tag.find_or_create_by(name: tag_name.downcase)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Error creating tag #{tag_name}: #{e.message}"
    nil
  end

  def normalize_website(url)
    return nil if url.blank?

    url = url.strip
    url = "https://#{url}" unless url.match?(/\Ahttps?:\/\//)
    url if url.match?(URI::DEFAULT_PARSER.make_regexp)
  end

  def normalize_employment_type(type)
    return EmploymentType::FULL_TIME if type.blank?

    case type.to_s.downcase
    when /full.?time/, /permanent/
      EmploymentType::FULL_TIME
    when /part.?time/
      EmploymentType::PART_TIME
    when /contract/, /freelance/
      EmploymentType::CONTRACT
    when /intern/
      EmploymentType::INTERNSHIP
    else
      EmploymentType::FULL_TIME
    end
  end

  def handle_api_error(response)
    case response.status
    when 401, 403
      raise AuthenticationError, "API authentication failed"
    when 429
      raise RateLimitError, "API rate limit exceeded"
    when 500..599
      raise APIError, "API server error: #{response.status}"
    else
      raise APIError, "API request failed: #{response.status}"
    end
  end
end
