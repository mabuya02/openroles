#!/usr/bin/env ruby

puts "🧪 Fresh Job Creation Test"
puts "=" * 40

# Generate a truly unique job
timestamp = Time.current.to_f
job_data = {
  title: "Unique Ruby Developer #{timestamp}",
  description: "A unique test position for Ruby development",
  location: "Remote",
  company: {
    name: "Unique Test Company #{timestamp}",
    website: "https://unique#{timestamp.to_i}.com"
  },
  employment_type: "full_time",
  apply_url: "https://unique#{timestamp.to_i}.com/apply",
  external_id: "unique-#{timestamp}",
  tags: [ "ruby", "rails" ]
}

puts "Job data:"
puts "  Title: #{job_data[:title]}"
puts "  Company: #{job_data[:company][:name]}"
puts "  External ID: #{job_data[:external_id]}"

puts "\nBefore processing:"
jobs_before = Job.count
companies_before = Company.count
puts "  Jobs: #{jobs_before}"
puts "  Companies: #{companies_before}"

processor = Api::JobProcessorService.new([ job_data ], 'unique_test')
result = processor.process

puts "\nProcessing result: #{result}"

jobs_after = Job.count
companies_after = Company.count
puts "\nAfter processing:"
puts "  Jobs: #{jobs_after} (#{jobs_after - jobs_before > 0 ? '+' : ''}#{jobs_after - jobs_before})"
puts "  Companies: #{companies_after} (#{companies_after - companies_before > 0 ? '+' : ''}#{companies_after - companies_before})"

if jobs_after > jobs_before
  puts "\n✅ Job was created in database"
  latest_job = Job.order(created_at: :desc).first
  puts "   Latest job: #{latest_job.title}"
  puts "   Company: #{latest_job.company.name}"
  puts "   Source: #{latest_job.source}"
else
  puts "\n❌ No job was created in database"
end

# Check if any jobs have our external_id
matching_job = Job.find_by(external_id: job_data[:external_id])
if matching_job
  puts "\n🔍 Found job with our external_id:"
  puts "   ID: #{matching_job.id}"
  puts "   Title: #{matching_job.title}"
  puts "   Source: #{matching_job.source}"
else
  puts "\n❌ No job found with our external_id"
end
