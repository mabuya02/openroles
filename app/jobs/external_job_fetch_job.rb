class ExternalJobFetchJob < ApplicationJob
  queue_as :low_priority

  def perform(search_queries = [])
    Rails.logger.info "Starting external job fetch"

    # Default search queries if none provided
    search_queries = default_search_queries if search_queries.empty?

    total_jobs_saved = 0

    search_queries.each do |query|
      begin
        Rails.logger.info "Fetching jobs for query: #{query}"

        search_service = NaturalLanguageSearchService.new(query)
        external_jobs = search_service.search_external_jobs

        jobs_saved = external_jobs.count
        total_jobs_saved += jobs_saved

        Rails.logger.info "Saved #{jobs_saved} jobs for query: #{query}"

        # Add a small delay to be respectful to APIs
        sleep(2) unless Rails.env.test?

      rescue => e
        Rails.logger.error "Error fetching jobs for query '#{query}': #{e.message}"
        next
      end
    end

    Rails.logger.info "External job fetch complete: #{total_jobs_saved} total jobs saved"

    # Trigger alert processing if new jobs were found
    if total_jobs_saved > 0
      AlertNotificationJob.perform_later("immediate")
    end

    {
      queries_processed: search_queries.count,
      total_jobs_saved: total_jobs_saved,
      completed_at: Time.current
    }
  end

  private

  def default_search_queries
    [
      "remote software engineer",
      "marketing manager",
      "product manager",
      "data scientist",
      "frontend developer",
      "backend developer",
      "full stack developer",
      "devops engineer",
      "ui ux designer",
      "sales representative"
    ]
  end
end
