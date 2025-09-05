# frozen_string_literal: true

# Enhanced service for fetching jobs from multiple APIs using tag-based strategies
class TagBasedJobFetcherService
  include JobFetchingConfig
  include ActiveModel::Model
  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations

  attr_accessor :sources, :tag_strategy, :location, :jobs_per_tag, :max_tags, :total_job_limit

  validates :tag_strategy, inclusion: { in: VALID_STRATEGIES.map(&:to_s) }
  validates :jobs_per_tag, :max_tags, :total_job_limit,
            numericality: { greater_than: 0 }

  def initialize(attributes = {})
    # Set defaults
    @sources = API_SERVICES
    @tag_strategy = :balanced
    @location = nil
    @jobs_per_tag = DEFAULT_CONFIG[:jobs_per_tag]
    @max_tags = DEFAULT_CONFIG[:max_tags]
    @total_job_limit = DEFAULT_CONFIG[:total_job_limit]

    # Assign provided attributes
    assign_attributes(attributes)

    # Validate and process
    @sources = Array(@sources).map(&:to_sym) & API_SERVICES.map(&:to_sym)
    @tag_strategy = @tag_strategy.to_s
    @results = initialize_results

    validate!
    ensure_seed_data
  end

  def fetch_jobs_by_tags
    log_fetch_start

    keywords = fetch_keywords_from_tags
    return build_result if keywords.empty?

    fetch_jobs_for_keywords(keywords)
    process_and_save_jobs
    track_analytics
    build_result
  end

  def execute_with_strategy(strategy = @tag_strategy)
    @tag_strategy = strategy.to_sym
    validate!
    fetch_jobs_by_tags
  end

  private

  def initialize_results
    { jobs: [], stats: {}, errors: [], tags_used: [] }
  end

  def log_fetch_start
    Rails.logger.info "Starting tag-based job fetch with strategy: #{@tag_strategy}"
  end

  def fetch_keywords_from_tags
    keywords = get_keywords_from_tags
    Rails.logger.info "Using #{keywords.length} keywords from tags: #{keywords.first(10).join(', ')}"
    keywords
  end

  def fetch_jobs_for_keywords(keywords)
    keywords.each do |keyword|
      break if job_limit_reached?

      fetch_jobs_for_keyword(keyword)
    end
  end

  def job_limit_reached?
    @results[:jobs].length >= @total_job_limit
  end

  def fetch_jobs_for_keyword(keyword)
    @sources.each do |source|
      break if job_limit_reached?

      jobs = fetch_from_source_with_keyword(source, keyword)
      add_jobs_to_results(jobs, keyword)
    end
  end

  def add_jobs_to_results(jobs, keyword)
    tagged_jobs = jobs.map do |job|
      job.merge(
        search_tag: keyword,
        api_source: @sources.first.to_s, # Current source being processed
        fetched_at: Time.current
      )
    end
    @results[:jobs].concat(tagged_jobs)
    @results[:tags_used] << keyword unless @results[:tags_used].include?(keyword)
  end

  def get_keywords_from_tags
    Tag.get_fetching_keywords(strategy: @tag_strategy, limit: @max_tags)
  end

  def fetch_from_source_with_keyword(source, keyword)
    return [] unless API_SERVICES.include?(source.to_s)

    # Handle special case for remoteok service naming
    service_class_name = case source.to_s
    when "remoteok"
                           "Api::RemoteOkService"
    else
                           "Api::#{source.to_s.camelize}Service"
    end

    service_class = service_class_name.constantize
    service = service_class.new(keyword, @location, @jobs_per_tag)
    jobs = service.fetch_jobs

    Rails.logger.info "#{source}: fetched #{jobs.length} jobs for tag '#{keyword}'"
    jobs
  rescue StandardError => e
    Rails.logger.error "Error fetching from #{source} with keyword '#{keyword}': #{e.message}"
    @results[:errors] << { source: source, keyword: keyword, error: e.message }
    []
  end

  def process_and_save_jobs
    return if @results[:jobs].empty?

    Rails.logger.info "Processing #{@results[:jobs].length} jobs for database storage"
    process_jobs_in_batches
  end

  def process_jobs_in_batches
    # Remove duplicates
    unique_jobs = @results[:jobs].uniq { |job| [ job[:external_id], job[:api_source] ] }
    Rails.logger.info "After deduplication: #{unique_jobs.length} unique jobs"

    # Process jobs in batches by source
    unique_jobs.group_by { |job| job[:api_source] }.each do |source, jobs|
      process_source_jobs(source, jobs)
    end
  end

  def process_source_jobs(source, jobs)
    processor = Api::JobProcessorService.new(jobs, source)
    stats = processor.process
    @results[:stats][source] = stats
    Rails.logger.info "#{source}: Created #{stats[:created]}, Updated #{stats[:updated]}, Skipped #{stats[:skipped]}"
  rescue StandardError => e
    Rails.logger.error "Error processing jobs from #{source}: #{e.message}"
    @results[:errors] << { source: source, error: e.message }
  end

  def track_analytics
    return unless defined?(TagBasedAnalyticsService)

    TagBasedAnalyticsService.track_fetch(
      strategy: @tag_strategy,
      tags_used: @results[:tags_used],
      jobs_found: @results[:jobs].length,
      api_results: transform_stats_for_analytics
    )
  end

  def transform_stats_for_analytics
    @results[:stats].transform_values do |stats|
      {
        found: @results[:jobs].length,
        created: stats[:created] || 0,
        updated: stats[:updated] || 0
      }
    end
  end

  def build_result
    {
      success: @results[:errors].empty?,
      strategy_used: @tag_strategy,
      total_jobs_fetched: @results[:jobs].length,
      total_jobs_processed: calculate_processed_jobs,
      new_jobs_created: calculate_created_jobs,
      tags_attempted: @results[:tags_used].length,
      api_sources_used: @sources.length,
      errors: @results[:errors],
      timestamp: Time.current
    }
  end

  def calculate_processed_jobs
    @results[:stats].values.sum { |stats| stats[:created].to_i + stats[:updated].to_i }
  end

  def calculate_created_jobs
    @results[:stats].values.sum { |stats| stats[:created].to_i }
  end

  # Industry-specific methods
  def fetch_by_industry_tags(industry_pattern)
    industry_tags = Tag.where("LOWER(name) SIMILAR TO ?", "%#{industry_pattern.downcase}%")
                      .limit(@max_tags)
                      .pluck(:name)
    fetch_with_custom_keywords(industry_tags)
  end

  def fetch_for_underrepresented_tags(min_job_count: 2)
    underrepresented_tags = Tag.left_joins(:jobs)
                              .group("tags.id")
                              .having("COUNT(jobs.id) < ?", min_job_count)
                              .limit(@max_tags)
                              .pluck(:name)
    Rails.logger.info "Found #{underrepresented_tags.length} underrepresented tags"
    fetch_with_custom_keywords(underrepresented_tags)
  end

  def fetch_for_popular_tags(min_job_count: 10)
    popular_tags = Tag.joins(:jobs)
                     .group("tags.id")
                     .having("COUNT(jobs.id) >= ?", min_job_count)
                     .order(Arel.sql("COUNT(jobs.id) DESC"))
                     .limit(@max_tags)
                     .pluck(:name)
    Rails.logger.info "Found #{popular_tags.length} popular tags"
    fetch_with_custom_keywords(popular_tags)
  end

  def ensure_seed_data
    return if Tag.count >= 20

    Rails.logger.info "Creating seed tag data for job fetching"
    Tag.create_industry_seed_data
  end

  def fetch_with_custom_keywords(keywords)
    @results = initialize_results
    fetch_jobs_for_keywords(keywords)
    process_and_save_jobs
    track_analytics
    build_result
  end
end
