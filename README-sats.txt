
Tilitapahtumien ajaminen sisään
-------------------------------

Lataa Nordeasta CSV-muodossa tilitapahtumat halutulle jaksolle (edellisen loppumisesta).

  ./jasenmaksu-import-nordea.rb tilitapahtumat/Tapahtumat_FIxxxxxx_xxxxxx.txt

Katso läpi tulostus ja merkitse loput käsin.



Ensimmäinen jäsenmaksulaskutus
------------------------------

Aja sisään maksetut jäsenmaksut.


./jasenlaskutus-email.rb sats/sahkopostilasku.erb

  - testaile ensin tyhjällä salasanalla
  - aja sitten Kapsin salasanan kera


./jasenlaskutus-paperi.rb sats/paperilasku.erb laskut.html

  - testaile ja varmista laskujen oikeellisuus
  - varmista ettei laskua lähde henkilöille joilla on sähköpostiosoite
  - sitten aja (merkkaa laskutetuksi):

    ./jasenlaskutus-paperi.rb sats/paperilasku.erb laskut.html true



Muistutuslaskutus
-----------------

Aja sisään maksetut jäsenmaksut.

Muokkaa jasenlaskutus-paperi.rb funktiota include_user, sisällytä
käyttäjät joilla on sähköpostiosoite.

Luo paperilaskut aivan kuten yllä (samaa templatea käyttäen).





