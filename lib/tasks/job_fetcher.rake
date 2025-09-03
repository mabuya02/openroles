# frozen_string_literal: true

namespace :jobs do
  desc "Fetch jobs from external APIs"
  task :fetch, [ :sources ] => :environment do |t, args|
    sources = args[:sources]&.split(",")&.map(&:strip)&.map(&:to_sym)

    puts "🚀 Starting job fetch from APIs..."
    puts "Sources: #{sources || 'all available'}"

    start_time = Time.current

    begin
      job_fetcher = JobFetcherService.new(sources: sources, limit: 100)
      results = job_fetcher.fetch_all

      # Display results
      puts "\n📊 Fetch Results:"
      puts "=" * 50

      results[:success]&.each do |result|
        puts "✅ #{result[:source].to_s.upcase}:"
        puts "   Fetched: #{result[:fetched]} jobs"
        puts "   Created: #{result[:processed]} jobs"
        puts "   Updated: #{result[:updated]} jobs"
        puts "   Skipped: #{result[:skipped]} jobs"
        puts
      end

      results[:errors]&.each do |error|
        puts "❌ #{error[:source].to_s.upcase}: #{error[:error]}"
      end

      duration = (Time.current - start_time).round(2)
      total_processed = results[:success]&.sum { |r| r[:processed] || 0 } || 0

      puts "=" * 50
      puts "✨ Completed in #{duration} seconds"
      puts "📈 Total jobs processed: #{total_processed}"

    rescue StandardError => e
      puts "💥 Error: #{e.message}"
      exit 1
    end
  end

  desc "Fetch jobs from specific API source"
  task :fetch_from, [ :source, :keywords ] => :environment do |t, args|
    source = args[:source]&.to_sym
    keywords = args[:keywords]

    unless JobFetcherService::API_SERVICES.key?(source)
      puts "❌ Invalid source: #{source}"
      puts "Available sources: #{JobFetcherService::API_SERVICES.keys.join(', ')}"
      exit 1
    end

    puts "🎯 Fetching jobs from #{source.to_s.upcase}..."
    puts "Keywords: #{keywords}" if keywords

    start_time = Time.current

    begin
      job_fetcher = JobFetcherService.new(sources: [ source ], keywords: keywords, limit: 100)
      job_fetcher.fetch_from_source(source)

      duration = (Time.current - start_time).round(2)
      puts "✅ Completed in #{duration} seconds"

    rescue StandardError => e
      puts "💥 Error: #{e.message}"
      exit 1
    end
  end

  desc "Show job fetch statistics"
  task stats: :environment do
    puts "📊 Job Statistics"
    puts "=" * 40

    total_jobs = Job.count
    external_jobs = Job.where.not(source: [ nil, "manual" ]).count

    puts "Total Jobs: #{total_jobs}"
    puts "External Jobs: #{external_jobs}"
    puts "Manual Jobs: #{total_jobs - external_jobs}"
    puts

    # Jobs by source
    puts "Jobs by Source:"
    Job.group(:source).count.each do |source, count|
      puts "  #{source || 'manual'}: #{count}"
    end
    puts

    # Recent activity
    puts "Recent Activity (last 24h):"
    recent_jobs = Job.where("created_at >= ?", 24.hours.ago).count
    puts "  New jobs: #{recent_jobs}"

    # Companies
    puts "\nCompanies: #{Company.count} total"
    puts "Companies with jobs: #{Company.joins(:jobs).distinct.count}"
  end

  desc "Test API connections"
  task test_apis: :environment do
    puts "🔍 Testing API connections..."
    puts "=" * 40

    JobFetcherService::API_SERVICES.each do |source, service_class|
      print "#{source.to_s.upcase}: "

      begin
        service = service_class.new("test", "remote", 1)
        # This will test the connection without processing results
        service.fetch_jobs
        puts "✅ Connected"
      rescue StandardError => e
        puts "❌ Failed (#{e.message})"
      end
    end
  end
end

# Alias for convenience
task fetch_jobs: "jobs:fetch"
