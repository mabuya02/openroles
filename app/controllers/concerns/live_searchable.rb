# frozen_string_literal: true

# Shared concern for live search functionality across controllers
module LiveSearchable
  extend ActiveSupport::Concern

  # Perform live search and return JSON suggestions
  # @param jobs_scope [ActiveRecord::Relation] Base scope to search within
  # @param limit [Integer] Maximum number of suggestions to return
  # @return [Hash] JSON response with suggestions and metadata
  def perform_live_search(jobs_scope:, limit: 10)
    query = params[:q]&.strip

    if query.present? && query.length >= 2
      # Use natural language search service for live search
      search_service = NaturalLanguageSearchService.new(query)
      jobs = search_service.parse_and_search
      
      # Apply the scope filter (e.g., remote_friendly)
      jobs = jobs.merge(jobs_scope).limit(limit)

      suggestions = build_job_suggestions(jobs)
      search_metadata = build_search_metadata(search_service, suggestions)
    else
      suggestions = []
      search_metadata = {}
    end

    { suggestions: suggestions, metadata: search_metadata }
  end

  private

  # Build job suggestions array from jobs collection
  # @param jobs [ActiveRecord::Relation] Jobs to convert to suggestions
  # @return [Array<Hash>] Array of job suggestion hashes
  def build_job_suggestions(jobs)
    jobs.includes(:company).map do |job|
      {
        id: job.id,
        title: job.title,
        company: job.company.name,
        location: job.location,
        employment_type: job.employment_type&.humanize,
        url: job_path(job),
        company_url: company_path(job.company)
      }
    end
  end

  # Build search metadata
  # @param search_service [NaturalLanguageSearchService] Search service instance
  # @param suggestions [Array] Suggestions array
  # @return [Hash] Metadata hash
  def build_search_metadata(search_service, suggestions)
    {
      parsed_data: search_service.parsed_data,
      suggestions_count: suggestions.length
    }
  end
end
