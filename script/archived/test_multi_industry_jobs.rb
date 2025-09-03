#!/usr/bin/env ruby

puts "🌍 Testing Multi-Industry Job Fetching"
puts "=" * 60

require_relative '../app/services/job_fetching_config'
require_relative '../app/services/multi_industry_job_fetcher_service'

# Test 1: Show available categories and keywords
puts "\n1. Available Job Categories"
puts "-" * 40

JobFetchingConfig::JOB_CATEGORIES.each do |category, config|
  puts "#{category.to_s.titleize} (Priority: #{config[:priority]})"
  puts "  Sample keywords: #{config[:keywords].first(5).join(', ')}"
  puts
end

# Test 2: Test different fetching strategies
strategies = [
  {
    name: "Category Focused (Technology + Marketing)",
    config: {
      strategy: :category_focused,
      categories: [ :technology, :marketing ],
      jobs_per_category: 3,
      total_job_limit: 20
    }
  },
  {
    name: "Broad Spectrum Search",
    config: {
      strategy: :broad_search,
      jobs_per_category: 5,
      total_job_limit: 20
    }
  },
  {
    name: "Keyword Rotation",
    config: {
      strategy: :keyword_rotation,
      jobs_per_category: 3,
      total_job_limit: 15
    }
  }
]

strategies.each_with_index do |strategy_info, index|
  puts "\n#{index + 2}. Testing Strategy: #{strategy_info[:name]}"
  puts "-" * 40

  begin
    fetcher = MultiIndustryJobFetcherService.new(**strategy_info[:config])
    results = fetcher.fetch_all_industries

    puts "Results Summary:"
    puts "  Total Jobs Fetched: #{results[:summary][:total_jobs_fetched]}"
    puts "  New Jobs Created: #{results[:summary][:new_jobs_created]}"
    puts "  Categories Discovered: #{results[:summary][:categories_discovered]}"
    puts "  API Sources Used: #{results[:summary][:api_sources_used]}"
    puts "  Errors: #{results[:summary][:errors_count]}"

    if results[:summary][:processing_stats].any?
      puts "\n  Processing Stats by API:"
      results[:summary][:processing_stats].each do |api, stats|
        puts "    #{api.capitalize}: Created #{stats[:created]}, Updated #{stats[:updated]}, Skipped #{stats[:skipped]}"
      end
    end

    # Show sample of different job types found
    if results[:jobs].any?
      puts "\n  Sample Jobs Found:"
      sample_jobs = results[:jobs].first(3)
      sample_jobs.each do |job|
        category = job[:detected_category] || "Unknown"
        puts "    • #{job[:title]} at #{job[:company]&.dig(:name) || 'Unknown Company'} (#{category.to_s.titleize})"
      end
    end

  rescue => e
    puts "  ❌ Error: #{e.message}"
    puts "     #{e.backtrace.first(2).join("\n     ")}"
  end

  puts
end

# Test 3: Demonstrate keyword configuration
puts "\n#{strategies.length + 2}. Testing Keyword Configuration"
puts "-" * 40

puts "Random keywords sample: #{JobFetchingConfig.random_keywords(count: 5).join(', ')}"
puts "Healthcare keywords: #{JobFetchingConfig.keywords_for_category(:healthcare).first(5).join(', ')}"
puts "Finance + Remote keywords: #{JobFetchingConfig.keywords_with_remote(:finance).first(5).join(', ')}"

puts "\n" + "=" * 60
puts "Multi-Industry Job Fetching Test Complete!"

# Test 4: Quick single API test with different keywords
puts "\n#{strategies.length + 3}. Quick Test: Different Keywords per API"
puts "-" * 40

test_keywords = [ 'nurse', 'accountant', 'sales manager', 'teacher', 'consultant' ]

test_keywords.each do |keyword|
  puts "\nTesting keyword: '#{keyword}'"

  begin
    # Test with RemoteOK since it worked well
    require_relative '../app/services/api/remote_ok_service'
    service = Api::RemoteOkService.new(keyword, nil, 3)
    jobs = service.fetch_jobs

    puts "  RemoteOK found: #{jobs.length} jobs"
    if jobs.any?
      puts "    Sample: #{jobs.first[:title]} at #{jobs.first[:company]&.dig(:name)}"
    end
  rescue => e
    puts "  Error: #{e.message}"
  end
end

puts "\n" + "=" * 60
puts "Comprehensive Test Complete!"
