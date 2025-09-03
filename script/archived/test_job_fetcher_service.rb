#!/usr/bin/env ruby

puts "🎯 Testing Jooble through JobFetcherService"
puts "=" * 50

require_relative '../app/services/job_fetcher_service'

begin
  # Test fetching jobs through the main service
  fetcher = JobFetcherService.new

  puts "\nFetching jobs from all APIs..."
  results = fetcher.fetch_all

  puts "\nResults Summary:"
  puts "Success: #{results[:success]&.count || 0} sources"
  puts "Errors: #{results[:errors]&.count || 0} sources"

  # Test Jooble specifically
  puts "\n" + "-" * 30
  puts "Testing Jooble specifically..."

  fetcher.fetch_from_source(:jooble)
  puts "Jooble processed"

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n" + "=" * 50
puts "JobFetcherService Test Complete!"
