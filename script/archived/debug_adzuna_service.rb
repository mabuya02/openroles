#!/usr/bin/env ruby

puts "🔍 Debugging Adzuna Service Step by Step"
puts "=" * 50

require_relative '../app/services/api/adzuna_service'

# Create service instance
service = Api::AdzunaService.new('developer', 'remote', 5)
puts "✅ Service instance created"

# Test build_uri method
puts "\n1. Testing build_uri method"
begin
  uri = service.send(:build_uri)
  puts "✅ URI built: #{uri}"
rescue => e
  puts "❌ build_uri failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test make_request method
puts "\n2. Testing make_request method"
begin
  response_data = service.send(:make_request)
  puts "✅ make_request returned: #{response_data.class}"
  puts "   Keys: #{response_data.keys}" if response_data.respond_to?(:keys)

  if response_data.is_a?(Hash) && response_data["results"]
    puts "   Results array present: #{response_data['results'].length} jobs"
    puts "   Count: #{response_data['count']}"
    puts "   Mean: #{response_data['mean']}"
  else
    puts "   ❌ No results array found"
    puts "   Response: #{response_data}"
  end
rescue => e
  puts "❌ make_request failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test parse_response method
puts "\n3. Testing parse_response method"
begin
  if defined?(response_data) && response_data
    parsed_jobs = service.send(:parse_response, response_data)
    puts "✅ parse_response returned: #{parsed_jobs.length} jobs"

    if parsed_jobs.any?
      first_job = parsed_jobs.first
      puts "   First job keys: #{first_job.keys}" if first_job.respond_to?(:keys)
      puts "   Title: #{first_job[:title]}" if first_job[:title]
      puts "   Company: #{first_job[:company]}" if first_job[:company]
      puts "   Location: #{first_job[:location]}" if first_job[:location]
    end
  else
    puts "⏭️  Skipping parse_response test (no response_data)"
  end
rescue => e
  puts "❌ parse_response failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test normalize_job_data method with sample data
puts "\n4. Testing normalize_job_data method"
begin
  if defined?(response_data) && response_data && response_data["results"]&.any?
    sample_job = response_data["results"].first
    puts "Sample job data keys: #{sample_job.keys}"

    normalized = service.send(:normalize_job_data, sample_job)
    puts "✅ normalize_job_data returned:"
    normalized.each do |key, value|
      puts "   #{key}: #{value.is_a?(String) && value.length > 100 ? value[0..100] + '...' : value}"
    end
  end
rescue => e
  puts "❌ normalize_job_data failed: #{e.message}"
  puts e.backtrace.first(3)
end

# Test full fetch_jobs method
puts "\n5. Testing full fetch_jobs method"
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
  puts e.backtrace.first(5)
end
