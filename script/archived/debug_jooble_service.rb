#!/usr/bin/env ruby

# Debug the Jooble Service step by step

puts "🔍 Debugging Jooble Service"
puts "=" * 50

require_relative '../app/services/api/jooble_service'

# Create service instance
service = Api::JoobleService.new(keywords: 'developer', location: 'remote', limit: 5)
puts "✅ Service instance created"

# Test make_request method directly
puts "\n1. Testing make_request method"
begin
  response_data = service.send(:make_request)
  puts "✅ make_request returned: #{response_data.class}"
  puts "   Keys: #{response_data.keys}" if response_data.respond_to?(:keys)

  if response_data.is_a?(Hash) && response_data["jobs"]
    puts "   Jobs array present: #{response_data['jobs'].length} jobs"
    puts "   Total count: #{response_data['totalCount']}"
  else
    puts "   ❌ No jobs array found"
    puts "   Response: #{response_data}"
  end
rescue => e
  puts "❌ make_request failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test parse_response method
puts "\n2. Testing parse_response method"
begin
  if defined?(response_data) && response_data
    parsed_jobs = service.send(:parse_response, response_data)
    puts "✅ parse_response returned: #{parsed_jobs.length} jobs"

    if parsed_jobs.any?
      first_job = parsed_jobs.first
      puts "   First job keys: #{first_job.keys}" if first_job.respond_to?(:keys)
      puts "   Title: #{first_job[:title]}" if first_job[:title]
      puts "   Company: #{first_job[:company]}" if first_job[:company]
    end
  else
    puts "⏭️  Skipping parse_response test (no response_data)"
  end
rescue => e
  puts "❌ parse_response failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test full fetch_jobs method
puts "\n3. Testing full fetch_jobs method"
begin
  jobs = service.fetch_jobs
  puts "✅ fetch_jobs returned: #{jobs.length} jobs"

  if jobs.any?
    first_job = jobs.first
    puts "   First job:"
    puts "     Title: #{first_job[:title]}"
    puts "     Company: #{first_job[:company]}"
    puts "     Location: #{first_job[:location]}"
    puts "     Description length: #{first_job[:description]&.length || 0}"
  end
rescue => e
  puts "❌ fetch_jobs failed: #{e.message}"
  puts e.backtrace.first(3)
end
