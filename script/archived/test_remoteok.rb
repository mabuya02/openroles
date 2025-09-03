#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Testing RemoteOK API Integration"
puts "=" * 50

# Configuration
api_url = ENV['REMOTEOK_API_URL'] || 'https://remoteok.com/api'

puts "\n1. Testing Direct RemoteOK API Call"
puts "-" * 30

begin
  # Test basic API call
  uri = URI(api_url)
  puts "URL: #{uri}"

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
    puts "Response Type: #{data.class}"

    if data.is_a?(Array)
      puts "Array Length: #{data.length}"

      # Check if first element is metadata
      first_element = data.first
      if first_element.is_a?(Hash) && first_element["legal"]
        puts "First element is metadata: #{first_element.keys.join(', ')}"
        jobs = data[1..-1]
      else
        puts "First element is job data"
        jobs = data
      end

      puts "Jobs found: #{jobs.length}"

      if jobs.any?
        job = jobs.first
        puts "\nFirst Job Sample:"
        puts "  Position: #{job['position']}"
        puts "  Company: #{job['company']}"
        puts "  Location: #{job['location']}"
        puts "  URL: #{job['url']}"
        puts "  ID: #{job['id']}"
        puts "  Date: #{job['date']}"
        puts "  Tags: #{job['tags']&.join(', ')}"
        puts "  Salary: #{job['salary']}"
        puts "  Description length: #{job['description']&.length || 0}"
        puts "  All job keys: #{job.keys.join(', ')}"
      end
    else
      puts "Unexpected response format: #{data.class}"
      puts "Data keys: #{data.keys.join(', ')}" if data.respond_to?(:keys)
    end
  else
    puts "Error Response: #{response.body[0..500]}..."
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n2. Testing with Search Query"
puts "-" * 30

begin
  # Test with search parameter
  search_uri = URI(api_url)
  search_uri.query = URI.encode_www_form({ q: 'developer' })
  puts "Search URL: #{search_uri}"

  response = Net::HTTP.start(search_uri.hostname, search_uri.port, use_ssl: search_uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(search_uri)
    request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
    http.request(request)
  end

  puts "Status: #{response.code} #{response.message}"
  puts "Response Size: #{response.body.length} bytes"

  if response.code == '200'
    data = JSON.parse(response.body)
    jobs = data.is_a?(Array) && data.first.is_a?(Hash) && data.first["legal"] ? data[1..-1] : data
    puts "Jobs found with search: #{jobs&.length || 0}"
  end

rescue => e
  puts "Error: #{e.message}"
end

puts "\n3. Testing RemoteOK Service Class"
puts "-" * 30

begin
  require_relative '../app/services/api/remote_ok_service'

  service = Api::RemoteOkService.new('developer', 'remote', 5)
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

puts "\n4. Testing Job Processing with RemoteOK Data"
puts "-" * 30

begin
  # Only test if we have jobs from the service
  if defined?(jobs) && jobs.any?
    require_relative '../app/services/api/job_processor_service'

    processor = Api::JobProcessorService.new(jobs, 'remoteok')
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
puts "RemoteOK Test Complete!"
