#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Luo osoitelistan CSV-muodossa.
#
# Käyttö:
#    ./osoitelista.rb <osoitelista.csv> [sarake_nimi]
#
# Jos sarakkeen nimi on määritetty, siihen merkataan postitus.
#

if ARGV.length < 1 || ARGV.length > 2
	puts "Käyttö:  ./osoitelista.rb <osoitelista.csv> [sarake_nimi]"
	exit 1
end

OUTPUT = ARGV[0]
COLUMN = ARGV[1]
SENT_MARK = "P"

require_relative 'settings.rb'
require_relative 'userdatabase.rb'

db = UserDatabase.new
total = 0
skipped = 0
lines = ""
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

  if nimi.include?("\n") || osoite1.include?("\n") || osoite2.include?("\n") || postinro.include?("\n") || postitmi.include?("\n")
  	raise "Rivin sisältö sisältää rivinvaihdon: #{nimi}"
  end

  # Generate CSV line
  if osoite2 && osoite2.length > 0
    line = "#{nimi},#{osoite1},#{osoite2},#{postinro} #{postitmi}"
  else
    line = "#{nimi},#{osoite1},#{postinro} #{postitmi},"
  end
  lines << line + "\n"
  total += 1
  
  if COLUMN
  	user[COLUMN] = SENT_MARK
  end

end

File.open(OUTPUT, 'w') { |file| file.write(lines) }
puts "#{total} osoitetta kirjoitettiin tiedostoon #{OUTPUT}"
puts "#{skipped} ulkomaalaista osoitetta tiputtettu pois"
if COLUMN
  db.save
  puts "Tietokantaan merkattiin #{total} lehteä lähetetyksi sarakkeeseen #{COLUMN}"
end

