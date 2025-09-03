#!/usr/bin/env ruby
# frozen_string_literal: true

# API Data Structure Analysis Script
# This script fetches data from each API and shows the structure

require 'net/http'
require 'uri'
require 'json'

puts "🔍 API Data Structure Analysis"
puts "=" * 50

def test_api(name, url, headers = {})
  puts "\n#{name.upcase} API"
  puts "-" * 30

  begin
    uri = URI(url)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      headers.each { |key, value| request[key] = value }
      request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
      http.request(request)
    end

    puts "Status: #{response.code} #{response.message}"
    puts "Content-Type: #{response['content-type']}"
    puts "Response Size: #{response.body.length} bytes"

    if response.code == '200'
      data = JSON.parse(response.body)

      puts "\nData Structure:"
      puts "Root Type: #{data.class}"

      if data.is_a?(Hash)
        puts "Root Keys: #{data.keys.inspect}"

        # Look for job data
        jobs_key = data.keys.find { |k| k.to_s.downcase.include?('job') }
        if jobs_key && data[jobs_key].is_a?(Array) && data[jobs_key].any?
          sample_job = data[jobs_key].first
          puts "\nSample Job Keys: #{sample_job.keys.inspect}"
          puts "\nSample Job Data:"
          sample_job.each do |key, value|
            display_value = value.is_a?(String) && value.length > 100 ? "#{value[0..100]}..." : value.inspect
            puts "  #{key}: #{display_value}"
          end
        end
      elsif data.is_a?(Array)
        puts "Array Size: #{data.size}"
        if data.any? && data.first.is_a?(Hash)
          sample_job = data.first
          puts "\nSample Job Keys: #{sample_job.keys.inspect}"
          puts "\nSample Job Data:"
          sample_job.each do |key, value|
            display_value = value.is_a?(String) && value.length > 100 ? "#{value[0..100]}..." : value.inspect
            puts "  #{key}: #{display_value}"
          end
        end
      end
    else
      puts "Error Response: #{response.body[0..200]}"
    end

  rescue => e
    puts "Error: #{e.message}"
  end
end

# Test RemoteOK API
test_api("RemoteOK", "https://remoteok.com/api")

# Test Remotive API
test_api("Remotive", "https://remotive.com/api/remote-jobs?limit=3")

# Test Adzuna API (with auth)
adzuna_url = "https://api.adzuna.com/v1/api/jobs/us/search/1?app_id=#{ENV['ADZUNA_APP_ID']}&app_key=#{ENV['ADZUNA_APP_KEY']}&results_per_page=3"
test_api("Adzuna", adzuna_url)

# Test Jooble API (POST request)
puts "\nJOOBLE API"
puts "-" * 30

begin
  uri = URI("#{ENV['JOOBLE_API_URL']}/#{ENV['JOOBLE_API_KEY']}")

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Post.new(uri)
    request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
    request['Content-Type'] = 'application/json'
    request.body = { keywords: 'developer', location: '', page: 1 }.to_json
    http.request(request)
  end

  puts "Status: #{response.code} #{response.message}"
  puts "Content-Type: #{response['content-type']}"
  puts "Response Size: #{response.body.length} bytes"

  if response.code == '200'
    data = JSON.parse(response.body)
    puts "\nData Structure:"
    puts "Root Type: #{data.class}"
    puts "Root Keys: #{data.keys.inspect}"

    if data['jobs'] && data['jobs'].any?
      sample_job = data['jobs'].first
      puts "\nSample Job Keys: #{sample_job.keys.inspect}"
      puts "\nSample Job Data:"
      sample_job.each do |key, value|
        display_value = value.is_a?(String) && value.length > 100 ? "#{value[0..100]}..." : value.inspect
        puts "  #{key}: #{display_value}"
      end
    end
  else
    puts "Error Response: #{response.body[0..200]}"
  end

rescue => e
  puts "Error: #{e.message}"
end

puts "\n" + "=" * 50
puts "Analysis Complete!"
