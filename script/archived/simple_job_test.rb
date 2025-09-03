#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🧪 Simple Job Processing Test"
puts "=" * 50
puts "Testing job creation with currency field..."

# Test data that mimics what we get from APIs
test_job_data = {
  title: "Senior Ruby Developer",
  description: "Great opportunity for a Ruby developer",
  location: "Remote",
  company_name: "Tech Startup Inc",
  employment_type: "full_time",
  salary_min: 80000,
  salary_max: 120000,
  apply_url: "https://example.com/apply",
  external_id: "test_job_123",
  posted_at: "2024-01-15T10:00:00Z",
  currency: "USD"
}

puts "\n📊 Current Database State:"
puts "Jobs count: #{Job.count}"
puts "Companies count: #{Company.count}"

puts "\n🔄 Processing test job..."
processor = Api::JobProcessorService.new([ test_job_data ], "test_api")
stats = processor.process

puts "\n📈 Processing Stats:"
puts "Created: #{stats[:created]}"
puts "Updated: #{stats[:updated]}"
puts "Skipped: #{stats[:skipped]}"

# Find the created job
if stats[:created] > 0
  created_job = Job.where(source: "test_api").last
  puts "\n✅ Job processed successfully!"
  puts "Job ID: #{created_job.id}"
  puts "Job title: #{created_job.title}"
  puts "Company: #{created_job.company.name}"
  puts "Currency: #{created_job.currency}"
  puts "Employment type: #{created_job.employment_type}"
else
  puts "\n❌ No jobs were created!"
end

puts "\n📊 Final Database State:"
puts "Jobs count: #{Job.count}"
puts "Companies count: #{Company.count}"

# Check the created job
if stats[:created] > 0
  puts "\n🔍 Job Details:"
  job = Job.where(source: "test_api").last
  puts "Title: #{job.title}"
  puts "Company: #{job.company.name}"
  puts "Location: #{job.location}"
  puts "Currency: #{job.currency}"
  puts "Salary: #{job.salary_min} - #{job.salary_max} #{job.currency}"
  puts "Employment Type: #{job.employment_type}"
  puts "Source: #{job.source}"
  puts "Status: #{job.status}"
  puts "Posted at: #{job.posted_at}"
end
