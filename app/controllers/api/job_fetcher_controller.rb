module Api
  class JobFetcherController < ApplicationController
    before_action :authenticate_admin! 
    before_action :validate_sources, only: [ :fetch_from_sources ]

    # POST /api/job_fetcher/fetch_all
    def fetch_all
      keywords = params[:keywords]
      location = params[:location]
      limit = [ params[:limit].to_i, 100 ].min.positive? ? [ params[:limit].to_i, 100 ].min : 50
      sources = parse_sources

      job_fetcher = JobFetcherService.new(
        sources: sources,
        keywords: keywords,
        location: location,
        limit: limit
      )

      results = job_fetcher.fetch_all

      render json: {
        status: "success",
        message: "Job fetching completed",
        summary: generate_summary(results),
        details: results,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "Job fetching failed: #{e.message}"

      render json: {
        status: "error",
        message: "Job fetching failed",
        error: e.message,
        timestamp: Time.current
      }, status: :internal_server_error
    end

    # POST /api/job_fetcher/fetch_from_source
    def fetch_from_source
      source = params[:source]&.to_sym
      keywords = params[:keywords]
      location = params[:location]
      limit = [ params[:limit].to_i, 100 ].min.positive? ? [ params[:limit].to_i, 100 ].min : 50

      unless JobFetcherService::API_SERVICES.key?(source)
        return render json: {
          status: "error",
          message: "Invalid source",
          valid_sources: JobFetcherService::API_SERVICES.keys
        }, status: :bad_request
      end

      job_fetcher = JobFetcherService.new(
        sources: [ source ],
        keywords: keywords,
        location: location,
        limit: limit
      )

      result = job_fetcher.fetch_from_source(source)

      render json: {
        status: "success",
        message: "Jobs fetched from #{source}",
        data: result,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "Job fetching from #{source} failed: #{e.message}"

      render json: {
        status: "error",
        message: "Job fetching from #{source} failed",
        error: e.message,
        timestamp: Time.current
      }, status: :internal_server_error
    end

    # GET /api/job_fetcher/recent
    def recent
      hours_ago = [ params[:hours_ago].to_i, 168 ].min.positive? ? [ params[:hours_ago].to_i, 168 ].min : 24

      results = JobFetcherService.fetch_recent(hours_ago: hours_ago)

      render json: {
        status: "success",
        message: "Recent jobs fetched (#{hours_ago} hours ago)",
        summary: generate_summary(results),
        details: results,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "Recent job fetching failed: #{e.message}"

      render json: {
        status: "error",
        message: "Recent job fetching failed",
        error: e.message,
        timestamp: Time.current
      }, status: :internal_server_error
    end

    # GET /api/job_fetcher/status
    def status
      render json: {
        status: "success",
        available_sources: JobFetcherService::API_SERVICES.keys,
        api_health: check_api_health,
        last_sync: get_last_sync_info,
        timestamp: Time.current
      }
    end

    private

    def authenticate_admin!
      # Implement your admin authentication logic here
      # For now, we'll skip authentication - you should secure this in production
      # head :unauthorized unless current_user&.admin?
    end

    def parse_sources
      sources = params[:sources]

      case sources
      when String
        sources.split(",").map(&:strip).map(&:to_sym)
      when Array
        sources.map(&:to_sym)
      else
        JobFetcherService::API_SERVICES.keys
      end
    end

    def validate_sources
      invalid_sources = parse_sources - JobFetcherService::API_SERVICES.keys

      return if invalid_sources.empty?

      render json: {
        status: "error",
        message: "Invalid sources provided",
        invalid_sources: invalid_sources,
        valid_sources: JobFetcherService::API_SERVICES.keys
      }, status: :bad_request
    end

    def generate_summary(results)
      success_results = results[:success] || []
      error_results = results[:errors] || []

      total_fetched = success_results.sum { |r| r[:fetched] || 0 }
      total_created = success_results.sum { |r| r[:processed] || 0 }
      total_updated = success_results.sum { |r| r[:updated] || 0 }
      total_skipped = success_results.sum { |r| r[:skipped] || 0 }

      {
        sources_processed: success_results.size,
        sources_failed: error_results.size,
        jobs_fetched: total_fetched,
        jobs_created: total_created,
        jobs_updated: total_updated,
        jobs_skipped: total_skipped,
        success_rate: calculate_success_rate(success_results.size, error_results.size)
      }
    end

    def calculate_success_rate(success_count, error_count)
      total = success_count + error_count
      return 0 if total.zero?

      ((success_count.to_f / total) * 100).round(1)
    end

    def check_api_health
      # Basic API health check - you could expand this to actually ping APIs
      JobFetcherService::API_SERVICES.keys.map do |source|
        {
          source: source,
          status: api_configured?(source) ? "configured" : "missing_config",
          last_error: nil # You could track this in Redis or database
        }
      end
    end

    def api_configured?(source)
      case source
      when :jooble
        ENV["JOOBLE_API_KEY"].present? && ENV["JOOBLE_API_URL"].present?
      when :adzuna
        ENV["ADZUNA_APP_ID"].present? && ENV["ADZUNA_APP_KEY"].present?
      when :remotive
        ENV["REMOTIVE_API_URL"].present?
      when :remoteok
        ENV["REMOTEOK_API_URL"].present?
      else
        false
      end
    end

    def get_last_sync_info
      # You could store this information in your database
      # For now, return basic job creation stats
      {
        last_job_created: Job.maximum(:created_at),
        jobs_today: Job.where("created_at >= ?", Date.current).count,
        total_external_jobs: Job.where.not(source: [ "manual", nil ]).count
      }
    end
  end
end
