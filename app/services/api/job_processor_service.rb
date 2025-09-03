# frozen_string_literal: true

module Api
  # Process and save job data from external APIs
  class JobProcessorService
    def initialize(jobs_data, source)
      @jobs_data = Array(jobs_data)
      @source = source
      @stats = { created: 0, updated: 0, skipped: 0 }
    end

    def process
      @jobs_data.each { |job_data| process_job(job_data) }
      @stats
    end

    private

    def process_job(job_data)
      return skip_job("Invalid job data") unless valid_job_data?(job_data)

      # Step 1: Find or create company first (as per your logic)
      company = find_or_create_company(job_data[:company])
      return skip_job("Could not create/find company") unless company

      # Step 2: Check if this is a new job or existing job
      existing_job = find_existing_job(job_data, company)

      if existing_job
        # Update existing job
        job = update_job(existing_job, job_data, company)
        @stats[:updated] += 1
        Rails.logger.info "Updated job: #{job.title}" if Rails.env.development?
      else
        # Create new job for this company
        job = create_job(job_data, company)
        @stats[:created] += 1
        Rails.logger.info "Created new job: #{job.title}" if Rails.env.development?
      end

      return skip_job("Could not save job") unless job&.persisted?

      # Step 3: Add metadata and tags
      create_job_metadata(job, job_data)
      create_job_tags(job, job_data[:tags])

    rescue StandardError => e
      Rails.logger.error "Error processing job: #{e.message}"
      Rails.logger.error "Job data: #{job_data.inspect}" if Rails.env.development?
      skip_job("Processing error: #{e.message}")
    end

    def update_company_data(company, new_data)
      # Only update fields that are currently blank or if we have better data
      update_fields = {}

      update_fields[:website] = new_data[:website] if new_data[:website] && company.website.blank?
      # Note: Company model doesn't have description field - skipping description update
      update_fields[:location] = new_data[:location] if new_data[:location] && company.location.blank?
      update_fields[:industry] = new_data[:industry] if new_data[:industry] && company.industry.blank?
      # Note: Company model doesn't have company_size field - skipping company_size update
      update_fields[:logo_url] = new_data[:logo_url] if new_data[:logo_url] && company.logo_url.blank?

      company.update!(update_fields) if update_fields.any?
    end

    def normalize_website(url)
      return nil if url.blank?

      url = url.strip
      url = "https://#{url}" unless url.match?(/\Ahttps?:\/\//)
      url if URI::DEFAULT_PARSER.make_regexp.match?(url)
    end

    def normalize_company_size(size)
      return nil if size.blank?

      case size.to_s.downcase
      when /1-10|startup|small/
        "1-10"
      when /11-50|medium/
        "11-50"
      when /51-200|growing/
        "51-200"
      when /201-500|large/
        "201-500"
      when /500+|enterprise|big/
        "500+"
      else
        size.to_s.strip
      end
    end

    def find_or_create_company(company_data)
      # Handle both string and hash company data
      company_name = company_data.is_a?(Hash) ? company_data[:name] : company_data.to_s
      return nil if company_name.blank?

      # Enhanced company registration with additional data
      company_attrs = {
        name: company_name.strip,
        status: CompanyStatus::ACTIVE
      }

      # If we have additional company data from the API
      if company_data.is_a?(Hash)
        company_attrs.merge!(
          website: normalize_website(company_data[:website]),
          description: company_data[:description]&.strip,
          location: company_data[:location]&.strip,
          industry: company_data[:industry]&.strip,
          company_size: normalize_company_size(company_data[:size]),
          logo_url: company_data[:logo_url]
        ).compact!
      end

      # Find existing or create new company
      company = Company.find_by(name: company_attrs[:name])

      if company
        # Update existing company with new data if available
        update_company_data(company, company_attrs)
        Rails.logger.info "Updated existing company: #{company.name}" if Rails.env.development?
      else
        # Create new company
        company = Company.create!(company_attrs)
        Rails.logger.info "Registered new company: #{company.name}" if Rails.env.development?
      end

      company
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to register company '#{company_name}': #{e.message}"
      nil
    end

    def find_existing_job(job_data, company)
      # Try to find existing job by external_id first, then by fingerprint
      existing_job = Job.find_by(external_id: job_data[:external_id], source: @source) if job_data[:external_id].present?
      existing_job ||= Job.find_by(fingerprint: generate_fingerprint(job_data, company))

      Rails.logger.info "Found existing job: #{existing_job&.title}" if existing_job && Rails.env.development?
      existing_job
    end

    def find_or_create_job(job_data, company)
      # Try to find existing job by external_id first, then by fingerprint
      job = Job.find_by(external_id: job_data[:external_id], source: @source) if job_data[:external_id]
      job ||= Job.find_by(fingerprint: generate_fingerprint(job_data, company))

      if job
        update_job(job, job_data, company)
      else
        create_job(job_data, company)
      end
    end

    def create_job(job_data, company)
      Rails.logger.debug "Creating job: #{job_data[:title]} for company: #{company.name}" if Rails.env.development?

      job = Job.create!(
        title: job_data[:title],
        description: job_data[:description],
        location: job_data[:location],
        company: company,
        employment_type: normalize_employment_type(job_data[:employment_type]),
        salary_min: job_data[:salary_min],
        salary_max: job_data[:salary_max],
        apply_url: job_data[:apply_url],
        external_id: job_data[:external_id],
        source: @source,
        posted_at: parse_date(job_data[:posted_at]),
        status: JobStatus::OPEN,
        fingerprint: generate_fingerprint(job_data, company)
      )

      Rails.logger.debug "Successfully created job ID: #{job.id}" if Rails.env.development?
      job
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create job: #{e.message}"
      Rails.logger.error "Job data: #{job_data.inspect}" if Rails.env.development?
      nil
    end

    def update_job(job, job_data, company)
      job.update!(
        title: job_data[:title],
        description: job_data[:description],
        location: job_data[:location],
        company: company,
        employment_type: normalize_employment_type(job_data[:employment_type]),
        salary_min: job_data[:salary_min],
        salary_max: job_data[:salary_max],
        apply_url: job_data[:apply_url],
        posted_at: parse_date(job_data[:posted_at]) || job.posted_at
      )
      job
    end

    def create_job_metadata(job, job_data)
      return unless job_data[:metadata]

      job.job_metadatum&.destroy
      job.create_job_metadatum!(
        requirements: job_data[:metadata][:requirements],
        benefits: job_data[:metadata][:benefits],
        experience_level: job_data[:metadata][:experience_level],
        remote_policy: job_data[:metadata][:remote_policy],
        visa_sponsored: job_data[:metadata][:visa_sponsored]
      )
    end

    def create_job_tags(job, tags_data)
      return unless tags_data.present?

      job.job_tags.destroy_all

      Array(tags_data).each do |tag_name|
        next if tag_name.blank?

        tag = Tag.find_or_create_by(name: tag_name.strip.downcase) do |new_tag|
          new_tag.tag_type = "skill"
        end

        job.job_tags.create!(tag: tag)
      end
    end

    def valid_job_data?(job_data)
      is_valid = job_data[:title].present? &&
                 job_data[:description].present? &&
                 job_data[:company]&.is_a?(Hash) &&
                 job_data[:company][:name].present?

      unless is_valid
        missing_fields = []
        missing_fields << "title" unless job_data[:title].present?
        missing_fields << "description" unless job_data[:description].present?
        missing_fields << "company (Hash)" unless job_data[:company]&.is_a?(Hash)
        missing_fields << "company.name" unless job_data[:company]&.[](:name)&.present?

        Rails.logger.debug "Invalid job data - missing: #{missing_fields.join(', ')}" if Rails.env.development?
      end

      is_valid
    end

    def generate_fingerprint(job_data, company)
      return nil unless company

      content = [
        job_data[:title],
        company.name,
        job_data[:location],
        job_data[:description]
      ].compact.join("|")

      Digest::SHA256.hexdigest(content)
    end

    def normalize_employment_type(type)
      return EmploymentType::FULL_TIME if type.blank?

      normalized_type = case type.to_s.downcase.strip
      when /full.?time/, /permanent/, /regular/
        EmploymentType::FULL_TIME
      when /part.?time/
        EmploymentType::PART_TIME
      when /contract/, /freelance/, /contractor/
        EmploymentType::CONTRACT
      when /intern/
        EmploymentType::INTERNSHIP
      when /temporary/, /temp/
        EmploymentType::CONTRACT  # Map temporary to contract as fallback
      else
        Rails.logger.debug "Unknown employment type '#{type}', defaulting to FULL_TIME" if Rails.env.development?
        EmploymentType::FULL_TIME
      end

      Rails.logger.debug "Normalized employment type '#{type}' -> '#{normalized_type}'" if Rails.env.development?
      normalized_type
    end

    def parse_date(date_str)
      return nil if date_str.blank?
      return date_str if date_str.is_a?(Time) || date_str.is_a?(Date)

      Time.parse(date_str.to_s)
    rescue ArgumentError
      nil
    end

    def skip_job(reason = "Unknown reason")
      Rails.logger.debug "Skipping job: #{reason}" if Rails.env.development?
      @stats[:skipped] += 1
    end

    def extract_industry_from_description(description)
      return nil unless description.present?

      # Simple industry extraction based on keywords
      industries = {
        "technology" => [ "software", "tech", "programming", "developer", "engineer" ],
        "healthcare" => [ "health", "medical", "hospital", "clinic", "pharmaceutical" ],
        "finance" => [ "financial", "banking", "investment", "trading", "fintech" ],
        "education" => [ "education", "teaching", "university", "school", "learning" ],
        "marketing" => [ "marketing", "advertising", "brand", "social media" ],
        "design" => [ "design", "creative", "graphic", "ui", "ux" ],
        "consulting" => [ "consulting", "advisory", "professional services" ]
      }

      description_lower = description.downcase
      industries.each do |industry, keywords|
        return industry if keywords.any? { |keyword| description_lower.include?(keyword) }
      end

      "other"
    end
  end
end
