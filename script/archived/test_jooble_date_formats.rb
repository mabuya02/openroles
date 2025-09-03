#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Testing Jooble API with Different Date Formats"
puts "=" * 50

api_key = ENV['JOOBLE_API_KEY']

# Test 1: Remove datecreatedfrom entirely
puts "\n1. Testing WITHOUT datecreatedfrom field"
begin
  url = "https://us.jooble.org/api/#{api_key}"
  uri = URI(url)

  request_body = {
    keywords: 'developer',
    location: '',
    radius: 25,
    salary: 0,
    page: 1
  }

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = request_body.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Response: #{response.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Test 2: With date in YYYY-MM-DD format
puts "\n2. Testing WITH datecreatedfrom as YYYY-MM-DD"
begin
  url = "https://us.jooble.org/api/#{api_key}"
  uri = URI(url)

  # Date from 7 days ago
  seven_days_ago = (Date.today - 7).strftime('%Y-%m-%d')

  request_body = {
    keywords: 'developer',
    location: '',
    radius: 25,
    salary: 0,
    datecreatedfrom: seven_days_ago,
    page: 1
  }

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = request_body.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Date used: #{seven_days_ago}"
  puts "Response: #{response.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Test 3: With date in MM/DD/YYYY format
puts "\n3. Testing WITH datecreatedfrom as MM/DD/YYYY"
begin
  url = "https://us.jooble.org/api/#{api_key}"
  uri = URI(url)

  # Date from 7 days ago in US format
  seven_days_ago = (Date.today - 7).strftime('%m/%d/%Y')

  request_body = {
    keywords: 'developer',
    location: '',
    radius: 25,
    salary: 0,
    datecreatedfrom: seven_days_ago,
    page: 1
  }

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = request_body.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  puts "Status: #{response.code}"
  puts "Date used: #{seven_days_ago}"
  puts "Response: #{response.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end
