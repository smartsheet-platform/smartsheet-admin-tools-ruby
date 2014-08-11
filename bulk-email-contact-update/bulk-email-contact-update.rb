#!/usr/bin/env ruby
require 'httparty'
require 'active_support/core_ext/hash/deep_merge'
require 'json'
require 'csv'
require 'benchmark'
require 'cgi'

#
# replace old email addresses with new ones in contact list columns
# this is to keep reminders and resource management working
#

# must be an admin token
SS_TOKEN = 'INSERT-YOUR-TOKEN-HERE'
CSV_FILE = 'email-map.csv'

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

    return json, response.code
  end
end


# benchmark execution
elapsed = Benchmark.realtime {

  ss = Smartsheet.new(SS_TOKEN)
  email_map = {}
  sheets = []

  puts
  puts 'Starting email replace...'

  puts 'Loading email map CSV file...'
  csv = CSV.table(CSV_FILE, options = Hash.new)
  puts "  CSV file loaded...  Emails found: #{csv.length}"

  puts "  Building email map..."
  csv.each {|item|
    # CSV format: old, new
    old, new = item.fields
    email_map[old] = new
  }
  puts "  Done building email map...  Emails to update: #{email_map.length}"
  puts
 
  puts "Fetching the list of org sheets..."
  sheets, result_code = ss.request('get', '/users/sheets') 
  if result_code.to_s !~ /^2/
    puts "  Error fetching list: #{result_code}... Exiting."
    exit
  end
  puts "  Done fetching list of sheets ...  Sheets: #{sheets.length}"
  puts

  puts "Processing sheets ..."
  sheets.each_with_index {|sheet, index|
    puts "  sheet #{index+1}"
    owner = sheet['owner']
    options = { headers: { 'Assume-User' => CGI.escape(owner)} }
    body = ss.request('get', "/sheet/#{sheet['id']}", options)[0]
    columns = body['columns']
    rows = body['rows']
    contact_columns = columns.select{|c| c['type'] == "CONTACT_LIST"}
    contact_columns_ids = contact_columns.collect{|cc| cc['id']}
    if !contact_columns.empty?
      puts "  sheet has #{contact_columns.length} CONTACT_LIST columns"

      rows.each_with_index {|row, index|

        cells_to_update = [] 
        puts "    processing row #{index+1}"
        # extract contact column cells from rows
        contact_cells = row['cells'].select{|cell|
          contact_columns_ids.include?(cell['columnId'])
        }
        puts "    found CONTACT_LIST cells: #{contact_cells.length}"

        # check against old emails
        contact_cells.each {|cc|
          if new_email = email_map[ cc['value'] ]
            puts "      found email to update: #{new_email}"
            # add to row update query
            cells_to_update << { "columnId" => cc['columnId'], "value" => new_email }
          end
        }

        # if found matches, execute row update query
        # assume identity of sheet owner
        puts "    CONTACT_LIST cells to update #{cells_to_update.length}"
        if !cells_to_update.empty?
          # update row
          options = {
            headers: { 
              'Content-Type' => 'application/json',
              'Assume-User' => CGI.escape(owner)
            },
            body: cells_to_update.to_json
          }
          body = ss.request('put', "/row/#{row['id']}/cells", options) 
          result = body[0]['result']
        end

      }

    end
    puts
  }



  puts "Completed bulk email replace."
}

puts "Total execution time: #{elapsed} seconds."
