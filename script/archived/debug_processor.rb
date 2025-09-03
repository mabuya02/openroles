#!/usr/bin/env ruby

puts "🔍 JobProcessorService Debug"
puts "=" * 40

# Let's debug step by step
job_data = {
  title: "Debug Ruby Developer",
  description: "A debug position for Ruby development",
  location: "Remote",
  company: {
    name: "Debug Company",
    website: "https://debug.com"
  },
  employment_type: "full_time",
  apply_url: "https://debug.com/apply",
  external_id: "debug-#{Time.current.to_i}",
  tags: [ "ruby", "rails" ]
}

puts "Starting with job data:"
puts job_data.inspect

puts "\n1. Testing valid_job_data?..."
processor = Api::JobProcessorService.new([ job_data ], 'debug_test')

# Access private method for testing
def processor.test_valid_job_data?(job_data)
  valid_job_data?(job_data)
end

is_valid = processor.test_valid_job_data?(job_data)
puts "valid_job_data? result: #{is_valid}"

if is_valid
  puts "\n2. Testing find_or_create_company..."

  def processor.test_find_or_create_company(company_data)
    find_or_create_company(company_data)
  end

  company = processor.test_find_or_create_company(job_data[:company])
  puts "Company result: #{company.inspect}"
  puts "Company persisted: #{company&.persisted?}"

  if company&.persisted?
    puts "\n3. Testing find_or_create_job..."

    def processor.test_find_or_create_job(job_data, company)
      find_or_create_job(job_data, company)
    end

    job = processor.test_find_or_create_job(job_data, company)
    puts "Job result: #{job.inspect}"
    puts "Job persisted: #{job&.persisted?}"

    if job && !job.persisted?
      puts "Job errors: #{job.errors.full_messages}"
    end
  else
    puts "❌ Company not created/found"
  end
else
  puts "❌ Job data validation failed"
end

puts "\n4. Running full process..."
result = processor.process
puts "Final result: #{result}"
