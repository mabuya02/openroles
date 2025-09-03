#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🔍 Comparing Direct Call vs Service Call"
puts "=" * 60

api_key = ENV['JOOBLE_API_KEY']

puts "\n1. DIRECT API CALL (Working)"
puts "-" * 30
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
  request['User-Agent'] = 'OpenRoles-JobBoard/1.0'
  request.body = request_body.to_json

  puts "URL: #{url}"
  puts "Headers:"
  request.each_header { |k, v| puts "  #{k}: #{v}" }
  puts "Body: #{request.body}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  puts "Response Status: #{response.code}"
  puts "Response Size: #{response.body.length}"

rescue => e
  puts "Error: #{e.message}"
end

puts "\n2. SERVICE CALL (Not Working)"
puts "-" * 30

require_relative '../app/services/api/jooble_service'

begin
  service = Api::JoobleService.new(keywords: 'developer', location: '', limit: 5)

  # Manually call the internal methods to see what they produce
  uri = service.send(:build_uri)
  puts "Service URL: #{uri}"

  request_body = service.send(:build_request_body)
  puts "Service Body: #{request_body.to_json}"

  # Create the request like the service does
  request = Net::HTTP::Post.new(uri)
  service.send(:add_headers, request)
  request.body = request_body.to_json

  puts "Service Headers:"
  request.each_header { |k, v| puts "  #{k}: #{v}" }

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  puts "Service Response Status: #{response.code}"
  puts "Service Response Size: #{response.body.length}"
  puts "Service Response Body: #{response.body[0..200]}..."

rescue => e
  puts "Service Error: #{e.message}"
  puts e.backtrace.first(3)
end
