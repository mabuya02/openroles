# frozen_string_literal: true

module Api
  # Base class for external API integrations
  class BaseApiService
    include ActiveModel::Validations

    def initialize(keywords = nil, location = nil, limit = 50)
      @keywords = keywords
      @location = location
      @limit = [ limit, 100 ].min # Cap at 100 per request
      @http_client = setup_http_client
    end

    def fetch_jobs
      response = make_request
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "API request failed for #{self.class.name}: #{e.message}"
      []
    end

    private

    attr_reader :keywords, :location, :limit, :http_client

    def setup_http_client
      require "net/http"
      require "uri"
      require "json"
    end

    def make_request
      uri = build_uri
      request = Net::HTTP::Get.new(uri)
      add_headers(request)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def handle_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise "HTTP Error: #{response.code} - #{response.message}"
      end

      JSON.parse(response.body)
    end

    # Abstract methods to be implemented by subclasses
    def build_uri
      raise NotImplementedError, "Subclasses must implement build_uri"
    end

    def add_headers(request)
      request["User-Agent"] = "OpenRoles Job Board/1.0"
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
    end

    def parse_response(response)
      raise NotImplementedError, "Subclasses must implement parse_response"
    end

    def normalize_job_data(job_data)
      {
        title: job_data["title"] || job_data["name"],
        description: job_data["description"] || job_data["snippet"],
        location: extract_location(job_data),
        company: extract_company(job_data),
        employment_type: job_data["type"] || job_data["employment_type"],
        salary_min: extract_salary_min(job_data),
        salary_max: extract_salary_max(job_data),
        currency: extract_currency(job_data),
        apply_url: job_data["url"] || job_data["apply_url"],
        external_id: job_data["id"]&.to_s,
        posted_at: job_data["created_at"] || job_data["date"] || job_data["published_at"],
        tags: extract_tags(job_data),
        metadata: extract_metadata(job_data)
      }
    end

    def extract_location(job_data)
      job_data["location"] ||
      job_data["candidate_required_location"] ||
      [ job_data["city"], job_data["country"] ].compact.join(", ")
    end

    def extract_company(job_data)
      company_name = job_data["company"] || job_data["company_name"]
      return nil unless company_name

      {
        name: company_name,
        description: job_data["company_description"],
        website: job_data["company_url"] || job_data["company_website"]
      }
    end

    def extract_salary_min(job_data)
      salary_data = job_data["salary"] || job_data["salary_min"]
      return nil unless salary_data

      case salary_data
      when Hash
        salary_data["min"] || salary_data["minimum"]
      when String
        extract_number_from_string(salary_data)
      when Numeric
        salary_data
      end
    end

    def extract_salary_max(job_data)
      salary_data = job_data["salary"] || job_data["salary_max"]
      return nil unless salary_data

      case salary_data
      when Hash
        salary_data["max"] || salary_data["maximum"]
      when String
        numbers = salary_data.scan(/\d+/)
        numbers.size > 1 ? numbers.last.to_i : nil
      when Numeric
        salary_data
      end
    end

    def extract_currency(job_data)
      job_data["currency"] ||
      (job_data["salary"].is_a?(Hash) ? job_data["salary"]["currency"] : nil) ||
      "USD"
    end

    def extract_tags(job_data)
      tags = []
      tags.concat(Array(job_data["skills"])) if job_data["skills"]
      tags.concat(Array(job_data["tags"])) if job_data["tags"]
      tags.concat(Array(job_data["technologies"])) if job_data["technologies"]
      tags.compact.uniq
    end

    def extract_metadata(job_data)
      {
        requirements: job_data["requirements"],
        benefits: job_data["benefits"],
        experience_level: job_data["experience_level"],
        remote_policy: extract_remote_policy(job_data),
        visa_sponsored: job_data["visa_sponsored"]
      }
    end

    def extract_remote_policy(job_data)
      return "remote" if job_data["remote"] == true
      return "onsite" if job_data["remote"] == false

      location = job_data["location"]&.downcase || ""
      if location.include?("remote") || location.include?("anywhere")
        "remote"
      elsif location.include?("hybrid")
        "hybrid"
      else
        "onsite"
      end
    end

    def extract_number_from_string(str)
      return nil unless str.is_a?(String)

      numbers = str.scan(/\d+/)
      numbers.first&.to_i
    end
  end
end
