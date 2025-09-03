#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test script for the job fetcher API integration
# Run with: ruby script/test_job_fetcher.rb

puts "🧪 Testing Job Fetcher API Integration"
puts "=" * 50

# Test individual services
puts "\n1. Testing Individual API Services"
puts "-" * 30

begin
  # Test Jooble
  puts "Testing Jooble API..."
  jooble_service = Api::JoobleService.new('ruby developer', 'remote', 2)
  jooble_jobs = jooble_service.fetch_jobs
  puts "✅ Jooble: Fetched #{jooble_jobs.size} jobs"
rescue => e
  puts "❌ Jooble: #{e.message}"
end

begin
  # Test RemoteOK
  puts "Testing RemoteOK API..."
  remoteok_service = Api::RemoteOkService.new('developer', nil, 2)
  remoteok_jobs = remoteok_service.fetch_jobs
  puts "✅ RemoteOK: Fetched #{remoteok_jobs.size} jobs"
rescue => e
  puts "❌ RemoteOK: #{e.message}"
end

# Test main service
puts "\n2. Testing Main JobFetcherService"
puts "-" * 30

begin
  fetcher = JobFetcherService.new(sources: [ :remoteok ], keywords: 'developer', limit: 3)
  results = fetcher.fetch_all

  puts "📊 Results:"
  puts "Success: #{results[:success].size} sources"
  puts "Errors: #{results[:errors].size} sources"

  results[:success].each do |result|
    puts "  #{result[:source]}: #{result[:processed]} jobs processed"
  end

  results[:errors].each do |error|
    puts "  #{error[:source]}: #{error[:error]}"
  end

rescue => e
  puts "❌ JobFetcherService: #{e.message}"
  puts e.backtrace.first(5)
end

# Test database integration
puts "\n3. Testing Database Integration"
puts "-" * 30

initial_jobs = Job.count
initial_companies = Company.count

puts "Initial counts - Jobs: #{initial_jobs}, Companies: #{initial_companies}"

begin
  # Run a small fetch to test database integration
  JobFetchJob.perform_now(sources: [ :remoteok ], limit: 2)

  final_jobs = Job.count
  final_companies = Company.count

  puts "Final counts - Jobs: #{final_jobs}, Companies: #{final_companies}"
  puts "New jobs: #{final_jobs - initial_jobs}"
  puts "New companies: #{final_companies - initial_companies}"

rescue => e
  puts "❌ Database integration: #{e.message}"
end

puts "\n✅ Test completed!"
puts "\nTo run manual fetches:"
puts "  rails jobs:fetch"
puts "  rails jobs:fetch_from[remoteok]"
puts "  rails jobs:stats"
