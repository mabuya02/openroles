# frozen_string_literal: true

module Api
  module Concerns
    # Shared methods for extracting and normalizing job data across API services
    module JobDataExtraction
      # Common tech skills and technologies to extract from job descriptions
      TECH_SKILLS = %w[
        ruby rails python django flask fastapi
        javascript typescript nodejs react vue angular svelte
        java spring kotlin scala
        php laravel symfony
        go golang rust swift
        csharp dotnet
        mysql postgresql mongodb redis elasticsearch solr cassandra
        aws azure gcp heroku digitalocean cloudflare
        docker kubernetes terraform ansible jenkins circleci
        git github gitlab bitbucket
        html css sass scss less bootstrap tailwind
        rest soap graphql grpc websocket
        linux ubuntu centos debian macos windows
        agile scrum kanban devops ci/cd
        tensorflow pytorch keras scikit-learn
        spark hadoop kafka rabbitmq
      ].freeze

      # Employment type keywords mapping
      EMPLOYMENT_TYPE_PATTERNS = {
        full_time: [ /full.?time/i, /permanent/i, /perm/i ],
        part_time: [ /part.?time/i ],
        contract: [ /contract/i, /contractor/i, /freelance/i, /temporary/i, /temp/i ],
        internship: [ /intern/i, /internship/i, /graduate/i ]
      }.freeze

      # Experience level keywords
      EXPERIENCE_LEVELS = {
        senior: [ /senior/i, /lead/i, /principal/i, /staff/i, /expert/i, /architect/i ],
        mid: [ /mid/i, /intermediate/i, /experienced/i ],
        junior: [ /junior/i, /entry/i, /graduate/i, /intern/i, /beginner/i ]
      }.freeze

      # Remote work indicators
      REMOTE_KEYWORDS = %w[
        remote
        telecommute
        work\ from\ home
        anywhere
        wfh
      ].freeze

      # Extract tech skills and tags from text content
      # @param content [String] Text to extract skills from (description, title, etc.)
      # @return [Array<String>] List of found tech skills
      def extract_tech_skills(content)
        return [] unless content.present?

        text = content.to_s.downcase
        TECH_SKILLS.select { |skill| text.include?(skill) }.uniq
      end

      # Determine employment type from job data
      # @param job_data [Hash] Job data hash
      # @param fields [Array<Symbol>] Fields to check (:title, :description, :type, etc.)
      # @return [String] Employment type (full_time, part_time, contract, internship)
      def extract_employment_type_from_text(job_data, fields: [ :title, :description, :type, :job_type ])
        text = fields.map { |field| job_data[field] || job_data[field.to_s] }.compact.join(" ").downcase

        EMPLOYMENT_TYPE_PATTERNS.each do |type, patterns|
          return type.to_s if patterns.any? { |pattern| text.match?(pattern) }
        end

        "full_time" # Default
      end

      # Extract experience level from text content
      # @param content [String] Text to analyze (title, description, tags)
      # @return [String] Experience level (senior, mid, junior)
      def extract_experience_level(content)
        return "mid" unless content.present?

        text = content.to_s.downcase

        EXPERIENCE_LEVELS.each do |level, patterns|
          return level.to_s if patterns.any? { |pattern| text.match?(pattern) }
        end

        "mid" # Default
      end

      # Determine if a location indicates remote work
      # @param location [String] Location string to check
      # @return [Boolean] True if location indicates remote work
      def remote_location?(location)
        return false unless location.present?

        location_text = location.to_s.downcase
        REMOTE_KEYWORDS.any? { |keyword| location_text.include?(keyword) }
      end

      # Extract remote policy from job data
      # @param job_data [Hash] Job data hash
      # @return [String] Remote policy (remote, hybrid, onsite)
      def extract_remote_policy_from_data(job_data)
        # Check explicit remote flag first
        return "remote" if job_data["remote"] == true || job_data[:remote] == true
        return "onsite" if job_data["remote"] == false || job_data[:remote] == false

        # Check location, title, and description for remote indicators
        location = (job_data["location"] || job_data[:location]).to_s.downcase
        title = (job_data["title"] || job_data[:title]).to_s.downcase
        description = (job_data["description"] || job_data[:description]).to_s.downcase

        content = [ location, title, description ].join(" ")

        if REMOTE_KEYWORDS.any? { |keyword| content.include?(keyword) }
          "remote"
        elsif content.include?("hybrid")
          "hybrid"
        else
          "onsite"
        end
      end

      # Parse salary amount from string
      # @param amount_str [String] Salary string like "50k", "50000", "50,000"
      # @return [Integer, nil] Parsed salary amount
      def parse_salary_amount(amount_str)
        return nil unless amount_str.present?

        # Remove any non-digit/k characters and convert
        clean_amount = amount_str.to_s.gsub(/[^\dk]/i, "")
        return nil if clean_amount.empty?

        if clean_amount.downcase.end_with?("k")
          clean_amount.to_i * 1000
        else
          clean_amount.to_i
        end
      end

      # Extract salary from text (handles ranges and single values)
      # @param text [String] Text containing salary information
      # @param type [Symbol] :min or :max
      # @return [Integer, nil] Extracted salary value
      def extract_salary_from_text(text, type: :min)
        return nil unless text.present?

        # Look for salary patterns like $50,000, $50k, £30000, €55k - €80k
        if text.match?(/[\$£€](\d+(?:,\d{3})*(?:k)?)\s*-\s*[\$£€]?(\d+(?:,\d{3})*(?:k)?)/i)
          # Range format
          range_match = text.match(/[\$£€](\d+(?:,\d{3})*(?:k)?)\s*-\s*[\$£€]?(\d+(?:,\d{3})*(?:k)?)/i)
          amount_str = type == :min ? range_match[1] : range_match[2]
          return parse_salary_amount(amount_str)
        elsif text.match?(/[\$£€](\d+(?:,\d{3})*(?:k)?)/i)
          # Single amount
          amount_match = text.match(/[\$£€](\d+(?:,\d{3})*(?:k)?)/i)
          return parse_salary_amount(amount_match[1])
        end

        nil
      end

      # Normalize common tech tag variations
      # @param tag [String] Tag to normalize
      # @return [String] Normalized tag
      def normalize_tech_tag(tag)
        tag_mapping = {
          "js" => "javascript",
          "ts" => "typescript",
          "py" => "python",
          "rb" => "ruby",
          "go" => "golang",
          "k8s" => "kubernetes",
          "tf" => "terraform",
          "pg" => "postgresql",
          "postgres" => "postgresql",
          "mongo" => "mongodb",
          "react.js" => "react",
          "vue.js" => "vue",
          "node.js" => "nodejs",
          "next.js" => "nextjs"
        }

        tag_mapping[tag.to_s.downcase] || tag.to_s.downcase
      end

      # Filter out common non-skill tags
      # @param tags [Array<String>] Tags to filter
      # @return [Array<String>] Filtered skill tags
      def filter_skill_tags(tags)
        excluded_tags = %w[
          remote worldwide anywhere hiring open fulltime full-time
          parttime part-time contract freelance visa new hot
          top featured popular trending urgent apply now
        ]

        Array(tags).reject do |tag|
          tag_str = tag.to_s.downcase
          excluded_tags.include?(tag_str) ||
          tag_str.match?(/^\d+$/) || # Remove numeric tags
          tag_str.length < 2 # Remove very short tags
        end
      end
    end
  end
end
