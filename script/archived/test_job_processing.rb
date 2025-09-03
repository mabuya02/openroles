#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive API Job Processing Test Script
# This script tests the entire pipeline from API fetch to database storage

puts "🧪 Job Processing Pipeline Test"
puts "=" * 60

def test_api_service(service_name, service_class)
  puts "\n#{service_name.upcase} SERVICE TEST"
  puts "-" * 40

  begin
    # Step 1: Initialize service
    service = service_class.new("developer", nil, 3)
    puts "✅ Service initialized"

    # Step 2: Fetch jobs
    jobs_data = service.fetch_jobs
    puts "✅ API call completed: #{jobs_data.size} jobs fetched"

    if jobs_data.empty?
      puts "❌ No jobs returned from API"
      return false
    end

    # Step 3: Inspect first job
    first_job = jobs_data.first
    puts "\n📋 First job structure:"
    puts "   Title: #{first_job[:title]}"
    puts "   Company: #{first_job[:company]&.dig(:name) || 'N/A'}"
    puts "   Location: #{first_job[:location]}"
    puts "   External ID: #{first_job[:external_id]}"
    puts "   Description length: #{first_job[:description]&.length || 0} chars"
    puts "   Tags: #{first_job[:tags]&.size || 0} items"

    # Step 4: Test job processing
    puts "\n🔄 Testing job processor..."
    initial_job_count = Job.count
    initial_company_count = Company.count

    processor = Api::JobProcessorService.new(jobs_data.first(1), service_name.downcase)
    result = processor.process

    puts "   Processor result: #{result}"
    puts "   Jobs before: #{initial_job_count}, after: #{Job.count}"
    puts "   Companies before: #{initial_company_count}, after: #{Company.count}"

    if result[:created] > 0 || result[:updated] > 0
      puts "✅ Jobs successfully processed!"
      true
    else
      puts "❌ No jobs were created or updated"
      puts "   Skipped: #{result[:skipped]}"
      false
    end

  rescue => e
    puts "❌ Error: #{e.class.name}: #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(3).join(', ')}"
    false
  end
end

def test_company_creation
  puts "\n🏢 COMPANY CREATION TEST"
  puts "-" * 40

  begin
    # Test data
    company_data = {
      name: "Test Company #{Time.current.to_i}",
      website: "https://test.com",
      description: "A test technology company"
    }

    processor = Api::JobProcessorService.new([], 'test')
    company = processor.send(:find_or_create_company, company_data)

    puts "✅ Company created: #{company.name}"
    puts "   ID: #{company.id}"
    puts "   Website: #{company.website}"
    puts "   Industry: #{company.industry}"
    puts "   Status: #{company.status}"

    true
  rescue => e
    puts "❌ Company creation failed: #{e.message}"
    puts "   Error class: #{e.class.name}"
    false
  end
end

def test_job_creation
  puts "\n💼 JOB CREATION TEST"
  puts "-" * 40

  begin
    # Create a test company first
    company = Company.find_or_create_by(name: "Direct Test Company") do |c|
      c.status = CompanyStatus::ACTIVE
    end

    # Test job data
    job_data = {
      title: "Test Developer Position",
      description: "A test job for Ruby developers with Rails experience",
      location: "Remote",
      external_id: "test-#{Time.current.to_i}",
      employment_type: "full_time",
      apply_url: "https://test.com/apply",
      tags: [ "ruby", "rails", "remote" ],
      company: { name: company.name }
    }

    processor = Api::JobProcessorService.new([ job_data ], 'test')
    result = processor.process

    puts "✅ Job processing result: #{result}"

    if result[:created] > 0
      job = Job.last
      puts "   Created job: #{job.title}"
      puts "   Company: #{job.company.name}"
      puts "   Source: #{job.source}"
      puts "   External ID: #{job.external_id}"
      true
    else
      puts "❌ Job was not created"
      false
    end

  rescue => e
    puts "❌ Job creation failed: #{e.message}"
    puts "   Error class: #{e.class.name}"
    puts "   Backtrace: #{e.backtrace.first(3).join(', ')}"
    false
  end
end

def check_validation_issues
  puts "\n🔍 VALIDATION ISSUES CHECK"
  puts "-" * 40

  # Check enum values
  puts "Employment types: #{EmploymentType::VALUES}"
  puts "Job statuses: #{JobStatus::VALUES}"
  puts "Company statuses: #{CompanyStatus::VALUES}"

  # Test validation
  job = Job.new(
    title: "Test",
    description: "Test",
    location: "Test",
    status: "invalid_status"
  )

  if job.valid?
    puts "✅ Job validation passed"
  else
    puts "❌ Job validation errors:"
    job.errors.full_messages.each { |msg| puts "   - #{msg}" }
  end
end

# Run all tests
puts "Starting comprehensive job processing tests..."

# Test basic validation
check_validation_issues

# Test company creation
company_success = test_company_creation

# Test direct job creation
job_success = test_job_creation

# Test each API service
apis_to_test = [
  [ 'RemoteOK', Api::RemoteOkService ],
  [ 'Jooble', Api::JoobleService ],
  [ 'Remotive', Api::RemotiveService ],
  [ 'Adzuna', Api::AdzunaService ]
]

successful_apis = []
apis_to_test.each do |name, service_class|
  if test_api_service(name, service_class)
    successful_apis << name
  end
end

puts "\n" + "=" * 60
puts "📊 FINAL RESULTS"
puts "=" * 60
puts "Company creation: #{company_success ? '✅ SUCCESS' : '❌ FAILED'}"
puts "Direct job creation: #{job_success ? '✅ SUCCESS' : '❌ FAILED'}"
puts "Working APIs: #{successful_apis.join(', ')}"
puts "Failed APIs: #{(apis_to_test.map(&:first) - successful_apis).join(', ')}"

puts "\nTotal jobs in database: #{Job.count}"
puts "Total companies in database: #{Company.count}"

if successful_apis.empty?
  puts "\n🚨 No APIs are working properly. Check the issues above."
else
  puts "\n🎉 #{successful_apis.size}/#{apis_to_test.size} APIs are working!"
end
