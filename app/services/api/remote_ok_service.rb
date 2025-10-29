# frozen_string_literal: true

module Api
  # RemoteOK API integration service
  class RemoteOkService < BaseApiService
    private

    def build_uri
      uri = URI(ENV["REMOTEOK_API_URL"])

      # Add query parameters if needed
      if keywords.present?
        uri.query = URI.encode_www_form({ q: keywords })
      end

      uri
    end

    def add_headers(request)
      super
      # RemoteOK requires specific user agent
      request["User-Agent"] = "OpenRoles-JobBoard/1.0"
    end

    def parse_response(response)
      # RemoteOK returns an array directly, first element might be metadata
      jobs_array = response.is_a?(Array) ? response : []

      # Skip first element if it's metadata (common pattern for RemoteOK)
      jobs_data = jobs_array.first.is_a?(Hash) && jobs_array.first["legal"] ? jobs_array[1..-1] : jobs_array

      return [] unless jobs_data.is_a?(Array)

      jobs_data.first(limit).map do |job_data|
        normalize_job_data(job_data)
      end
    end

    def normalize_job_data(job_data)
      super.merge(
        title: job_data["position"],
        description: build_description(job_data),
        location: job_data["location"] || "Remote",
        company: {
          name: job_data["company"],
          website: job_data["company_logo"]
        },
        apply_url: job_data["url"] || "https://remoteok.io/remote-jobs/#{job_data['id']}",
        external_id: job_data["id"].to_s,
        posted_at: parse_remoteok_date(job_data["date"]),
        employment_type: determine_employment_type(job_data),
        tags: extract_remoteok_tags(job_data),
        metadata: {
          requirements: job_data["description"],
          experience_level: extract_experience_from_tags(job_data["tags"]),
          remote_policy: "remote",
          visa_sponsored: job_data["tags"]&.include?("visa")
        }
      )
    end

    def build_description(job_data)
      parts = []
      parts << job_data["description"] if job_data["description"]

      # Add tags as skills if description is short
      if job_data["description"]&.length.to_i < 100 && job_data["tags"]
        skills = Array(job_data["tags"]).join(", ")
        parts << "Required skills: #{skills}"
      end

      parts.join("\n\n")
    end

    def parse_remoteok_date(date_value)
      return nil unless date_value

      case date_value
      when Numeric
        # Unix timestamp
        Time.at(date_value)
      when String
        Time.parse(date_value)
      else
        nil
      end
    rescue ArgumentError
      nil
    end

    def determine_employment_type(job_data)
      # Use shared extraction method
      extract_employment_type_from_text(job_data, fields: [ :position, :tags ])
    end

    def extract_remoteok_tags(job_data)
      tags = Array(job_data["tags"]) || []

      # Filter out non-skill tags using shared method
      skill_tags = filter_skill_tags(tags)

      # Normalize tech tags using shared method
      skill_tags.map { |tag| normalize_tech_tag(tag) }.uniq
    end



    def extract_experience_from_tags(tags)
      return "mid" unless tags.is_a?(Array)

      # Use shared experience extraction method
      tags_text = tags.join(" ")
      extract_experience_level(tags_text)
    end
  end
end
