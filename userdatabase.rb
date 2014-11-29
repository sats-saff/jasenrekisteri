#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Prompts user for username and password (alternatively provided in
# GOOGLE_USERNAME and GOOGLE_PASSWORD environment variables),
# and reads the user database into the variable 'users'.


# Document ID to read from, provided in the URL
# https://docs.google.com/spreadsheet/ccc?key=<DOCUMENT_ID>
#DOCUMENT_ID = "abcdef"

# Column name for user ID
USER_ID_COLUMN = "jasennro"

# Pattern for matching a valid user ID.
# Any row not containing a valid user ID is ignored.
USER_ID_PATTERN = /^[0-9]+$/

# Column name for the resignation date.
# Any row that has a date in this column is ignored.
RESIGNED_DATE_COLUMN = "eroamispvm"



require "rubygems"
require "google_drive"
require 'pp'
require "highline/import"
$terminal = HighLine.new($stdin, $stderr)

class UserDatabase

  attr_reader :worksheet, :users, :header

  def initialize(username = nil, password = nil, document_id = nil)
    @username = username || ENV['GOOGLE_USERNAME'] || ask("Google username:  ")
    @password = password || ENV['GOOGLE_PASSWORD'] || ask("Google password:  ") { |q| q.echo = false }
    @document_id = document_id || ENV['DOCUMENT_ID'] || DOCUMENT_ID

    # Logs in.
    @session = GoogleDrive.login(@username, @password)

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

end

