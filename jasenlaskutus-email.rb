#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Lähettää jäsenlaskut sähköpostilla.
#
# Lue skripti läpi ja tarkista toimintalogiikka!!!
#
# Käyttö:
#    ./jasenlaskutus-email.rb <email.erb> [emails...]
#


if ARGV.length < 1
  puts "Usage:"
  puts "  #{$0} <email.erb> [emails...]"
  exit 1
end


require 'date'
require 'highline/import'
require_relative 'settings.rb'
require_relative 'userdatabase.rb'

require_relative 'helpers.rb'


LIMIT_EMAILS = ARGV.clone
LIMIT_EMAILS.shift



# Yhteiset osat sähköposti + paperilaskuille:
require_relative 'jasenlaskutus-common-variables'


# Select which users to include.  Return true to include the user.
def include_user(user)

  # Komentorivillä mainitut käyttäjät
  return false unless LIMIT_EMAILS.empty? || LIMIT_EMAILS.include?(user.email)

  # Hylkää käyttäjät, jotka eivät maksa henkilöjäsenmaksua
  return false if not LASKUTETAVAT_JASENLUOKAT.include?(user["jasenluokka"])

  # Hylkää käyttäjät, joilla ei ole sähköpostiosoitetta
  puts "Ei sähköpostiosoitetta: #{user.nimi}" if (user.email == nil)
  return false if (user.email == nil)

  # Hylkää käyttäjät, joille on jo lähetetty tänä vuonna jäsenmaksulasku
  laskutettu = user.laskutettu?(CURRENT_YEAR)
  puts "On jo laskutettu tänä vuonna: #{user.nimi}" if laskutettu
  return false if laskutettu

  # Poista käyttäjät jotka ovat maksaneet
  maksanut = (user.maksanut?(CURRENT_YEAR) || user.maksanut?(CURRENT_YEAR+1))
  puts "On jo maksanut: #{user.nimi}" if maksanut
  return false if maksanut

  return true
end


# Return a string to set to the "sent" status.  nil for setting nothing.
def mark_sent(user)
  return "email #{LASKUPV}"
end


#############################################################################


INPUT = ARGV[0]
TEMPLATE = IO.read(INPUT)

puts "Provide Kapsi password to send emails (or empty to print messages to stdout)."
email_password = ask("Kapsi password:  ") { |q| q.echo = false }
TEST = (email_password == "")



class UserErb
  include ERB::Util
  attr_accessor :user, :template

  def initialize(template)
    @user = {}
    @template = template
  end

  def render()
    ERB.new(@template).result(binding)
  end
end


db = UserDatabase.new

if !TEST
  require 'mail'
  options = {
            :address              => "mail.kapsi.fi",
	    :port                 => 587,
	    :domain               => 'kapsi.fi',
	    :user_name            => 'sats',
	    :password             => email_password,
	    :authentication       => 'login',
	    :enable_starttls_auto => true
  }
  Mail.defaults do
    delivery_method :smtp, options
  end
end

count = 0
db.users.each do |user|

  next if not include_user(user)

  u = generate_variables(user)
  erb = UserErb.new(TEMPLATE)
  erb.user = u


  # Generate email
  email_subject = "SATS jäsenmaksu #{CURRENT_YEAR}"
  email_from = "Suomen avaruustutkimusseura ry <sats@kapsi.fi>"
  email_to = "#{u[:nimi]} <#{u[:email]}>"
  email_msg = erb.render


  if TEST
    puts "--------------------------------------------------------------------------"
    puts "To: #{email_to}"
    puts "Subject: #{email_subject}"
    puts "From: #{email_from}"
    puts email_msg
  else
    puts "Sending to #{email_to}..."
    Mail.deliver do
           to email_to
         from email_from
      subject email_subject
         body email_msg
    end

    txt = mark_sent(user)
    if txt
      user["#{CURRENT_YEAR}:laskutettu"] = txt
      db.save
    end
  end

  count += 1
end

puts "Processed #{count} bills"
