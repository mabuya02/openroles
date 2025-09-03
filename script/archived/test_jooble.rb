#!/usr/bin/env ruby

# Load Rails environment
require_relative '../config/environment'

puts "🧪 Testing Jooble API Integration"
puts "=" * 50

# Test 1: Direct API call
puts "\n1. Testing Direct Jooble API Call"
puts "-" * 30

begin
  require 'net/http'
  require 'uri'
  require 'json'

  uri = URI("#{ENV['JOOBLE_API_URL']}/#{ENV['JOOBLE_API_KEY']}")
  puts "URL: #{uri}"

  request_body = {
    keywords: 'developer',
    location: '',
    radius: 25,
    salary: '',
    datecreatedfrom: '',
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
    end
  else
    puts "Error Response: #{response.body}"
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test 2: Rails Service Integration
puts "\n\n2. Testing Jooble Service Class"
puts "-" * 30

begin
  service = Api::JoobleService.new('developer', nil, 3)
  puts "Service created successfully"

  jobs = service.fetch_jobs
  puts "Service returned: #{jobs.size} jobs"

  if jobs.any?
    job = jobs.first
    puts "\nFirst Job from Service:"
    puts "  Title: #{job[:title]}"
    puts "  Company: #{job[:company][:name]}"
    puts "  Location: #{job[:location]}"
    puts "  Description: #{job[:description][0..100]}..." if job[:description]
    puts "  Apply URL: #{job[:apply_url]}"
    puts "  External ID: #{job[:external_id]}"
    puts "  Employment Type: #{job[:employment_type]}"
    puts "  Tags: #{job[:tags].inspect}"
  end

rescue => e
  puts "Error in service: #{e.message}"
  puts e.backtrace.first(3)
end

# Test 3: Job Processing
puts "\n\n3. Testing Job Processing with Jooble Data"
puts "-" * 30

begin
  service = Api::JoobleService.new('developer', nil, 2)
  jobs_data = service.fetch_jobs

  if jobs_data.any?
    puts "Processing #{jobs_data.size} jobs from Jooble..."

    # Process jobs
    processor = Api::JobProcessorService.new(jobs_data, 'jooble')
    result = processor.process

    puts "Processing Result:"
    puts "  Created: #{result[:created]}"
    puts "  Updated: #{result[:updated]}"
    puts "  Skipped: #{result[:skipped]}"

    # Check database
    jooble_jobs = Job.where(source: 'jooble')
    puts "\nJooble Jobs in Database: #{jooble_jobs.count}"

    if jooble_jobs.any?
      job = jooble_jobs.first
      puts "Sample DB Job:"
      puts "  Title: #{job.title}"
      puts "  Company: #{job.company.name}"
      puts "  Status: #{job.status}"
      puts "  Employment Type: #{job.employment_type}"
      puts "  Currency: #{job.currency}"
    end

  else
    puts "No jobs data to process"
  end

rescue => e
  puts "Error in processing: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n" + "=" * 50
puts "Jooble Test Complete!"
