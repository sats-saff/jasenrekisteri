#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Luo HTML-tiedoston, josta voi tulostaa paperiset jäsenmaksulaskut.
#
# Lue skripti läpi ja tarkista toimintalogiikka!!!
#
# Käyttö:
#    ./jasenlaskutus-paperi.rb <paperilasku.erb> <output.html> [true - merkitse laskutetuksi]
#

require 'date'
require_relative 'settings.rb'
require_relative 'userdatabase.rb'
require 'erb'

require_relative 'helpers.rb'


# Yhteiset osat sähköposti + paperilaskuille:
require_relative 'jasenlaskutus-common-variables'


# Select which users to include.  Return true to include the user.
def include_user(user)

  # Hylkää käyttäjät, jotka eivät maksa henkilöjäsenmaksua
  return false if not JASENLUOKAT[user["jasenluokka"]]

  # Hylkää käyttäjät, joilla on sähköpostiosoite
  return false if (user.email != nil)

  # Poista käyttäjät jotka ovat maksaneet
  maksanut = (user.maksanut?(CURRENT_YEAR) || user.maksanut?(CURRENT_YEAR+1))
  puts "On jo maksanut: #{user.nimi}" if maksanut
  return false if maksanut

  return true
end


# Return a string to set to the "sent" status.  nil for setting nothing.
def mark_sent(user)
  if MARK_CHARGED
    "paperi #{LASKUPV}"
  else
    nil
  end
end




#############################################################################



if ARGV.length != 2 && ARGV.length != 3
  puts "Usage:"
  puts "  #{$0} <paperi.erb> <output.html>"
  exit 1
end

INPUT = ARGV[0]
OUTPUT = ARGV[1]
MARK_CHARGED = (ARGV[2] == "true")

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



db.users.each do |user|

  next if not include_user(user)

  u = generate_variables(user)
  userlist.users.push u
  
  txt = mark_sent(user)
  if txt
    current = user["#{CURRENT_YEAR}:laskutettu"]
    if current && current.length > 0
      txt = "#{current}; #{txt}"
    end
    user["#{CURRENT_YEAR}:laskutettu"] = txt
  end

end

userlist.save(OUTPUT)
puts "Luotiin #{userlist.users.length} laskua."

db.save

