#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

puts "🔍 Testing Jooble API Endpoint Formats"
puts "=" * 50

# Test data
api_key = ENV['JOOBLE_API_KEY'] || '63f25532-8e66-45db-b244-a60f4c0561f6'
request_body = {
  keywords: "developer",
  location: "remote",
  radius: 25,
  salary: "",
  datecreatedfrom: "",
  page: 1
}

# Format 1: /api/{key} (current implementation)
puts "\n1. Testing Format: https://jooble.org/api/#{api_key}"
begin
  uri1 = URI("https://jooble.org/api/#{api_key}")
  request1 = Net::HTTP::Post.new(uri1)
  request1['Content-Type'] = 'application/json'
  request1['Accept'] = 'application/json'
  request1.body = request_body.to_json

  response1 = Net::HTTP.start(uri1.hostname, uri1.port, use_ssl: true) do |http|
    http.read_timeout = 30
    http.request(request1)
  end

  puts "Status: #{response1.code}"
  puts "Content-Type: #{response1['content-type']}"
  puts "Body preview: #{response1.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Format 2: /api with key in query params
puts "\n2. Testing Format: https://jooble.org/api?key=#{api_key}"
begin
  uri2 = URI("https://jooble.org/api")
  uri2.query = "key=#{api_key}"
  request2 = Net::HTTP::Post.new(uri2)
  request2['Content-Type'] = 'application/json'
  request2['Accept'] = 'application/json'
  request2.body = request_body.to_json

  response2 = Net::HTTP.start(uri2.hostname, uri2.port, use_ssl: true) do |http|
    http.read_timeout = 30
    http.request(request2)
  end

  puts "Status: #{response2.code}"
  puts "Content-Type: #{response2['content-type']}"
  puts "Body preview: #{response2.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Format 3: Include API key in the request body
puts "\n3. Testing Format: https://jooble.org/api with key in body"
begin
  uri3 = URI("https://jooble.org/api")
  request3 = Net::HTTP::Post.new(uri3)
  request3['Content-Type'] = 'application/json'
  request3['Accept'] = 'application/json'

  body_with_key = request_body.merge(key: api_key)
  request3.body = body_with_key.to_json

  response3 = Net::HTTP.start(uri3.hostname, uri3.port, use_ssl: true) do |http|
    http.read_timeout = 30
    http.request(request3)
  end

  puts "Status: #{response3.code}"
  puts "Content-Type: #{response3['content-type']}"
  puts "Body preview: #{response3.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

# Format 4: Try different base URL
puts "\n4. Testing Format: https://us.jooble.org/api/#{api_key}"
begin
  uri4 = URI("https://us.jooble.org/api/#{api_key}")
  request4 = Net::HTTP::Post.new(uri4)
  request4['Content-Type'] = 'application/json'
  request4['Accept'] = 'application/json'
  request4.body = request_body.to_json

  response4 = Net::HTTP.start(uri4.hostname, uri4.port, use_ssl: true) do |http|
    http.read_timeout = 30
    http.request(request4)
  end

  puts "Status: #{response4.code}"
  puts "Content-Type: #{response4['content-type']}"
  puts "Body preview: #{response4.body[0..200]}..."
rescue => e
  puts "Error: #{e.message}"
end

puts "\n" + "=" * 50
puts "Endpoint Format Test Complete!"
