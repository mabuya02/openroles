#!/usr/bin/env ruby
# Test Solid Queue Job Processing

require_relative 'config/environment'

puts "🔄 Testing Solid Queue Job Processing..."
puts "=" * 50

# Check if Solid Queue is running
puts "1. Checking Solid Queue status..."
active_processes = SolidQueue::Process.count
puts "   Active Solid Queue processes: #{active_processes}"

# Check current job queue
puts "\n2. Current job queue status..."
pending_jobs = SolidQueue::Job.where(finished_at: nil).count
finished_jobs = SolidQueue::Job.where.not(finished_at: nil).count
puts "   Pending jobs: #{pending_jobs}"
puts "   Finished jobs: #{finished_jobs}"

# Test enqueuing a job
puts "\n3. Testing job enqueueing..."
begin
  # Test a simple job first
  TestJob = Class.new(ApplicationJob) do
    def perform(message)
      Rails.logger.info "Test job executed: #{message}"
      puts "✅ Test job executed successfully: #{message}"
    end
  end

  # Enqueue the test job
  job = TestJob.perform_later("Hello from Solid Queue!")
  puts "✅ Test job enqueued successfully with ID: #{job.job_id}"

  # Wait a moment for processing
  sleep(2)

  # Check if it was processed
  if SolidQueue::Job.find_by(active_job_id: job.job_id)&.finished_at
    puts "✅ Test job was processed successfully!"
  else
    puts "⏳ Test job is still pending or processing..."
  end

rescue => e
  puts "❌ Error enqueueing test job: #{e.message}"
end

# Test your actual alert job
puts "\n4. Testing AlertNotificationJob..."
begin
  # Check if we have active alerts
  active_alerts = Alert.active.count
  puts "   Active alerts in database: #{active_alerts}"

  if active_alerts > 0
    # Test enqueueing an alert job
    alert_job = AlertNotificationJob.perform_later('daily')
    puts "✅ AlertNotificationJob enqueued with ID: #{alert_job.job_id}"
  else
    puts "⚠️  No active alerts found, skipping AlertNotificationJob test"
  end

rescue => e
  puts "❌ Error with AlertNotificationJob: #{e.message}"
end

# Test your job fetching job
puts "\n5. Testing JobFetchJob..."
begin
  fetch_job = JobFetchJob.perform_later({ limit: 5 })
  puts "✅ JobFetchJob enqueued with ID: #{fetch_job.job_id}"
rescue => e
  puts "❌ Error with JobFetchJob: #{e.message}"
end

puts "\n6. Final queue status..."
pending_after = SolidQueue::Job.where(finished_at: nil).count
puts "   Pending jobs after test: #{pending_after}"

puts "\n🎉 Solid Queue test completed!"
puts "   Background job processor should be running in your other terminal"
puts "   Jobs will be processed automatically every few seconds"
