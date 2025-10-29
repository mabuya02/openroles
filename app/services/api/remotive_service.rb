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

      # Handle Remotive-specific format first
      case job_type
      when "full_time", "full-time"
        "full_time"
      when "part_time", "part-time"
        "part_time"
      when "contract", "contractor", "freelance"
        "contract"
      else
        # Use shared extraction method as fallback
        extract_employment_type_from_text(job_data, fields: [ :title, :description ])
      end
    end

    def extract_salary_min(job_data)
      salary_str = job_data["salary"]
      return nil unless salary_str.present?

      # Use shared salary extraction method
      extract_salary_from_text(salary_str, type: :min)
    end

    def extract_salary_max(job_data)
      salary_str = job_data["salary"]
      return nil unless salary_str.present?

      # Use shared salary extraction method
      extract_salary_from_text(salary_str, type: :max)
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

      # Extract tech skills from job title and description using shared method
      content = "#{job_data['title']} #{job_data['description']}"
      tags.concat(extract_tech_skills(content))

      tags.compact.uniq.map(&:downcase)
    end

    def extract_experience_level(job_data)
      # Use shared experience extraction method
      content = "#{job_data['title']} #{job_data['description']}"
      super(content)
    end
  end
end
