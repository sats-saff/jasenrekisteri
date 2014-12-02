#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Luo HTML-tiedoston, josta voi tulostaa paperiset jäsenmaksulaskut.
#
# Lue skripti läpi ja tarkista toimintalogiikka!!!
#
# Käyttö:
#    ./jasenlaskutus-paperi.rb <paperilasku.erb> <output.html>
#

require 'date'
require_relative 'settings.rb'
require_relative 'userdatabase.rb'
require 'erb'

require_relative 'helpers.rb'

JASENLUOKAT = {
  "V" => "Varsinainen jäsen",
  "O" => "Opiskelijajäsen",
  "N" => "Nuorisojäsen (alle 18v)",
  "J" => "Juniorijäsen (alle 15v)"
}
JASENMAKSUT = {
  "V" => 28,
  "O" => 14,
  "N" => 14,
  "J" => 10
}

if ARGV.length != 2
  puts "Usage:"
  puts "  #{$0} <paperi.erb> <output.html>"
  exit 1
end

INPUT = ARGV[0]
OUTPUT = ARGV[1]


class UserList
  include ERB::Util
  attr_accessor :users, :template

  def initialize(template)
    @users = []
    @template = template
  end

  def render()
    ERB.new(@template).result(binding)
  end

  def save(file)
    File.open(file, "w+") do |f|
      f.write(render)
    end
  end
end

userlist = UserList.new(IO.read(INPUT))
db = UserDatabase.new
vuosi_nyt = Time.now.year


# Laskun päivämäärä on tänään
laskupv = Time.now
laskupv = "#{laskupv.day}.#{laskupv.month}.#{laskupv.year}"


# Eräpäivä on 2 viikon päästä seuraava maanantai
erapv = Time.now + 14*24*60*60
while erapv.saturday? or erapv.sunday?
  erapv += 24*60*60
end
erapv = "#{erapv.day}.#{erapv.month}.#{erapv.year}"



db.users.each do |user|

#  next unless user["sahkoposti"] == "valtteri.maja@gmail.com" || user["sahkoposti"] == "timo.toivanen@iki.fi"

  u = {}

  # Valitse vain henkilöjäsenet
  jasenluokka = JASENLUOKAT[user["jasenluokka"]]
  jasenmaksu = JASENMAKSUT[user["jasenluokka"]]
  puts "Jasenluokka ei valituissa '#{user["jasenluokka"]}': #{user["sukunimi"]}" unless jasenluokka  
  next unless jasenluokka

  # Valitse vain käyttäjät joilla ei ole sähköpostiosoitetta TAI jotka eivät ole maksaneet kuluvan tai ensi vuoden jäsenmaksua
  email = user["sahkoposti"]
  email = nil if email == ""
  #puts "Sähköposti on: #{user["sukunimi"]}" if email != ""
  #next if email != ""

  # Poista käyttäjät jotka ovat maksaneet
  maksanut = (user["#{vuosi_nyt}:maksanut"] != "" || user["#{vuosi_nyt+1}:maksanut"] != "")
  puts "On jo maksanut: #{user["sukunimi"]}" if maksanut
  next if maksanut

  # Select proper name (first+last or last)
  nimi = user.nimi
  osoite1 = user["osoite1"]
  osoite2 = user["osoite2"]
  postinro = user["postinro"]
  postitmi = user["postitoimipaikka"]
  maa = user["maa"]
  
  osoite2 = nil if osoite2 == ""
  maa = nil if maa == ""

  # Tarkista maksetaanko kuluvan vai kuluvan ja seuraavan vuoden jäsenmaksu
  limit = "#{vuosi_nyt}-10-01"
  if user["liittymispvm"] >= limit
    jmaksu_vuosi = vuosi_nyt + 1
    jmaksu_vuosi_info = "#{vuosi_nyt} - #{vuosi_nyt+1}"
  else
    jmaksu_vuosi = vuosi_nyt
    jmaksu_vuosi_info = "#{vuosi_nyt}"
  end  

  # Luo viitenumero
  viitenro = viitenumero(user["jasennro"].to_i * 10000 + jmaksu_vuosi)


#  if user["2014:laskutettu"] != ""
#    puts "Lasku on jo lähetetty käyttäjälle #{email}: #{user["2014:laskutettu"]}"
#    puts "Tuotetaanko uudestaan (y/N)?"
#    next unless gets.start_with?("y")
#  end


  # Luo hash käyttäjän tiedoista erb:tä varten
  u = {
    laskutettava: [
      {
        laskutettava: "Jäsenmaksu #{jmaksu_vuosi_info} (#{jasenluokka})",
        summa: "#{jasenmaksu} €"
      }
    ],
    jasenluokka: jasenluokka,
    jasenmaksu: jasenmaksu,
    nimi: nimi,
    osoite1: osoite1,
    osoite2: osoite2,
    postinro: postinro,
    postitmi: postitmi,
    maa: maa,
    email: email,
    jmaksu_vuosi: jmaksu_vuosi_info,
    viitenro: viitenro,
    laskupv: laskupv,
    erapv: erapv
  }
  userlist.users.push u

end

userlist.save(OUTPUT)
puts "Luotiin #{userlist.users.length} laskua."

