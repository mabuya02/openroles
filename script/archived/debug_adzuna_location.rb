#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🔍 Testing Adzuna Location Parameter Issue"
puts "=" * 50

api_url = ENV['ADZUNA_API_URL'] || 'https://api.adzuna.com/v1/api/jobs'
app_id = ENV['ADZUNA_APP_ID']
app_key = ENV['ADZUNA_APP_KEY']

# Test 1: With location = "remote"
puts "\n1. Testing with where=remote"
begin
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5,
    what: "developer",
    where: "remote",
    sort_by: "date"
  }

  uri = URI("#{api_url}/us/search/1")
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  data = JSON.parse(response.body) if response.code == '200'
  puts "Count: #{data&.dig('count') || 'N/A'}"
  puts "Results: #{data&.dig('results')&.length || 0}"
rescue => e
  puts "Error: #{e.message}"
end

# Test 2: Without location parameter
puts "\n2. Testing without where parameter"
begin
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5,
    what: "developer",
    sort_by: "date"
  }

  uri = URI("#{api_url}/us/search/1")
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  data = JSON.parse(response.body) if response.code == '200'
  puts "Count: #{data&.dig('count') || 'N/A'}"
  puts "Results: #{data&.dig('results')&.length || 0}"

  # Show first job location to see if any are actually remote
  if data&.dig('results')&.any?
    job = data['results'].first
    puts "First job location: #{job.dig('location', 'display_name')}"
  end
rescue => e
  puts "Error: #{e.message}"
end

# Test 3: Try different location terms
puts "\n3. Testing different location terms"
location_terms = [ "remote work", "work from home", "telecommute", "anywhere" ]

location_terms.each do |term|
  puts "\nTrying location: '#{term}'"
  begin
    params = {
      app_id: app_id,
      app_key: app_key,
      results_per_page: 3,
      what: "developer",
      where: term,
      sort_by: "date"
    }

    uri = URI("#{api_url}/us/search/1")
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    data = JSON.parse(response.body) if response.code == '200'
    puts "  Count: #{data&.dig('count') || 0}"
  rescue => e
    puts "  Error: #{e.message}"
  end
end
