#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Tulostaa käyttäjät, jotka eivät ole maksaneet kahden peräkkäisen
# vuoden jäsenmaksua.
#
# Käyttö:
#    ./irtisanottavat.rb 2015
# 
#    -->  tulostaa jäsenet, jotka eivät ole maksaneet 2014 eikä 2015
#

require_relative 'settings.rb'
require_relative 'userdatabase.rb'

vuosi2 = ARGV[0].to_i
vuosi1 = vuosi2 - 1

db = UserDatabase.new
JASENLUOKAT = [ "V", "O", "N", "J" ]

skipped = 0
uudet = 0
laskuttamatta = 0
erotettava = 0

db.users.each do |user|
  
  # Vain käyttäjät määritellyissä jäsenluokissa
  if not JASENLUOKAT.include?(user["jasenluokka"])
    skipped += 1
    next
  end
  


  if user["#{vuosi1}:maksanut"] == "" && user["#{vuosi2}:maksanut"] == ""
    # Tarkista olisiko jäsenen pitänyt maksaa kummankin vuoden jäsenmaksu
    if !(user.maksaa?(vuosi1) && user.maksaa?(vuosi2))
      uudet += 1
      next
    end
    # Tarkista onko laskua lähetetty kyseisinä vuosina
    if user["#{vuosi1}:laskutettu"] == "" && user["#{vuosi2}:laskutettu"] == ""
      laskuttamatta += 1
      next
    end
    puts "#{user.nimi} <#{user["sahkoposti"]}>"
    erotettava += 1
  end

end

puts
puts "#{erotettava} jäsentä, jotka eivät ole maksaneet laskua vuosina #{vuosi1} eikä #{vuosi2}"
puts "#{uudet} jäsentä, jotka ovat uusia eivätkä ole joutuneet maksamaan kummankin vuoden maksua"
puts "#{laskuttamatta} jäsentä, joille ei ole lähetetty laskua eivätkä maksaneet vuosina #{vuosi1} eikä #{vuosi2}"
puts "#{skipped} jäsentä muissa jäsenluokissa kuin #{JASENLUOKAT}"

