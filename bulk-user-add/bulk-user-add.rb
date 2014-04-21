#!/usr/bin/env ruby
require 'httparty'
require 'active_support/core_ext/hash/deep_merge'
require 'json'
require 'csv'
require 'benchmark'

SS_TOKEN = 'INSERT_YOUR_TOKEN_HERE'
CSV_FILE = 'user-list.csv'
EMAIL_DOMAINS = %w(example.com example2.com)

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
  puts 'Starting bulk user add...'

  puts 'Loading user CSV file...'
  csv = CSV.table(CSV_FILE, options = Hash.new)
  puts "CSV file loaded, users to add: #{csv.length}"

  puts "Adding users..."
  csv.each_with_index do |item, index|
    # CSV format: Email,FirstName,LastName,Admin,Licensed,ResourceManager
    email, first, last, admin, licensed, rmanager = item.fields
    puts "Adding user #{index + 1}: #{email}"

    # check email domain
    email_domain = email.split("@").last
    # avoid sending out user invitation to join this org:
    # skip if email does not match any of registered domains
    if !(EMAIL_DOMAINS.include?(email_domain))
      puts "* error: email address is not in list of email domains, skipping..."
      next
    end
    
    options = {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        email:      email,
        firstName:  first,
        lastName:   last,
        admin:      admin=="yes" ? true : false,
        licensedSheetCreator:  licensed=="yes" ? true : false, 
        resourceManager:  rmanager=="yes" ? true : false
      }.to_json
    }

    response = ss.request('post', "/users", options)
    # return user id if a user has been successfully added
    puts "User added, id: #{response['result']['id']}." if response['result']
  end

  puts "Completed bulk user add."
  
}

puts "Total execution time: #{elapsed} seconds."
