#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🔍 Testing Adzuna API with Different Parameter Combinations"
puts "=" * 60

api_url = ENV['ADZUNA_API_URL'] || 'https://api.adzuna.com/v1/api/jobs'
app_id = ENV['ADZUNA_APP_ID']
app_key = ENV['ADZUNA_APP_KEY']

# Test 1: Minimal parameters
puts "\n1. Testing with minimal parameters"
begin
  country = "us"
  url = "#{api_url}/#{country}/search/1"

  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5
  }

  uri = URI(url)
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Response: #{response.body[0..300]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Test 2: Without content_type parameter
puts "\n2. Testing without content_type parameter"
begin
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5,
    what: "developer"
  }

  uri = URI("#{api_url}/us/search/1")
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Response: #{response.body[0..300]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Test 3: Check if credentials are working with basic search
puts "\n3. Testing basic search without what parameter"
begin
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5
  }

  uri = URI("#{api_url}/us/search/1")
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Response: #{response.body[0..300]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Test 4: Try different country
puts "\n4. Testing with UK endpoint"
begin
  params = {
    app_id: app_id,
    app_key: app_key,
    results_per_page: 5
  }

  uri = URI("#{api_url}/gb/search/1")
  uri.query = URI.encode_www_form(params)

  puts "URL: #{uri}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Response: #{response.body[0..300]}..."
rescue => e
  puts "Error: #{e.message}"
end
