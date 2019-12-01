
# Generate the variables for use in the template.  Return a hash.
def generate_variables(user)
  jasenluokka = JASENLUOKAT[user["jasenluokka"]]
  jasenmaksu = JASENMAKSUT[user["jasenluokka"]]

  email = user.email

  nimi = user.nimi
  osoite1 = user["osoite1"]
  osoite2 = user["osoite2"]
  postinro = user["postinro"]
  postitmi = user["postitoimipaikka"]
  maa = user["maa"]

  osoite2 = nil if osoite2 == ""
  maa = nil if maa == ""

  # Tarkista maksetaanko kuluvan vai kuluvan ja seuraavan vuoden jäsenmaksu
  if user.maksaa?(CURRENT_YEAR)
    jmaksu_vuosi = CURRENT_YEAR
    jmaksu_vuosi_info = "#{CURRENT_YEAR}"
    juuri_liittynyt = false
  else
    jmaksu_vuosi = CURRENT_YEAR + 1
    jmaksu_vuosi_info = "#{CURRENT_YEAR} - #{CURRENT_YEAR+1}"
    juuri_liittynyt = true
  end

  # Luo viitenumero
  viitenro = viitenumero(user["jasennro"].to_i * 10000 + jmaksu_vuosi)

  # Tarkista maksut
  laskutettava = []
  laskutettava_yhteensa = 0
  edellisvuosi_maksamatta = nil
  if !user.maksanut?(CURRENT_YEAR-1) && user.maksaa?(CURRENT_YEAR-1)
    laskutettava.push({
      laskutettava: "Jäsenmaksu #{CURRENT_YEAR-1} (#{jasenluokka})",
      summa: "#{jasenmaksu} €"
    })
    laskutettava_yhteensa += jasenmaksu
    edellisvuosi_maksamatta = true
  end
  laskutettava.push({
    laskutettava: "Jäsenmaksu #{jmaksu_vuosi_info} (#{jasenluokka})",
    summa: "#{jasenmaksu} €"
  })
  laskutettava_yhteensa += jasenmaksu


  # Luo hash käyttäjän tiedoista erb:tä varten
  {
    laskutettava: laskutettava,
    laskutettava_yhteensa: laskutettava_yhteensa,
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
    edellisvuosi_maksamatta: edellisvuosi_maksamatta,
    viitenro: viitenro,
    laskupv: LASKUPV,
    erapv: ERAPV,
  }
end



LASKUTETAVAT_JASENLUOKAT = ["V","O","N"]
JASENLUOKAT = {
  "V" => "Varsinainen jäsen",
  "O" => "Opiskelijajäsen",
  "N" => "Nuorisojäsen (alle 18v)",
  "A" => "Ainaisjäsen",
  "K" => "Kunniajäsen",
  "Y" => "Yritys- / yhteisöjäsen"
}
JASENMAKSUT = {
  "V" => 28,
  "O" => 14,
  "N" => 10,
  "A" => 0,
  "K" => 0,
  "Y" => 280
}

CURRENT_YEAR = Time.now.year

# Laskun päivämäärä on tänään
pv = Time.now
LASKUPV = "#{pv.day}.#{pv.month}.#{pv.year}"


# Eräpäivä on 2 viikon päästä seuraava maanantai
pv = Time.now + 14*24*60*60
while not pv.monday?
  pv += 24*60*60
end
ERAPV = "#{pv.day}.#{pv.month}.#{pv.year}"
