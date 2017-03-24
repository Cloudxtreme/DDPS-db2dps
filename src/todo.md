
I morgen :

fnm2db skal ikke længere aflevere nye regler via et indlejret sql script, men
i stedet for som et dokument (sftp) se f.eks.

  - [limiting access with sftp jail](https://www.linode.com/docs/tools-reference/tools/limiting-access-with-sftp-jails-on-debian-and-ubuntu)
  - [openssh restrict to sftp chroot](https://passingcuriosity.com/2014/openssh-restrict-to-sftp-chroot/)
  - [restrict sftp user home](http://www.tecmint.com/restrict-sftp-user-home-directories-using-chroot/)

Bemærk finten med root som ejer af /home.

Upload dokument skal 

  - indeholde alle 12 felter fyldt ud med noget + start og sluttid
  - sidste linje skal indeholde 12 + 2 felter alle med f.eks. "last-line"

db2dps.pl skal i main loop før db forespørgslen (omkring dér hvor der alligevel
testes for noget i filsystemet teste om der er nye regler der skal
implementeres.

Filen læses, kontrolleres for fejl og reglerne tilføjes regelbasen hvis alt er ok. Derefter slettes den.

Upload bruger: newrules, restricted osv.
Homedir:       F.eks. /opt/db2dps/autorules/ {newrules, ... } ?

Resten af db2dps.pl er uændret.

Når det er testet oprettes en sftp bruger og fnm2db rettes.



# TODO

Perl version:

  - see TODO in db2dps.pl
  - add mynetworks = 95. .... ... ... ... 57.0/24
    to db.ini
  - match src and dst against mynetworks and fail if no match

DB:

  - add "customer" i2.dk with ``erhvervsnet`` addresses
  - add "customer" deic.dk with ``forskningsnet`` addresses
  - start with development DB 95.128.24.0/21, 130.225.0.0/16, 130.226.0.0/16, 192.38.0.0/17 and 185.1.57.0/24
  - erhvs network: 130.226.248.0/21

