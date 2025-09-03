#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Testing Jooble API Integration (FIXED)"
puts "=" * 50

# Configuration
api_key = ENV['JOOBLE_API_KEY']

unless api_key
  puts "❌ JOOBLE_API_KEY not found in environment"
  exit 1
end

puts "\n1. Testing Direct Jooble API Call"
puts "-" * 30

begin
  # Use the corrected endpoint format
  url = "https://us.jooble.org/api/#{api_key}"
  uri = URI(url)
  puts "URL: #{url}"

  # Corrected request body - remove problematic datecreatedfrom field
  request_body = {
    keywords: 'developer',
    location: '',
    radius: 25,
    salary: 0,  # Integer instead of empty string
    page: 1
  }
  puts "Request Body: #{request_body.to_json}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
    request.body = request_body.to_json
    http.request(request)
  end

  puts "Status: #{response.code} #{response.message}"
  puts "Content-Type: #{response['content-type']}"
  puts "Response Size: #{response.body.length} bytes"

  if response.code == '200'
    data = JSON.parse(response.body)
    puts "Jobs Count: #{data['jobs']&.size || 0}"

    if data['jobs'] && data['jobs'].any?
      job = data['jobs'].first
      puts "\nFirst Job Sample:"
      puts "  Title: #{job['title']}"
      puts "  Company: #{job['company']}"
      puts "  Location: #{job['location']}"
      puts "  Link: #{job['link']}"
      puts "  ID: #{job['id']}"
      puts "  Updated: #{job['updated']}"
      puts "  Snippet: #{job['snippet'][0..100]}..." if job['snippet']
      puts "  Full job keys: #{job.keys.join(', ')}"
    end
  else
    puts "Error Response: #{response.body[0..500]}..."
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n2. Testing Jooble Service Class"
puts "-" * 30

begin
  require_relative '../app/services/api/jooble_service'

  service = Api::JoobleService.new('developer', 'remote', 5)
  puts "Service created successfully"

  jobs = service.fetch_jobs
  puts "Service returned: #{jobs.length} jobs"

  if jobs.any?
    job = jobs.first
    puts "\nFirst Job from Service:"
    puts "  Title: #{job[:title]}"
    puts "  Company: #{job[:company_name]}"
    puts "  Location: #{job[:location]}"
    puts "  Employment Type: #{job[:employment_type]}"
    puts "  Salary: #{job[:salary_min]}-#{job[:salary_max]} #{job[:currency]}"
    puts "  Description: #{job[:description][0..100]}..." if job[:description]
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n3. Testing Job Processing with Jooble Data"
puts "-" * 30

begin
  # Only test if we have jobs from the service
  if defined?(jobs) && jobs.any?
    require_relative '../app/services/api/job_processor_service'

    processor = Api::JobProcessorService.new(jobs, 'jooble')
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
puts "Jooble Test Complete!"
