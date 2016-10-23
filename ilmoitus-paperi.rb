#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Luo HTML-tiedoston, josta voi tulostaa paperiset ilmoitukset jäsenistölle.
#
# Lue skripti läpi ja tarkista toimintalogiikka!!!
#
# Käyttö:
#    ./paperi-ilmoitus.rb <paperi.erb> <output.html>
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

  # Hylkää lehtitilaajat
  if user["jasenluokka"] == "LT" or user["jasenluokka"] == "VK"
    return false
  end
  
  return true
end




#############################################################################



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



db.users.each do |user|

  next if not include_user(user)

  u = generate_variables(user)
  userlist.users.push u
  
end

userlist.save(OUTPUT)
puts "Luotiin #{userlist.users.length} laskua."

db.save

