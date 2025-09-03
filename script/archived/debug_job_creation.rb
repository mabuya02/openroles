#!/usr/bin/env ruby

puts "🔬 Direct Job Creation Debug"
puts "=" * 50

# Test basic job creation
puts "\n1. Testing basic job creation..."

job_data = {
  title: "Test Ruby Developer",
  description: "A test position for Ruby development",
  location: "Remote",
  company: {
    name: "Test Company Debug",
    website: "https://testcompany.com"
  },
  employment_type: "full_time",
  salary_min: 70000,
  salary_max: 90000,
  currency: "USD",
  apply_url: "https://testcompany.com/apply",
  external_id: "debug-test-#{Time.current.to_i}",
  tags: [ "ruby", "rails", "remote" ],
  posted_at: Time.current
}

puts "Job data structure:"
puts job_data.inspect

puts "\n2. Testing JobProcessorService..."

# Enable debug logging
Rails.logger.level = Logger::DEBUG

processor = Api::JobProcessorService.new([ job_data ], 'manual_test')
result = processor.process

puts "Processing result: #{result}"

puts "\n3. Checking created records..."

jobs_count = Job.count
companies_count = Company.count

puts "Total jobs in database: #{jobs_count}"
puts "Total companies in database: #{companies_count}"

# Check the most recent job
if jobs_count > 0
  latest_job = Job.order(created_at: :desc).first
  puts "\nLatest job:"
  puts "  ID: #{latest_job.id}"
  puts "  Title: #{latest_job.title}"
  puts "  Company: #{latest_job.company.name}"
  puts "  Source: #{latest_job.source}"
  puts "  Status: #{latest_job.status}"
  puts "  Employment Type: #{latest_job.employment_type}"
  puts "  Valid?: #{latest_job.valid?}"
  unless latest_job.valid?
    puts "  Validation errors: #{latest_job.errors.full_messages}"
  end
else
  puts "No jobs found in database"
end

puts "\n4. Testing job validation manually..."

# Try to create a job directly
begin
  company = Company.find_or_create_by(name: "Manual Test Company") do |c|
    c.status = CompanyStatus::ACTIVE
  end

  job = Job.new(
    title: "Manual Test Job",
    description: "A manually created test job",
    location: "Remote",
    company: company,
    employment_type: EmploymentType::FULL_TIME,
    status: JobStatus::OPEN,
    source: "manual_test",
    apply_url: "https://test.com/apply",
    external_id: "manual-#{Time.current.to_i}"
  )

  if job.valid?
    job.save!
    puts "✅ Manual job creation successful: #{job.title}"
  else
    puts "❌ Manual job validation failed:"
    job.errors.full_messages.each do |error|
      puts "   - #{error}"
    end
  end
rescue => e
  puts "❌ Manual job creation error: #{e.message}"
end

puts "\n=" * 50
puts "Debug complete"
