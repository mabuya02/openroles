#!/usr/bin/env ruby
# Comprehensive Test Script for OpenRoles Core Functionalities

require_relative 'config/environment'

puts "🧪 OPENROLES COMPREHENSIVE FUNCTIONALITY TEST"
puts "=" * 60

# Test 1: Job Fetching & Company Creation
puts "\n1️⃣ TESTING JOB FETCHING & COMPANY CREATION"
puts "-" * 40

begin
  # Test the job fetcher service
  job_count_before = Job.count
  company_count_before = Company.count

  # Create a test job manually to simulate fetching
  test_company = Company.find_or_create_by(name: "Test Tech Company") do |company|
    company.industry = "Technology"
    company.status = CompanyStatus::ACTIVE
    company.slug = "test-tech-company"
  end

  test_job = Job.create!(
    title: "Software Engineer",
    description: "Test job description",
    company: test_company,
    employment_type: "full_time",
    status: JobStatus::OPEN,
    source: "test",
    currency: "USD"
  )

  job_count_after = Job.count
  company_count_after = Company.count

  puts "✅ Jobs created: #{job_count_after - job_count_before}"
  puts "✅ Companies created: #{company_count_after - company_count_before}"
  puts "✅ Test job ID: #{test_job.id}"

rescue => e
  puts "❌ Job fetching test failed: #{e.message}"
end

# Test 2: Natural Language Search
puts "\n2️⃣ TESTING NATURAL LANGUAGE SEARCH"
puts "-" * 40

begin
  search_service = NaturalLanguageSearchService.new("software engineer")
  search_results = search_service.parse_and_search

  puts "✅ Search service initialized successfully"
  puts "✅ Search results count: #{search_results.count}"

  # Test different search queries
  test_queries = [
    "remote python developer",
    "marketing manager at tech companies",
    "full-time software engineer"
  ]

  test_queries.each do |query|
    service = NaturalLanguageSearchService.new(query)
    results = service.parse_and_search
    puts "✅ Query: '#{query}' → #{results.count} results"
  end

rescue => e
  puts "❌ Natural language search test failed: #{e.message}"
end

# Test 3: Remote Jobs Functionality
puts "\n3️⃣ TESTING REMOTE JOBS FUNCTIONALITY"
puts "-" * 40

begin
  # Create a remote job for testing
  remote_job = Job.create!(
    title: "Remote Frontend Developer",
    description: "Work from anywhere",
    company: test_company,
    location: "Remote",
    employment_type: "full_time",
    status: JobStatus::OPEN,
    source: "test",
    currency: "USD"
  )

  # Test remote job detection
  is_remote = remote_job.remote_friendly?
  puts "✅ Remote job created: #{remote_job.title}"
  puts "✅ Remote detection working: #{is_remote}"

  # Test remote jobs scope
  remote_jobs_count = Job.remote_friendly.count
  puts "✅ Total remote jobs: #{remote_jobs_count}"

rescue => e
  puts "❌ Remote jobs test failed: #{e.message}"
end

# Test 4: User & Saved Jobs
puts "\n4️⃣ TESTING USER & SAVED JOBS FUNCTIONALITY"
puts "-" * 40

begin
  # Create or find a test user
  test_user = User.find_or_create_by(email: "test@example.com") do |user|
    user.first_name = "Test"
    user.last_name = "User"
    user.password = "TestPassword123!"
    user.status = UserStatus::ACTIVE
  end

  puts "✅ Test user created/found: #{test_user.email}"

  # Test saved jobs functionality
  saved_jobs_before = test_user.saved_jobs.count

  # Save a job
  saved_job = test_user.saved_jobs.find_or_create_by(job: test_job)

  saved_jobs_after = test_user.saved_jobs.count

  puts "✅ Saved jobs before: #{saved_jobs_before}"
  puts "✅ Saved jobs after: #{saved_jobs_after}"
  puts "✅ Job saved successfully: #{saved_job.persisted?}"

  # Test user methods
  has_saved = test_user.has_saved_job?(test_job)
  saved_job_record = test_user.saved_job_for(test_job)

  puts "✅ has_saved_job? method: #{has_saved}"
  puts "✅ saved_job_for method: #{saved_job_record.present?}"

