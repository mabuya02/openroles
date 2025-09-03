#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🧪 Debug Job Processing Test"
puts "=" * 50

# Enable debug logging
Rails.logger.level = Logger::DEBUG if Rails.env.development?

# Test data that mimics what we get from APIs
test_job_data = {
  title: "Senior Python Developer - #{Time.now.to_i}", # Make it unique
  description: "Great opportunity for a Python developer",
  location: "Remote",
  company_name: "New Tech Startup #{Time.now.to_i}",
  employment_type: "full_time",
  salary_min: 90000,
  salary_max: 130000,
  apply_url: "https://example.com/apply/#{Time.now.to_i}",
  external_id: "test_job_#{Time.now.to_i}",
  posted_at: "2024-01-15T10:00:00Z",
  currency: "USD"
}

puts "\n📋 Test Job Data:"
test_job_data.each { |key, value| puts "  #{key}: #{value}" }

puts "\n📊 Current Database State:"
puts "Jobs count: #{Job.count}"
puts "Companies count: #{Company.count}"

puts "\n🔄 Processing test job with debug..."
processor = Api::JobProcessorService.new([ test_job_data ], "test_api_debug")

# Let's manually call the process_job method to get detailed output
puts "\n🔍 Calling process_job directly..."
begin
  result = processor.send(:process_job, test_job_data)
  if result
    puts "✅ Job created successfully: #{result.inspect}"
  else
    puts "❌ Job creation returned nil"
  end
rescue => e
  puts "💥 Error during job processing: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n📊 Final Database State:"
puts "Jobs count: #{Job.count}"
puts "Companies count: #{Company.count}"
