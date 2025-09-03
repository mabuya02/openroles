# frozen_string_literal: true

module Api
  # Remotive API integration service
  class RemotiveService < BaseApiService
    private

    def build_uri
      uri = URI(ENV["REMOTIVE_API_URL"])

      query_params = build_query_params
      uri.query = URI.encode_www_form(query_params) if query_params.any?
      uri
    end

    def build_query_params
      params = {}
      params[:limit] = limit if limit && limit > 0
      params[:search] = keywords if keywords.present?
      # Skip category mapping for now to avoid issues
      # params[:category] = map_keywords_to_category if keywords.present?
      params
    end

    def parse_response(response)
      jobs_data = response["jobs"] || response["0"] || []
      return [] unless jobs_data.is_a?(Array)

      jobs_data.map do |job_data|
        normalize_job_data(job_data)
      end
    end

    def normalize_job_data(job_data)
      super.merge(
        title: job_data["title"],
        description: job_data["description"],
        location: job_data["candidate_required_location"] || "Remote",
        company: {
          name: job_data["company_name"],
          website: job_data["company_logo_url"]
        },
        apply_url: job_data["url"],
        external_id: job_data["id"].to_s,
        posted_at: job_data["publication_date"],
        employment_type: extract_job_type(job_data),
        salary_min: extract_salary_min(job_data),
        salary_max: extract_salary_max(job_data),
        currency: "USD", # Remotive typically shows USD
        tags: extract_tags_from_remotive(job_data),
        metadata: {
          requirements: job_data["description"],
          experience_level: extract_experience_level(job_data),
          remote_policy: "remote", # All Remotive jobs are remote
          visa_sponsored: job_data["visa_sponsored"]
        }
      )
    end

    def map_keywords_to_category
      return nil unless keywords.present?

      category_mapping = {
        "software" => "software-dev",
        "developer" => "software-dev",
        "engineering" => "software-dev",
        "frontend" => "software-dev",
        "backend" => "software-dev",
        "fullstack" => "software-dev",
        "devops" => "devops",
        "data" => "data",
        "analytics" => "data",
        "scientist" => "data",
        "design" => "design",
        "designer" => "design",
        "ux" => "design",
        "ui" => "design",
        "marketing" => "marketing",
        "sales" => "sales",
        "product" => "product",
        "manager" => "product"
      }

      keywords_downcase = keywords.downcase
      category_mapping.each do |keyword, category|
        return category if keywords_downcase.include?(keyword)
      end

      nil
    end

    def extract_job_type(job_data)
      job_type = job_data["job_type"]&.downcase || ""

      case job_type
      when "full_time", "full-time"
        "full_time"
      when "part_time", "part-time"
        "part_time"
      when "contract", "contractor", "freelance"
        "contract"
      else
        "full_time"
      end
    end

    def extract_salary_min(job_data)
      salary_str = job_data["salary"]
      return nil unless salary_str.present?

      # Handle salary ranges like "$90 - $150 /hour", "€55k - €80k", "$10k"
      if salary_str.match?(/(\d+(?:k)?)\s*-\s*(\d+(?:k)?)/i)
        # Range format
        min_match = salary_str.match(/(\d+(?:k)?)/i)
        return parse_salary_amount(min_match[1]) if min_match
      elsif salary_str.match?(/(\d+(?:k)?)/i)
        # Single amount - use as minimum
        amount_match = salary_str.match(/(\d+(?:k)?)/i)
        return parse_salary_amount(amount_match[1]) if amount_match
      end

      nil
    end

    def extract_salary_max(job_data)
      salary_str = job_data["salary"]
      return nil unless salary_str.present?

      # Handle salary ranges like "$90 - $150 /hour", "€55k - €80k"
      if salary_str.match?(/(\d+(?:k)?)\s*-\s*(\d+(?:k)?)/i)
        # Range format - get the second number
        range_match = salary_str.match(/\d+(?:k)?\s*-\s*(\d+(?:k)?)/i)
        return parse_salary_amount(range_match[1]) if range_match
      end

      nil
    end

    def parse_salary_amount(amount_str)
      return nil unless amount_str.present?

      # Remove any non-digit/k characters and convert
      clean_amount = amount_str.gsub(/[^\dk]/i, "")

      if clean_amount.downcase.end_with?("k")
        clean_amount.to_i * 1000
      else
        clean_amount.to_i
      end
    end

    def extract_salary(job_data, type)
      # Legacy method - keeping for compatibility
      case type
      when "min"
        extract_salary_min(job_data)
      when "max"
        extract_salary_max(job_data)
      end
    end

    def extract_tags_from_remotive(job_data)
      tags = []

      # Add category as tag
      tags << job_data["category"] if job_data["category"]

      # Extract tags from job title and description
      content = "#{job_data['title']} #{job_data['description']}".downcase

      # Tech stack detection
      tech_stack = %w[
        ruby rails python django javascript node react vue angular
        php laravel java spring kotlin swift ios android
        golang rust scala elixir clojure haskell
        postgresql mysql mongodb redis elasticsearch
        aws azure gcp docker kubernetes terraform
        git github gitlab jenkins circleci travis
        typescript html css sass bootstrap tailwind
        graphql rest api microservices serverless
        linux ubuntu debian centos macos
        agile scrum kanban devops ci/cd
      ]

      found_tech = tech_stack.select { |tech| content.include?(tech) }
      tags.concat(found_tech)

      tags.compact.uniq.map(&:downcase)
    end

    def extract_experience_level(job_data)
      title = job_data["title"]&.downcase || ""
      description = job_data["description"]&.downcase || ""
      content = "#{title} #{description}"

      return "senior" if content.match?(/senior|lead|principal|staff|architect/)
      return "mid" if content.match?(/mid|intermediate|experienced/)
      return "junior" if content.match?(/junior|entry|graduate|intern/)

      "mid" # Default
    end
  end
end
