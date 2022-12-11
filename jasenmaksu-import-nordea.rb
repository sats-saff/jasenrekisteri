#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Lukee Nordean tuottaman tilitapahtuma-export-tiedoston ja päivittää
# jäsenmaksutiedot jäsenrekisteriin.
#
# Käyttö:
#    ./jasenmaksu-import-nordea.rb <tilitapahtumat.csv>
#

require 'date'
require_relative 'settings.rb'
require_relative 'userdatabase.rb'

require_relative 'helpers.rb'


if ARGV.length != 1
  puts "Usage:"
  puts "  #{$0} <tilitapahtumat.csv>"
  exit 1
end

INPUT = ARGV[0]


$db = UserDatabase.new


def process_payment(summa, viite, maksaja, pvm, viesti)
  viite = viite.gsub(" ", "")
  if viite =~ /^(?<jasennro>[0-9]{5})(?<vuosi>20[123][0-9])[0-9]$/
    jasennro = $~[:jasennro]
    vuosi = $~[:vuosi]
    user = $db.users.find { |u| u["jasennro"] == jasennro }
    if user
      txt = "#{summa} #{pvm}"
      if !user["#{vuosi}:maksanut"].include?(txt)
        puts "Lisättiin jäsenmaksu:  #{pvm}  #{summa}  #{maksaja}"
        user["#{vuosi}:maksanut"] = "#{txt} #{user["#{vuosi}:maksanut"]}"
        return true
      else
        puts "Oli jo maksanut:  #{pvm}  #{summa}  #{maksaja}"
      end
    else
      puts "Jäsentä ei löytynyt jäsennumerolla #{jasennro}:  #{pvm}  #{summa}  #{maksaja}  viite: #{viite}  viesti: #{viesti}"
    end
  else
    puts "Tuntematon viitenumero:  #{pvm}  #{summa}  #{maksaja}  viite: #{viite}  viesti: #{viesti}"
  end
  return false
end


count = 0
File.open(INPUT, "r") do |file|
  file.each_line do |line|
  
    # Ignore lines that don't start with a date
    if !(line =~ /^[0-9]/)
      next
    end

    # Parse the line
    # 0:Kirjauspäivä 1:Arvopäivä 2:Maksupäivä 3:Määrä 4:Saaja/Maksaja 5:Tilinumero 6:BIC 7:Tapahtuma 8:Viite 9:Maksajan viite 10:Viesti 11:Kortinnumero 12:Kuitti	
    split = line.split("\t", 15)
    if split.length != 14
      puts "Invalid line: #{line}"
      next
    end
    pvm = split[1]
    summa = split[3]
    maksaja = split[4]
    viite = split[8]
    viesti = split[10]
    if summa =~ /^-/
      # Payment, not receival
      next
    end
    if process_payment(summa, viite, maksaja, pvm, viesti)
      count+=1
    end

  end
end

$db.save

puts "Lisättiin #{count} maksanutta jäsentä."

