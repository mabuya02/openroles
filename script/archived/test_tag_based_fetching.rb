#!/usr/bin/env ruby

puts "🏷️  Testing Tag-Based Job Fetching System"
puts "=" * 60

# Test 1: Show current tags and create seed data if needed
puts "\n1. Current Tag Status"
puts "-" * 30

current_tag_count = Tag.count
puts "Current tags in database: #{current_tag_count}"

if current_tag_count < 20
  puts "Creating seed tag data..."
  Tag.create_industry_seed_data
  puts "After seeding: #{Tag.count} tags"
end

puts "\nSample existing tags:"
Tag.limit(10).each { |tag| puts "  • #{tag.name}" }

puts "\nTag distribution by type:"
puts "  Technology tags: #{Tag.technology_tags.count}"
puts "  Industry tags: #{Tag.industry_tags.count}"
puts "  Skill tags: #{Tag.skill_tags.count}"
puts "  Level tags: #{Tag.level_tags.count}"

# Test 2: Show different keyword strategies
puts "\n2. Testing Keyword Strategies"
puts "-" * 30

strategies = [ :popular, :diverse, :technology_focused, :balanced, :broad ]

strategies.each do |strategy|
  keywords = Tag.get_fetching_keywords(strategy: strategy, limit: 10)
  puts "\n#{strategy.to_s.titleize} strategy (#{keywords.length} keywords):"
  puts "  #{keywords.join(', ')}"
end

# Test 3: Test tag-based job fetching (limited scope for testing)
puts "\n3. Testing Tag-Based Job Fetching"
puts "-" * 30

begin
  require_relative '../app/services/tag_based_job_fetcher_service'

  # Small test with just a few tags
  fetcher = TagBasedJobFetcherService.new(
    tag_strategy: :technology_focused,
    jobs_per_tag: 2,
    max_tags: 5,
    total_job_limit: 10
  )

  puts "Starting small-scale tag-based fetch..."
  results = fetcher.fetch_jobs_by_tags

  puts "\nResults Summary:"
  puts "  Total Jobs Fetched: #{results[:summary][:total_jobs_fetched]}"
  puts "  New Jobs Created: #{results[:summary][:new_jobs_created]}"
  puts "  Tags Attempted: #{results[:summary][:tags_attempted]}"
  puts "  Successful Tags: #{results[:summary][:successful_tags]&.join(', ')}"
  puts "  Errors: #{results[:summary][:errors_count]}"

  if results[:summary][:processing_stats].any?
    puts "\n  Processing Stats:"
    results[:summary][:processing_stats].each do |api, stats|
      puts "    #{api.capitalize}: Created #{stats[:created]}, Updated #{stats[:updated]}, Skipped #{stats[:skipped]}"
    end
  end

rescue => e
  puts "  ❌ Error: #{e.message}"
  puts "     #{e.backtrace.first(3).join("\n     ")}"
end

# Test 4: Test specific industry targeting
puts "\n4. Testing Industry-Specific Fetching"
puts "-" * 30

begin
  # Test healthcare jobs
  healthcare_fetcher = TagBasedJobFetcherService.new(
    jobs_per_tag: 2,
    max_tags: 3,
    total_job_limit: 6
  )

  puts "Fetching healthcare jobs..."
  healthcare_results = healthcare_fetcher.fetch_by_industry_tags('health')

  puts "Healthcare jobs found: #{healthcare_results[:summary][:total_jobs_fetched]}"

  if healthcare_results[:jobs].any?
    puts "Sample healthcare jobs:"
    healthcare_results[:jobs].first(3).each do |job|
      puts "  • #{job[:title]} at #{job[:company]&.dig(:name) || 'Unknown'} (tag: #{job[:search_tag]})"
    end
  end

rescue => e
  puts "  ❌ Error: #{e.message}"
end

# Test 5: Test underrepresented tags
puts "\n5. Testing Underrepresented Tags Strategy"
puts "-" * 30

underrepresented_tags = Tag.left_joins(:jobs)
                          .group("tags.id")
                          .having("COUNT(jobs.id) < ?", 2)
                          .limit(10)
                          .pluck(:name)

puts "Found #{underrepresented_tags.length} underrepresented tags:"
puts "  #{underrepresented_tags.join(', ')}"

if underrepresented_tags.any?
  begin
    underrep_fetcher = TagBasedJobFetcherService.new(
      jobs_per_tag: 2,
      max_tags: 3,
      total_job_limit: 6
    )

    puts "\nFetching jobs for underrepresented tags..."
    underrep_results = underrep_fetcher.fetch_for_underrepresented_tags(min_job_count: 1)

    puts "Jobs found for underrepresented tags: #{underrep_results[:summary][:total_jobs_fetched]}"
    puts "New jobs created: #{underrep_results[:summary][:new_jobs_created]}"

  rescue => e
    puts "  ❌ Error: #{e.message}"
  end
end

# Test 6: Show tag effectiveness
puts "\n6. Tag Effectiveness Analysis"
puts "-" * 30

puts "Most popular tags (by job count):"
Tag.by_job_count.limit(10).each do |tag|
  job_count = tag.jobs.count
  puts "  • #{tag.name}: #{job_count} jobs"
end

puts "\n" + "=" * 60
puts "Tag-Based Job Fetching Test Complete!"

puts "\n💡 Next Steps:"
puts "   1. Run large-scale fetching: TagBasedJobFetcherService.new.fetch_jobs_by_tags"
puts "   2. Target specific industries: fetcher.fetch_by_industry_tags('finance')"
puts "   3. Help underrepresented tags: fetcher.fetch_for_underrepresented_tags"
puts "   4. Add more tags through admin interface or seeds"
puts "   5. Monitor tag performance and adjust strategies"
