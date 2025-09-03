#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Testing Adzuna API Integration"
puts "=" * 50

# Configuration
api_url = ENV['ADZUNA_API_URL'] || 'https://api.adzuna.com/v1/api/jobs'
app_id = ENV['ADZUNA_APP_ID']
app_key = ENV['ADZUNA_APP_KEY']

unless app_id && app_key
  puts "❌ ADZUNA_APP_ID and ADZUNA_APP_KEY not found in environment"
  exit 1
end

puts "\n1. Testing Direct Adzuna API Call"
puts "-" * 30

begin
  # Build the URL with country path
  country = "us"  # Default country
  url = "#{api_url}/#{country}/search/1"

  # Build query parameters (without content_type)
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5,
    what: "developer",
    sort_by: "date"
  }

  uri = URI(url)
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"
  puts "Parameters:"
  params.each { |k, v| puts "  #{k}: #{v}" }

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

    results = data['results'] || []
    puts "  Jobs found: #{results.length}"
    puts "  Count: #{data['count']}" if data['count']

    if results.any?
      job = results.first
      puts "\nFirst Job Sample:"
      puts "  Title: #{job['title']}"
      puts "  Company: #{job['company']&.dig('display_name')}"
      puts "  Location: #{job['location']&.dig('display_name')}"
      puts "  URL: #{job['redirect_url']}"
      puts "  ID: #{job['id']}"
      puts "  Created: #{job['created']}"
      puts "  Salary Min: #{job['salary_min']}"
      puts "  Salary Max: #{job['salary_max']}"
      puts "  Description length: #{job['description']&.length || 0}"
      puts "  All job keys: #{job.keys.join(', ')}"

      puts "\n  Company details:"
      if job['company']
        job['company'].each { |k, v| puts "    #{k}: #{v}" }
      end

      puts "\n  Location details:"
      if job['location']
        job['location'].each { |k, v| puts "    #{k}: #{v}" }
      end
    end
  else
    puts "Error Response: #{response.body[0..500]}..."
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n2. Testing Adzuna Service Class"
puts "-" * 30

begin
  require_relative '../app/services/api/adzuna_service'

  service = Api::AdzunaService.new('developer', 'remote', 5)
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

puts "\n3. Testing Job Processing with Adzuna Data"
puts "-" * 30

begin
  # Only test if we have jobs from the service
  if defined?(jobs) && jobs.any?
    require_relative '../app/services/api/job_processor_service'

    processor = Api::JobProcessorService.new(jobs, 'adzuna')
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
puts "Adzuna Test Complete!"
