#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "google_drive"
require 'pp'

ACCESS_TOKEN_FILE = 'access-token.txt'

def get_access_token
  begin
    # Read cached access token + test access token for validity
    access_token = File.read(ACCESS_TOKEN_FILE)
    session = GoogleDrive.login_with_oauth(access_token)
    session.spreadsheet_by_key(DOCUMENT_ID)
  rescue
  
    # Authorizes with OAuth and gets an access token.
    client = Google::APIClient.new
    auth = client.authorization
    auth.client_id = CLIENT_ID
    auth.client_secret = CLIENT_SECRET
    auth.scope = [
      "https://www.googleapis.com/auth/drive",
      "https://spreadsheets.google.com/feeds/"
    ]
    auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
    print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
    print("2. Enter the authorization code shown in the page: ")
    auth.code = $stdin.gets.chomp
    auth.fetch_access_token!
    access_token = auth.access_token

    File.open(ACCESS_TOKEN_FILE, 'w') do |file|
      file.write(access_token)
    end
  end
  return access_token
end

CLIENT_ACCESS_TOKEN = get_access_token


# Column name for user ID
USER_ID_COLUMN = "jasennro"

# Pattern for matching a valid user ID.
# Any row not containing a valid user ID is ignored.
USER_ID_PATTERN = /^[0-9]+$/

# Column name for the resignation date.
# Any row that has a date in this column is ignored.
RESIGNED_DATE_COLUMN = "eroamispvm"



class UserDatabase

  attr_reader :worksheet, :users, :header

  def initialize(document_id = nil, access_token = nil)
    @document_id = document_id || ENV['DOCUMENT_ID'] || DOCUMENT_ID

    # Logs in.
    @session = GoogleDrive.login_with_oauth(access_token || ENV['ACCESS_TOKEN'] || CLIENT_ACCESS_TOKEN)



    # Get first worksheet of document
    @worksheet = @session.spreadsheet_by_key(@document_id).worksheets[0]

    @header = @worksheet.rows[0]

    @users = []
    @worksheet.list().each do |row|
      # Exclude description rows
      if row[USER_ID_COLUMN] =~ USER_ID_PATTERN
        case row[RESIGNED_DATE_COLUMN]
        when ""
          @users.push User.new(row)
        when /^[0-9]+\/[0-9]+\/[0-9]+$/
          # ignore
        else
          $stderr.puts "***  WARNING:  Invalid entry in '#{RESIGNED_DATE_COLUMN}' for user id = #{row[USER_ID_COLUMN]}  ***"
          @users.push User.new(row)
        end
      end
    end

  end

  def save
    @worksheet.save()
  end
end


class User

  include(Enumerable)


  def initialize(data)
    @data = data
  end

  def [](key)
    @data[key]
  end

  def []=(key, value)
    @data[key] = value
  end

  # Return a CSV-safe property value.
  # Any commas in the value are replaced with a space.
  def csv(key)
    @data[key].gsub(",", " ")
  end

  def each
    @data.each { |e| yield e }
  end

  def nimi
    if self["etunimi"] != "" && self["sukunimi"] != ""
      "#{self["etunimi"]} #{self["sukunimi"]}"
    elsif self["sukunimi"] != ""
      self["sukunimi"]
    else
      self["etunimi"]
    end
  end
  
  def email
    email = self["sahkoposti"].strip
    email = nil if email == ""
    email
  end
  
  def rakettikortillinen?
    ["R1", "R2", "RM"].include? self["rakettistatus"]
  end
  
  # True jos on joku maksanut kyseisen vuoden jäsenmaksun.
  def maksanut?(year)
    self["#{year}:maksanut"] != ""
  end
  
  # True jos henkilön pitäisi maksaa kyseisen vuoden jäsenmaksu (eli on liittynyt
  # ennen ko. vuoden 1.10.)
  def maksaa?(year)
    limit = "#{year}-10-01"
    self["liittymispvm"] < limit
  end

end


