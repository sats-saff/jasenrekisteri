#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'date'
require_relative 'settings.rb'
require_relative 'userdatabase.rb'

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


puts "Provide Kapsi password to send emails or empty to print messages."
email_password = ask("Kapsi password:  ") { |q| q.echo = false }
TEST = (email_password == "")


db = UserDatabase.new

if !TEST
  require 'mail'
  options = { :address              => "mail.kapsi.fi",
	    :port                 => 587,
	    :domain               => 'kapsi.fi',
	    :user_name            => 'sats',
	    :password             => email_password,
	    :authentication       => 'plain',
	    :enable_starttls_auto => true  }
  Mail.defaults do
    delivery_method :smtp, options
  end
end

db.users.each do |user|

#  next unless user["sahkoposti"] == "valtteri.maja@gmail.com" || user["sahkoposti"] == "timo.toivanen@iki.fi"


  # Valitse vain henkilöjäsenet
  jasenluokka = JASENLUOKAT[user["jasenluokka"]]
  jasenmaksu = JASENMAKSUT[user["jasenluokka"]]
  puts "Jasenluokka puuttuu: #{user["sukunimi"]}" unless jasenluokka  
  next unless jasenluokka

  # Vain käyttäjät joilla on sähköpostiosoite
  email = user["sahkoposti"]
  puts "Sähköposti puuttuu: #{user["sukunimi"]}" unless email != ""
  next unless email != ""

  # Poista käyttäjät jotka ovat maksaneet
  puts "On jo maksanut: #{user["sukunimi"]}" if user["2014:maksanut"] != ""
  next if user["2014:maksanut"] != ""

  # Select proper name (first+last or last)
  etunimi = user["etunimi"]
  sukunimi = user["sukunimi"]
  osoite1 = user["osoite1"]
  osoite2 = user["osoite2"]
  postinro = user["postinro"]
  postitmi = user["postitoimipaikka"]
  maa = user["maa"]

  # Luo viitenumero
  viitenro = viitenumero(user["jasennro"].to_i * 10000 + 2014)

  # Generate email
  email_subject = "SATS jäsenmaksu 2014"
  email_from = "sats@kapsi.fi"
  email_to = email
  msg = <<-eos

Hei,

Tässä on Suomen avaruustutkimusseura ry:n vuoden 2014 jäsenmaksulasku.  Ole hyvä ja maksa lasku alla olevien tietojen mukaan.

Jos olet mielestäsi jo maksanut tämän vuoden jäsenmaksun tai laskussa on muuta epäselvyyttä, ole hyvä ja ota yhteyttä.

Tarkista samalla yhteystietosi.  Voit ilmoittaa muuttuneista yhteystiedoista vastaamalla tähän viestiin.

eos

  if (user["rakettistatus"] != "") && (user["rakettistatus"] != "J")
    msg += <<-eos
HUOM!  Rakettikortit postitetaan ainoastaan jäsenille, jotka ovat maksaneet jäsenmaksun.

eos
  end

  msg += <<-eos

Jäsenluokka:  #{jasenluokka}
Jäsenmaksu:   #{jasenmaksu} €  (ALV 0%)
Saaja:        Suomen avaruustutkimusseura ry
Tilinumero:   FI81 2185 1800 1292 32
BIC/SWIFT:    NDEAFIHH
Viimenumero:  #{viitenro}
Eräpäivä:     3.10.2014



Yhteystietosi jäsenrekisterissä:

Postiosoite:
  #{sukunimi}
  #{osoite1}#{"\n  #{osoite2}" if osoite2 != ""}
  #{postinro} #{postitmi}
  #{maa}

Sähköpostiosoite:
  #{email}


Ystävällisin terveisin,

  Suomen avaruustutkimusseura ry
  Sällskapet för Astronautisk Forskning i Finland rf
  http://www.sats-saff.fi/

eos

  if user["2014:laskutettu"] != ""
    puts "Lasku on jo lähetetty käyttäjälle #{email}: #{user["2014:laskutettu"]}"
    puts "Lähetänkö uudestaan (y/N)?"
    next unless gets.start_with?("y")
  end


  if TEST
    puts "--------------------------------------------------------------------------"
    puts "To: #{email}"
    puts "Subject: #{email_subject}"
    puts "From: #{email_from}"
    puts msg
  else
    puts "Sending to #{email}..."
    Mail.deliver do
           to email
         from email_from
      subject email_subject
         body msg
    end
    user["2014:laskutettu"] = "email #{DateTime.now.strftime("%Y-%m-%d")}"
    db.save
  end

end

