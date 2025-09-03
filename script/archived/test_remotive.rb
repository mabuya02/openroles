#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Testing Remotive API Integration"
puts "=" * 50

# Configuration
api_url = ENV['REMOTIVE_API_URL'] || 'https://remotive.com/api/remote-jobs'

puts "\n1. Testing Direct Remotive API Call"
puts "-" * 30

begin
  # Test with basic parameters
  url = "#{api_url}?limit=5&search=developer"
  uri = URI(url)
  puts "URL: #{url}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
    http.request(request)
  end

  puts "Status: #{response.code} #{response.message}"
  puts "Content-Type: #{response['content-type']}"
  puts "Response Size: #{response.body.length} bytes"

  if response.code == '200'
    data = JSON.parse(response.body)
    puts "Response Structure:"
    puts "  Root keys: #{data.keys.join(', ')}"

    # Check for jobs in different possible locations
    jobs = data['jobs'] || data['0'] || []
    puts "  Jobs found: #{jobs.length}"

    if jobs.any?
      job = jobs.first
      puts "\nFirst Job Sample:"
      puts "  Title: #{job['title']}"
      puts "  Company: #{job['company_name']}"
      puts "  Location: #{job['candidate_required_location']}"
      puts "  URL: #{job['url']}"
      puts "  ID: #{job['id']}"
      puts "  Publication Date: #{job['publication_date']}"
      puts "  Job Type: #{job['job_type']}"
      puts "  Category: #{job['category']}"
      puts "  Description length: #{job['description']&.length || 0}"
      puts "  All job keys: #{job.keys.join(', ')}"
    end
  else
    puts "Error Response: #{response.body[0..500]}..."
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n2. Testing Remotive Service Class"
puts "-" * 30

begin
  require_relative '../app/services/api/remotive_service'

  service = Api::RemotiveService.new('developer', 'remote', 5)
  puts "Service created successfully"

  jobs = service.fetch_jobs
  puts "Service returned: #{jobs.length} jobs"

  if jobs.any?
    job = jobs.first
    puts "\nFirst Job from Service:"
    puts "  Title: #{job[:title]}"
    puts "  Company: #{job[:company]}"
    puts "  Location: #{job[:location]}"
    puts "  Employment Type: #{job[:employment_type]}"
    puts "  Salary: #{job[:salary_min]}-#{job[:salary_max]} #{job[:currency]}"
    puts "  Apply URL: #{job[:apply_url]}"
    puts "  Posted: #{job[:posted_at]}"
    puts "  Tags: #{job[:tags]&.join(', ')}"
    puts "  Description length: #{job[:description]&.length || 0}"
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n3. Testing Job Processing with Remotive Data"
puts "-" * 30

begin
  # Only test if we have jobs from the service
  if defined?(jobs) && jobs.any?
    require_relative '../app/services/api/job_processor_service'

    processor = Api::JobProcessorService.new(jobs, 'remotive')
    puts "Created processor with #{jobs.length} jobs"

    results = processor.process
    puts "Processing Results:"
    puts "  Created: #{results[:created]}"
    puts "  Updated: #{results[:updated]}"
    puts "  Skipped: #{results[:skipped]}"

  else
    puts "No jobs data to process"
  end

rescue => e
  puts "Error setting up processor: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n" + "=" * 50
puts "Remotive Test Complete!"
