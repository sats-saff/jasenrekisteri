#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Luo osoitelistan CSV-muodossa.
#
# Käyttö:
#    ./osoitelista.rb > osoitelista.csv
#

require_relative 'settings.rb'
require_relative 'userdatabase.rb'

db = UserDatabase.new
skipped = 0
db.users.each do |user|
  
  # Ignore users abroad
  if user["maa"] != ""
    skipped+=1
    next
  end

  # Select proper name (first+last or last)
  nimi = user.nimi.gsub(",", " ")
  osoite1 = user.csv("osoite1")
  osoite2 = user.csv("osoite2")
  postinro = user.csv("postinro")
  postitmi = user.csv("postitoimipaikka").upcase

  # Generate CSV line
  if osoite2 && osoite2.length > 0
    line = "#{nimi},#{osoite1},#{osoite2},#{postinro} #{postitmi}"
  else
    line = "#{nimi},#{osoite1},#{postinro} #{postitmi},"
  end
  puts line

end

$stderr.puts "#{skipped} ulkomaalaista osoitetta tiputtettu pois"

