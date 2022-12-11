#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "google_drive"
require "pp"
require "googleauth"

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
    @document_id = document_id || ENV["DOCUMENT_ID"] || DOCUMENT_ID

    # Logs in.
    credentials = authenticate()
    @session = GoogleDrive::Session.from_credentials(credentials)

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

  # True jos on joku maksanut kyseisen vuoden jäsenmaksun.
  def laskutettu?(year)
    self["#{year}:laskutettu"] != ""
  end

  # True jos henkilön pitäisi maksaa kyseisen vuoden jäsenmaksu (eli on liittynyt
  # ennen ko. vuoden 1.10.)
  def maksaa?(year)
    limit = "#{year}-10-01"
    self["liittymispvm"] < limit
  end
end

def authenticate()
  # Instructions: https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
  file = File.read("./config.json")
  config = JSON.parse(file)

  credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: config["client_id"],
    client_secret: config["client_secret"],
    scope: [
      "https://www.googleapis.com/auth/drive",
      "https://spreadsheets.google.com/feeds/",
    ],
    redirect_uri: "http://localhost/redirect",
    additional_parameters: { "access_type" => "offline" },
  )

  if config["refresh_token"]
    puts 'Using refresh token from config.json. If this fails, remove "refresh_token" from config.json.'
    credentials.refresh_token = config["refresh_token"]
    credentials.fetch_access_token!
    return credentials
  end

  auth_url = credentials.authorization_uri

  puts "1. Open the following URL: #{auth_url}"
  puts "2. Follow the process though despire warnings"
  puts "3. Copy the auth code from the resulting URL 'code' query parameter here:"
  auth_code = ask("Auth code:  ") { |q| q.echo = true }

  credentials.code = auth_code
  credentials.fetch_access_token!

  config["refresh_token"] = credentials.refresh_token
  File.write("./config.json", JSON.pretty_generate(config))

  return credentials
end
