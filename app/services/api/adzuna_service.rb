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

    def remote_location?(loc)
      return false unless loc.present?

      remote_terms = %w[remote telecommute work\ from\ home anywhere wfh]
      remote_terms.any? { |term| loc.downcase.include?(term.downcase) }
    end

    # Override base class method to handle Adzuna's location hash format
    def extract_remote_policy(job_data)
      return "remote" if job_data["remote"] == true
      return "onsite" if job_data["remote"] == false

      # Handle Adzuna's location hash format
      location_display = if job_data["location"].is_a?(Hash)
        job_data["location"]["display_name"] || ""
      else
        job_data["location"]&.to_s || ""
      end

      location_text = location_display.downcase
      description = job_data["description"]&.downcase || ""
      title = job_data["title"]&.downcase || ""

      # Check for remote indicators in location, title, or description
      remote_terms = [ "remote", "anywhere", "work from home", "telecommute", "wfh" ]

      if remote_terms.any? { |term| [ location_text, title, description ].any? { |field| field.include?(term) } }
        "remote"
      elsif location_text.include?("hybrid") || description.include?("hybrid")
        "hybrid"
      else
        "onsite"
      end
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
      contract_type = job_data["contract_type"]&.downcase

      case contract_type
      when "permanent"
        "full_time"
      when "contract"
        "contract"
      when "part_time"
        "part_time"
      when "temporary"
        "contract"
      else
        "full_time"
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

      # Extract skills from description
      description = job_data["description"]&.downcase || ""

      # Programming languages and frameworks
      tech_skills = %w[
        ruby python java javascript typescript php go rust swift kotlin scala
        rails django flask spring laravel symfony nodejs react angular vue
        mysql postgresql mongodb redis elasticsearch solr
        aws azure gcp heroku digitalocean
        docker kubernetes terraform ansible
        git github gitlab bitbucket jenkins circleci
        html css sass scss bootstrap tailwind
        rest soap graphql grpc websocket
        linux ubuntu centos debian macos windows
      ]

      found_skills = tech_skills.select { |skill| description.include?(skill) }
      tags.concat(found_skills)

      tags.compact.uniq
    end
  end
end
