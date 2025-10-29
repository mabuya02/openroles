# frozen_string_literal: true

module Api
  # Jooble API integration service
  class JoobleService < BaseApiService
    private

    def build_uri
      # Use the correct Jooble API endpoint
      URI("https://us.jooble.org/api/#{ENV['JOOBLE_API_KEY']}")
    end

    def make_request
      uri = build_uri
      request = Net::HTTP::Post.new(uri)
      add_headers(request)
      request.body = build_request_body.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def build_request_body
      {
        keywords: keywords || "",  # Allow empty keywords for broader search
        location: location || "",
        radius: 25,
        salary: 0, # Jooble expects integer, not string
        page: 1
      }
      # Note: Omitting datecreatedfrom as it causes API errors
    end

    def parse_response(response)
      return [] unless response["jobs"].is_a?(Array)

      response["jobs"].first(limit).map do |job_data|
        normalize_job_data(job_data)
      end
    end

    def normalize_job_data(job_data)
      super.merge(
        title: job_data["title"],
        description: job_data["snippet"],
        location: job_data["location"],
        company: { name: job_data["company"] },
        apply_url: job_data["link"],
        external_id: job_data["id"]&.to_s,
        posted_at: job_data["updated"],
        employment_type: extract_employment_type(job_data),
        salary_min: extract_salary_from_snippet(job_data["snippet"]),
        tags: extract_skills_from_description(job_data["snippet"])
      )
    end

    def extract_employment_type(job_data)
      # Use shared extraction method
      extract_employment_type_from_text(job_data, fields: [ :title, :snippet ])
    end

    def extract_salary_from_snippet(snippet)
      return nil unless snippet.present?

      # Use shared salary extraction method
      extract_salary_from_text(snippet, type: :min)
    end

    def extract_skills_from_description(snippet)
      return [] unless snippet.present?

      # Use shared tech skills extraction method
      extract_tech_skills(snippet)
    end
  end
end
