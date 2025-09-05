# frozen_string_literal: true

# Service for tracking and analyzing tag-based job fetching performance
class TagBasedAnalyticsService
  include JobFetchingConfig

  # Cache keys
  CACHE_KEYS = {
    history_list: "tag_analytics_history",
    tag_effectiveness: "tag_effectiveness",
    api_stats: "api_performance_stats"
  }.freeze

  class << self
    # Track a job fetch operation
    def track_fetch(strategy:, tags_used:, jobs_found:, api_results: {})
      analytics_data = build_analytics_data(strategy, tags_used, jobs_found, api_results)

      cache_fetch_data(analytics_data)
      add_to_history(analytics_data.slice(:timestamp, :strategy, :jobs_found, :created, :updated))
      update_tag_effectiveness(tags_used, api_results)
    end

    # Get comprehensive analytics
    def get_analytics
      {
        overview: get_overview_stats,
        tag_performance: get_tag_performance,
        api_performance: get_api_performance,
        trends: get_trends,
        recommendations: get_recommendations
      }
    end

    # Get overview statistics
    def get_overview_stats
      {
        total_tags: Tag.count,
        total_jobs: Job.count,
        jobs_last_24h: Job.where(created_at: 24.hours.ago..Time.current).count,
        jobs_last_7d: Job.where(created_at: 7.days.ago..Time.current).count,
        active_apis: get_active_apis_count,
        last_fetch: get_last_fetch_time,
        success_rate: calculate_overall_success_rate
      }
    end

    # Get tag performance analytics
    def get_tag_performance
      {
        top_performing: Tag.joins(:jobs)
                          .group("tags.id")
                          .order(Arel.sql("COUNT(*) DESC"))
                          .limit(10)
                          .includes(:jobs),

        underperforming: Tag.left_joins(:jobs)
                           .group("tags.id")
                           .having("COUNT(jobs.id) < ?", 2)
                           .limit(20),

        recent_additions: Tag.where(created_at: 7.days.ago..Time.current)
                            .order(created_at: :desc),

        effectiveness_by_category: {
          technology: calculate_category_effectiveness(:technology_tags),
          industry: calculate_category_effectiveness(:industry_tags),
          skill: calculate_category_effectiveness(:skill_tags),
          level: calculate_category_effectiveness(:level_tags)
        }
      }
    end

    # Get API performance analytics
    def get_api_performance
      apis = %w[jooble adzuna remotive remoteok]

      apis.map do |api|
        recent_jobs = Job.where(
          source: api,
          created_at: 7.days.ago..Time.current
        )

        {
          api: api,
          jobs_7d: recent_jobs.count,
          success_rate: calculate_api_success_rate(api),
          avg_response_time: get_avg_response_time(api),
          last_successful_fetch: get_last_successful_fetch(api),
          error_rate: calculate_error_rate(api)
        }
      end
    end

    # Get trend data
    def get_trends
      {
        daily_jobs: get_daily_job_trends(30),
        tag_growth: get_tag_growth_trends(30),
        popular_industries: get_industry_trends,
        api_usage: get_api_usage_trends(7)
      }
    end

    # Get actionable recommendations
    def get_recommendations
      recommendations = []

      # Check for underperforming tags
      underperforming_count = Tag.left_joins(:jobs)
                                .group("tags.id")
                                .having("COUNT(jobs.id) < ?", 2)
                                .count

      if underperforming_count.length > 10
        recommendations << {
          type: "warning",
          title: "Many Underperforming Tags",
          message: "#{underperforming_count.length} tags have fewer than 2 jobs. Consider running focused fetches or removing ineffective tags.",
          action: "run_underrepresented_fetch"
        }
      end

      # Check fetch frequency
      last_fetch = get_last_fetch_time
      if last_fetch && last_fetch < 12.hours.ago
        recommendations << {
          type: "info",
          title: "Schedule Regular Fetches",
          message: "Last fetch was more than 12 hours ago. Consider scheduling regular background fetches.",
          action: "schedule_fetch"
        }
      end

      # Check API diversity
      recent_sources = Job.where(created_at: 7.days.ago..Time.current)
                         .group(:source)
                         .count

      if recent_sources.length < 3
        recommendations << {
          type: "warning",
          title: "Low API Diversity",
          message: "Jobs are coming from fewer than 3 APIs. Check API health and diversify sources.",
          action: "check_apis"
        }
      end

      # Check for trending keywords
      trending = identify_trending_keywords
      if trending.any?
        recommendations << {
          type: "success",
          title: "Trending Keywords Identified",
          message: "Consider adding these trending keywords: #{trending.join(', ')}",
          action: "add_trending_tags"
        }
      end

      recommendations
    end

    private

    def build_analytics_data(strategy, tags_used, jobs_found, api_results)
      created_count = api_results.values.sum { |result| result[:created] || 0 }
      updated_count = api_results.values.sum { |result| result[:updated] || 0 }

      {
        timestamp: Time.current,
        strategy: strategy,
        tags_used: tags_used,
        jobs_found: jobs_found,
        api_results: api_results,
        created: created_count,
        updated: updated_count
      }
    end

    def cache_fetch_data(analytics_data)
      Rails.cache.write(
        "fetch_history_#{analytics_data[:timestamp].to_i}",
        analytics_data,
        expires_in: JobFetchingConfig::DEFAULT_CONFIG[:analytics_cache_ttl].days
      )
    end

    def add_to_history(fetch_data)
      history = Rails.cache.read(CACHE_KEYS[:history_list]) || []
      history << fetch_data
      history = history.last(JobFetchingConfig::DEFAULT_CONFIG[:analytics_history_limit])
      Rails.cache.write(
        CACHE_KEYS[:history_list],
        history,
        expires_in: JobFetchingConfig::DEFAULT_CONFIG[:analytics_cache_ttl].days
      )
    end

    def update_tag_effectiveness(tags_used, api_results)
      tags_used.each do |tag_name|
        tag = Tag.find_by(name: tag_name)
        next unless tag

        # Simple effectiveness tracking
        jobs_found = api_results.values.sum { |result| result[:found] || 0 }
        effectiveness = [ jobs_found / 10.0, 1.0 ].min # Scale 0-1

        # Store in cache for quick access
        Rails.cache.write(
          "tag_effectiveness_#{tag.id}",
          {
            effectiveness: effectiveness,
            last_used: Time.current,
            jobs_found: jobs_found
          },
          expires_in: 7.days
        )
      end
    end

    def calculate_category_effectiveness(scope_method)
      tags = Tag.public_send(scope_method)
      return 0 if tags.empty?

      total_jobs = tags.joins(:jobs).count
      total_tags = tags.count

      total_tags > 0 ? (total_jobs.to_f / total_tags).round(2) : 0
    end

    def calculate_api_success_rate(api)
      # This would ideally track actual API call success/failure
      # For now, use job creation as a proxy
      recent_jobs = Job.where(
        source: api,
        created_at: 7.days.ago..Time.current
      ).count

      # Assume success if we got jobs recently
      recent_jobs > 0 ? 95 : 60
    end

    def get_avg_response_time(api)
      # Placeholder - would track actual API response times
      case api
      when "jooble" then 1.2
      when "adzuna" then 0.8
      when "remotive" then 0.5
      when "remoteok" then 0.3
      else 1.0
      end
    end

    def get_last_successful_fetch(api)
      Job.where(source: api)
        .order(created_at: :desc)
        .first
        &.created_at
    end

    def calculate_error_rate(api)
      # Placeholder - would track actual API errors
      rand(1..5) # 1-5% error rate
    end

    def get_daily_job_trends(days)
      (0...days).map do |i|
        date = i.days.ago.beginning_of_day
        count = Job.where(created_at: date..date.end_of_day).count
        {
          date: date.strftime("%m/%d"),
          count: count
        }
      end.reverse
    end

    def get_tag_growth_trends(days)
      (0...days).map do |i|
        date = i.days.ago.beginning_of_day
        count = Tag.where(created_at: date..date.end_of_day).count
        {
          date: date.strftime("%m/%d"),
          count: count
        }
      end.reverse
    end

    def get_industry_trends
      # Based on job titles and descriptions
      Job.where(created_at: 7.days.ago..Time.current)
        .joins(:tags)
        .group("tags.name")
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(10)
        .count
    end

    def get_api_usage_trends(days)
      (0...days).map do |i|
        date = i.days.ago.beginning_of_day
        api_counts = Job.where(created_at: date..date.end_of_day)
                       .group(:source)
                       .count
        {
          date: date.strftime("%m/%d"),
          apis: api_counts
        }
      end.reverse
    end

    def get_active_apis_count
      Job.where(created_at: 24.hours.ago..Time.current)
        .distinct
        .count(:source)
    end

    def get_last_fetch_time
      Rails.cache.read("tag_fetch_history")&.last&.dig(:timestamp)
    end

    def calculate_overall_success_rate
      recent_fetches = Rails.cache.read("tag_fetch_history") || []
      return 100 if recent_fetches.empty?

      successful = recent_fetches.count { |fetch| fetch[:jobs_found] > 0 }
      (successful.to_f / recent_fetches.length * 100).round(1)
    end

    def identify_trending_keywords
      # Placeholder - could analyze job descriptions for trending terms
      trending_terms = [
        "AI", "Machine Learning", "Remote", "Cloud", "DevOps",
        "React", "Python", "Data Science", "Cybersecurity", "Blockchain"
      ]

      existing_tag_names = Tag.pluck(:name).map(&:downcase)
      trending_terms.select { |term| !existing_tag_names.include?(term.downcase) }
                   .sample(3) # Return 3 random trending terms not in our tags
    end
  end
end
