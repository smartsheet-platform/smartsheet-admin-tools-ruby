#!/usr/bin/env ruby
require 'httparty'
require 'active_support/core_ext/hash/deep_merge'
require 'json'
require 'csv'
require 'benchmark'

SS_TOKEN = 'INSERT_YOUR_TOKEN_HERE'
CSV_FILE = 'user-list.csv'

class Smartsheet
  include HTTParty
  base_uri @@ss_uri = 'https://api.smartsheet.com/1.1'
  
  def initialize(token)
    @auth_options = {headers: {"Authorization" => 'Bearer ' + token}}
  end

  def self.return_ss_uri
    @@ss_uri
  end

  # Perform request, retrying on errors - gracefully handle rate limiting
  def request(method, uri, options={})
    options.deep_merge!(@auth_options)

    puts "* requesting #{method.upcase} #{uri}"
    response = self.class.send(method, uri, options)
    json = JSON.parse(response.body)

    while response.code.to_s !~ /^2/
      # if error other than 503, log and move on
      if response.code.to_s !~ /^503/
        puts "* error: #{json['errorCode']}: #{json['message']}"
        break 
      end
      
      # if 503 (exceeded rate limit), wait and try again
      puts "* waiting 60 seconds due to an error: #{json['errorCode']}: #{json['message']}"
      sleep(60)
      puts "* retrying #{method.upcase} #{uri}"
      response = self.class.send(method, uri, options)
      json = JSON.parse(response.body)
    end

    json
  end
end


# benchmark execution
elapsed = Benchmark.realtime {

  ss = Smartsheet.new(SS_TOKEN)

  puts
  puts 'Starting bulk user remove...'

  puts 'Loading user CSV file...'
  csv = CSV.table(CSV_FILE, options = Hash.new)
  puts "CSV file loaded, users to remove: #{csv.length}"

  puts "Removing users..."
  csv.each_with_index do |item, index|
    userID, userDescriptor, transferTo, removeFromSharing = item.fields
    puts "Removing user #{index + 1}: #{userDescriptor}"

    options = {
      query: {
        transferTo: transferTo,
        removeFromSharing:  removeFromSharing
      }.delete_if { |k, v| v.nil? }
    }

    response = ss.request('delete', "/user/#{userID}", options)
    puts "Response is #{response}"
    puts "User removed" if response['result']
  end

  puts "Completed bulk user remove."
  
}

puts "Total execution time: #{elapsed} seconds."
