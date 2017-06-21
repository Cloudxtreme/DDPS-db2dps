

1	læs alle felter og afgør om
		felt = -1 | værdi | liste-af-værdier
		idet liste-af-værdier er en top 10 hvor top 10 udgør mere end 25 %
		og -1 repræsenterer 'null' dvs. at feltet ikke kan anvendes til at
		lave regler med (0 er et valid port nummer)

2	er forbindelsen state full eller state less

2.1	state full:

	blokker src + evt. andre felter, stop

2.2	state less:

	(et større arbejde)

2.2.1	

	er længde = 64 bytes -- blokker, stop

2.2.2

	er det hverken udp eller tcp -- blokker, stop (icmp, gre, osv)

2.2.3

	Nu er der kun udp og tcp tilbage, begge i tilstandsløs udgave

2.2.4.1

	Er det udp fragmenter så blokker dém, stop

2.2.4.2

	Er det udp trafik til andet end dns, ntp og evt. andre velkendte porte så blokker, stop

2.2.4.3

	Er det tcp *fragmenter* med tcp flags så blokker dém, stop

	er det udp og er længde != -1 og længde ens så brug længde ved blokkering, 

	herfra svært