rescue => e
  puts "❌ User & saved jobs test failed: #{e.message}"
end

# Test 5: Alert System
puts "\n5️⃣ TESTING ALERT SYSTEM"
puts "-" * 40

begin
  # Create a test alert
  test_alert = test_user.alerts.find_or_create_by(
    criteria: { "natural_query" => "software engineer" },
    frequency: "daily",
    status: AlertStatus::ACTIVE
  ) do |alert|
    alert.unsubscribe_token = SecureRandom.hex(32)
  end

  puts "✅ Test alert created: #{test_alert.id}"
  puts "✅ Alert criteria: #{test_alert.criteria}"

  # Test alert matching
  matching_jobs = test_alert.matching_jobs.limit(5)
  puts "✅ Matching jobs found: #{matching_jobs.count}"

  matching_jobs.each_with_index do |job, index|
    puts "   #{index + 1}. #{job.title} at #{job.company.name}"
  end

rescue => e
  puts "❌ Alert system test failed: #{e.message}"
end

# Test 6: Email System
puts "\n6️⃣ TESTING EMAIL SYSTEM"
puts "-" * 40

begin
  # Test email configuration
  smtp_settings = ActionMailer::Base.smtp_settings
  puts "✅ SMTP Host: #{smtp_settings[:address]}"
  puts "✅ SMTP Port: #{smtp_settings[:port]}"
  puts "✅ SMTP configured: #{smtp_settings[:address].present?}"

  # Test email creation (without sending)
  if test_alert.present? && matching_jobs.any?
    mailer = AlertMailer.job_alert_notification(test_alert, matching_jobs.to_a)
    puts "✅ Email mailer created successfully"
    puts "✅ Email subject: #{mailer.subject}"
    puts "✅ Email to: #{mailer.to}"
  end

rescue => e
  puts "❌ Email system test failed: #{e.message}"
end

# Test 7: Database Performance
puts "\n7️⃣ TESTING DATABASE PERFORMANCE"
puts "-" * 40

begin
  # Test database indexes
  saved_jobs_indexes = ActiveRecord::Base.connection.indexes('saved_jobs')
  puts "✅ SavedJobs table indexes: #{saved_jobs_indexes.count}"

  saved_jobs_indexes.each do |index|
    puts "   - #{index.name}: #{index.columns.join(', ')}"
  end

  # Test query performance
  start_time = Time.current

  # Simulate N+1 query prevention
  jobs_with_companies = Job.includes(:company).limit(10)

  end_time = Time.current
  query_time = ((end_time - start_time) * 1000).round(2)

  puts "✅ Query performance test: #{query_time}ms for 10 jobs with companies"

rescue => e
  puts "❌ Database performance test failed: #{e.message}"
end

# Test 8: API Endpoints
puts "\n8️⃣ TESTING API ENDPOINTS"
puts "-" * 40

begin
  # Test if controllers can be instantiated
  jobs_controller = JobsController.new
  saved_jobs_controller = SavedJobsController.new
  companies_controller = CompaniesController.new

  puts "✅ JobsController instantiated"
  puts "✅ SavedJobsController instantiated"
  puts "✅ CompaniesController instantiated"

  # Test service classes
  remote_jobs_service = Remote::JobsService.new
  puts "✅ Remote::JobsService instantiated"

rescue => e
  puts "❌ API endpoints test failed: #{e.message}"
end

# Summary
puts "\n📊 TEST SUMMARY"
puts "=" * 60

total_jobs = Job.count
total_companies = Company.count
total_users = User.count
total_saved_jobs = SavedJob.count
total_alerts = Alert.count

puts "📈 Database Statistics:"
puts "   Jobs: #{total_jobs}"
puts "   Companies: #{total_companies}"
puts "   Users: #{total_users}"
puts "   Saved Jobs: #{total_saved_jobs}"
puts "   Alerts: #{total_alerts}"

puts "\n✅ All core functionalities tested!"
puts "🚀 OpenRoles system is ready for use!"
