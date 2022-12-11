#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Lukee Nordean tuottaman tilitapahtuma-export-tiedoston ja päivittää
# jäsenmaksutiedot jäsenrekisteriin.
#
# Tiedostonimi 'SHEKKITILI <tilinro> - <pvm>.csv',
# semicolon-separated-formaatti
#
# Käyttö:
#    ./jasenmaksu-import-nordea.rb <tilitapahtumat.csv>
#

require "date"
require_relative "settings.rb"
require_relative "userdatabase.rb"

require_relative "helpers.rb"

if ARGV.length != 1
  puts "Usage:"
  puts "  #{$0} <tilitapahtumat.csv>"
  exit 1
end

INPUT = ARGV[0]

$db = UserDatabase.new

def process_payment(summa, viite, maksaja, pvm)
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
      puts "Jäsentä ei löytynyt jäsennumerolla #{jasennro}:  #{pvm}  #{summa}  #{maksaja}  viite: #{viite}"
    end
  else
    puts "Tuntematon viitenumero:  #{pvm}  #{summa}  #{maksaja}  viite: #{viite}"
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
    # Kirjauspäivä;Määrä;Maksaja(tilinro);Maksunsaaja(tilinro);Nimi;Otsikko;Viitenumero;Valuutta
    split = line.split(";", 9)
    if split.length != 8
      puts "Invalid line: #{line}"
      next
    end
    pvm = split[0]
    summa = split[1]
    maksaja = split[5] # maksajan nimi on otsikko-kentässä
    viite = split[6]
    if summa =~ /^-/
      # Payment, not receival
      next
    end
    if process_payment(summa, viite, maksaja, pvm)
      count += 1
    end
  end
end

$db.save

puts "Lisättiin #{count} maksanutta jäsentä."
