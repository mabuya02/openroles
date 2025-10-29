# frozen_string_literal: true

module Api
  # Adzuna API integration service
  class AdzunaService < BaseApiService
    private

    def build_uri
      uri = URI(ENV["ADZUNA_API_URL"])
      country = extract_country_from_location || "us"
      uri.path += "/#{country}/search/1"

      query_params = build_query_params
      uri.query = URI.encode_www_form(query_params)
      uri
    end

    def build_query_params
      params = {
        app_id: ENV["ADZUNA_APP_ID"],
        app_key: ENV["ADZUNA_APP_KEY"],
        results_per_page: limit,
        what: build_search_query
      }
      # Note: Removed content_type parameter as it causes 400 errors

      # Only add location if it's not a remote work search
      if location.present? && !remote_location?(location)
        params[:where] = location
      end

      params[:sort_by] = "date"
      params
    end

    def build_search_query
      query_parts = []
      query_parts << keywords if keywords.present?

      # Include remote-related terms in the search query instead of location
      if location.present? && remote_location?(location)
        query_parts << "remote"
      end

      query_parts.join(" ")
    end



    # Override base class method to handle Adzuna's location hash format
    def extract_remote_policy(job_data)
      # Handle Adzuna's location hash format
      location_display = if job_data["location"].is_a?(Hash)
        job_data["location"]["display_name"] || ""
      else
        job_data["location"]&.to_s || ""
      end

      # Use shared method with formatted location
      job_data_copy = job_data.dup
      job_data_copy["location"] = location_display
      extract_remote_policy_from_data(job_data_copy)
    end

    def parse_response(response)
      return [] unless response["results"].is_a?(Array)

      response["results"].map do |job_data|
        normalize_job_data(job_data)
      end
    end

    def normalize_job_data(job_data)
      super.merge(
        title: job_data["title"],
        description: job_data["description"],
        location: format_location(job_data["location"]),
        company: {
          name: job_data["company"]["display_name"],
          website: job_data["company"]["canonical_url"]
        },
        apply_url: job_data["redirect_url"],
        external_id: job_data["id"].to_s,
        posted_at: job_data["created"],
        employment_type: extract_contract_type(job_data),
        salary_min: job_data.dig("salary_min"),
        salary_max: job_data.dig("salary_max"),
        currency: extract_currency_from_salary(job_data),
        tags: extract_category_tags(job_data)
      )
    end

    def extract_country_from_location
      return "us" unless location.present?

      country_mapping = {
        "united states" => "us",
        "usa" => "us",
        "america" => "us",
        "united kingdom" => "gb",
        "uk" => "gb",
        "england" => "gb",
        "canada" => "ca",
        "australia" => "au",
        "germany" => "de",
        "france" => "fr",
        "netherlands" => "nl",
        "spain" => "es",
        "italy" => "it",
        "poland" => "pl"
      }

      location_downcase = location.downcase
      country_mapping.each do |country_name, code|
        return code if location_downcase.include?(country_name)
      end

      "us" # Default
    end

    def format_location(location_data)
      return "" unless location_data

      parts = []
      parts << location_data["display_name"] if location_data["display_name"]
      parts << location_data["area"][0] if location_data["area"]&.any?

      parts.join(", ")
    end

    def extract_contract_type(job_data)
      # Map Adzuna-specific contract types to standard employment types
      contract_type = job_data["contract_type"]&.downcase || ""
      
      case contract_type
      when "permanent"
        "full_time"
      when "contract", "temporary"
        "contract"
      when "part_time"
        "part_time"
      else
        # Use shared extraction method as fallback
        extract_employment_type_from_text(job_data, fields: [ :title, :description ])
      end
    end

    def extract_currency_from_salary(job_data)
      # Adzuna typically returns currency in salary fields
      job_data["currency"] ||
      job_data["salary_currency"] ||
      (extract_country_from_location == "us" ? "USD" : "GBP")
    end

    def extract_category_tags(job_data)
      tags = []

      # Add category as a tag
      tags << job_data["category"]["label"] if job_data["category"]

      # Extract tech skills from description using shared method
      description = job_data["description"] || ""
      tags.concat(extract_tech_skills(description))

      tags.compact.uniq
    end
  end
end
