--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = flow, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: protocols; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE protocols (
    id integer NOT NULL,
    protocol json NOT NULL
);


ALTER TABLE protocols OWNER TO flowuser;

--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocols_id_seq OWNER TO flowuser;

--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE protocols_id_seq OWNED BY protocols.id;


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Data for Name: protocols; Type: TABLE DATA; Schema: flow; Owner: flowuser
--

COPY protocols (id, protocol) FROM stdin;
1	{ "ipprotocolname": "HOPOPT", "ipprotocolnumber": "0", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2460]"}
2	{ "ipprotocolname": "ICMP", "ipprotocolnumber": "1", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC792]"}
3	{ "ipprotocolname": "IGMP", "ipprotocolnumber": "2", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC1112]"}
4	{ "ipprotocolname": "GGP", "ipprotocolnumber": "3", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC823]"}
5	{ "ipprotocolname": "IPv4", "ipprotocolnumber": "4", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2003]"}
6	{ "ipprotocolname": "ST", "ipprotocolnumber": "5", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC1190][RFC1819]"}
7	{ "ipprotocolname": "TCP", "ipprotocolnumber": "6", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC793]"}
8	{ "ipprotocolname": "CBT", "ipprotocolnumber": "7", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Tony_Ballardie]"}
9	{ "ipprotocolname": "EGP", "ipprotocolnumber": "8", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC888][David_Mills]"}
10	{ "ipprotocolname": "IGP", "ipprotocolnumber": "9", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
11	{ "ipprotocolname": "BBN-RCC-MON", "ipprotocolnumber": "10", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steve_Chipman]"}
12	{ "ipprotocolname": "NVP-II", "ipprotocolnumber": "11", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC741][Steve_Casner]"}
13	{ "ipprotocolname": "PUP", "ipprotocolnumber": "12", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Boggs  D.  J. Shoch  E. Taft  and R. Metcalfe  'PUP: An Internetwork Architecture'  XEROX Palo Alto Research Center  CSL-79-10  July 1979  also in IEEE Transactions on Communication  Volume COM-28  Number 4  April 1980.][[XEROX]]'"}
14	{ "ipprotocolname": "ARGUS (deprecated)", "ipprotocolnumber": "13", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Robert_W_Scheifler]"}
15	{ "ipprotocolname": "EMCON", "ipprotocolnumber": "14", "servicename": "", "portnumber": "", "type": "protocol", "description": "[<mystery contact>]"}
16	{ "ipprotocolname": "XNET", "ipprotocolnumber": "15", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Haverty  J.  'XNET Formats for Internet Protocol Version 4'  IEN 158  October 1980.][Jack_Haverty]'"}
17	{ "ipprotocolname": "CHAOS", "ipprotocolnumber": "16", "servicename": "", "portnumber": "", "type": "protocol", "description": "[J_Noel_Chiappa]"}
18	{ "ipprotocolname": "UDP", "ipprotocolnumber": "17", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC768][Jon_Postel]"}
19	{ "ipprotocolname": "MUX", "ipprotocolnumber": "18", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Cohen  D. and J. Postel  'Multiplexing Protocol'  IEN 90  USC/Information Sciences Institute  May 1979.][Jon_Postel]'"}
20	{ "ipprotocolname": "DCN-MEAS", "ipprotocolnumber": "19", "servicename": "", "portnumber": "", "type": "protocol", "description": "[David_Mills]"}
21	{ "ipprotocolname": "HMP", "ipprotocolnumber": "20", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC869][Bob_Hinden]"}
22	{ "ipprotocolname": "PRM", "ipprotocolnumber": "21", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Zaw_Sing_Su]"}
23	{ "ipprotocolname": "XNS-IDP", "ipprotocolnumber": "22", "servicename": "", "portnumber": "", "type": "protocol", "description": "'['The Ethernet  A Local Area Network: Data Link Layer and Physical Layer Specification'  AA-K759B-TK  Digital Equipment Corporation  Maynard  MA.  Also as: 'The Ethernet - A Local Area Network'  Version 1.0  Digital Equipment Corporation  Intel Corporation  Xerox Corporation  September 1980.  And: 'The Ethernet  A Local Area Network: Data Link Layer and Physical Layer Specifications'  Digital  Intel and Xerox  November 1982.  And: XEROX  'The Ethernet  A Local Area Network: Data Link Layer and Physical Layer Specification'  X3T51/80-50  Xerox Corporation  Stamford  CT.  October 1980.][[XEROX]]'"}
24	{ "ipprotocolname": "TRUNK-1", "ipprotocolnumber": "23", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Barry_Boehm]"}
25	{ "ipprotocolname": "TRUNK-2", "ipprotocolnumber": "24", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Barry_Boehm]"}
26	{ "ipprotocolname": "LEAF-1", "ipprotocolnumber": "25", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Barry_Boehm]"}
27	{ "ipprotocolname": "LEAF-2", "ipprotocolnumber": "26", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Barry_Boehm]"}
28	{ "ipprotocolname": "RDP", "ipprotocolnumber": "27", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC908][Bob_Hinden]"}
29	{ "ipprotocolname": "IRTP", "ipprotocolnumber": "28", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC938][Trudy_Miller]"}
30	{ "ipprotocolname": "ISO-TP4", "ipprotocolnumber": "29", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC905][<mystery contact>]"}
31	{ "ipprotocolname": "NETBLT", "ipprotocolnumber": "30", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC969][David_Clark]"}
32	{ "ipprotocolname": "MFE-NSP", "ipprotocolnumber": "31", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Shuttleworth  B.  'A Documentary of MFENet  a National Computer Network'  UCRL-52317  Lawrence Livermore Labs  Livermore  California  June 1977.][Barry_Howard]'"}
33	{ "ipprotocolname": "MERIT-INP", "ipprotocolnumber": "32", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Hans_Werner_Braun]"}
34	{ "ipprotocolname": "DCCP", "ipprotocolnumber": "33", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC4340]"}
35	{ "ipprotocolname": "3PC", "ipprotocolnumber": "34", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Stuart_A_Friedberg]"}
36	{ "ipprotocolname": "IDPR", "ipprotocolnumber": "35", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Martha_Steenstrup]"}
37	{ "ipprotocolname": "XTP", "ipprotocolnumber": "36", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Greg_Chesson]"}
38	{ "ipprotocolname": "DDP", "ipprotocolnumber": "37", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Wesley_Craig]"}
39	{ "ipprotocolname": "IDPR-CMTP", "ipprotocolnumber": "38", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Martha_Steenstrup]"}
40	{ "ipprotocolname": "TP++", "ipprotocolnumber": "39", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Dirk_Fromhein]"}
41	{ "ipprotocolname": "IL", "ipprotocolnumber": "40", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Dave_Presotto]"}
42	{ "ipprotocolname": "IPv6", "ipprotocolnumber": "41", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2473]"}
43	{ "ipprotocolname": "SDRP", "ipprotocolnumber": "42", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Deborah_Estrin]"}
44	{ "ipprotocolname": "IPv6-Route", "ipprotocolnumber": "43", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steve_Deering]"}
45	{ "ipprotocolname": "IPv6-Frag", "ipprotocolnumber": "44", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steve_Deering]"}
46	{ "ipprotocolname": "IDRP", "ipprotocolnumber": "45", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Sue_Hares]"}
47	{ "ipprotocolname": "RSVP", "ipprotocolnumber": "46", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2205][RFC3209][Bob_Braden]"}
48	{ "ipprotocolname": "GRE", "ipprotocolnumber": "47", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2784][Tony_Li]"}
49	{ "ipprotocolname": "DSR", "ipprotocolnumber": "48", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC4728]"}
50	{ "ipprotocolname": "BNA", "ipprotocolnumber": "49", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Gary Salamon]"}
51	{ "ipprotocolname": "ESP", "ipprotocolnumber": "50", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC4303]"}
52	{ "ipprotocolname": "AH", "ipprotocolnumber": "51", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC4302]"}
53	{ "ipprotocolname": "I-NLSP", "ipprotocolnumber": "52", "servicename": "", "portnumber": "", "type": "protocol", "description": "[K_Robert_Glenn]"}
54	{ "ipprotocolname": "SWIPE (deprecated)", "ipprotocolnumber": "53", "servicename": "", "portnumber": "", "type": "protocol", "description": "[John_Ioannidis]"}
55	{ "ipprotocolname": "NARP", "ipprotocolnumber": "54", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC1735]"}
56	{ "ipprotocolname": "MOBILE", "ipprotocolnumber": "55", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Charlie_Perkins]"}
57	{ "ipprotocolname": "TLSP", "ipprotocolnumber": "56", "servicename": "", "portnumber": "", "type": "protocol", "description": ""}
58	{ "ipprotocolname": "", "ipprotocolnumber": "using Kryptonet key management", "servicename": "", "portnumber": "", "type": "protocol", "description": ""}
59	{ "ipprotocolname": "SKIP", "ipprotocolnumber": "57", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Tom_Markson]"}
60	{ "ipprotocolname": "IPv6-ICMP", "ipprotocolnumber": "58", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2460]"}
61	{ "ipprotocolname": "IPv6-NoNxt", "ipprotocolnumber": "59", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2460]"}
62	{ "ipprotocolname": "IPv6-Opts", "ipprotocolnumber": "60", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2460]"}
63	{ "ipprotocolname": "", "ipprotocolnumber": "61", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
64	{ "ipprotocolname": "CFTP", "ipprotocolnumber": "62", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Forsdick  H.  'CFTP'  Network Message  Bolt Beranek and Newman  January 1982.][Harry_Forsdick]'"}
65	{ "ipprotocolname": "", "ipprotocolnumber": "63", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
66	{ "ipprotocolname": "SAT-EXPAK", "ipprotocolnumber": "64", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
67	{ "ipprotocolname": "KRYPTOLAN", "ipprotocolnumber": "65", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Paul Liu]"}
68	{ "ipprotocolname": "RVD", "ipprotocolnumber": "66", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Michael_Greenwald]"}
69	{ "ipprotocolname": "IPPC", "ipprotocolnumber": "67", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
70	{ "ipprotocolname": "", "ipprotocolnumber": "68", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
71	{ "ipprotocolname": "SAT-MON", "ipprotocolnumber": "69", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
72	{ "ipprotocolname": "VISA", "ipprotocolnumber": "70", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Gene_Tsudik]"}
73	{ "ipprotocolname": "IPCV", "ipprotocolnumber": "71", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
74	{ "ipprotocolname": "CPNX", "ipprotocolnumber": "72", "servicename": "", "portnumber": "", "type": "protocol", "description": "[David Mittnacht]"}
75	{ "ipprotocolname": "CPHB", "ipprotocolnumber": "73", "servicename": "", "portnumber": "", "type": "protocol", "description": "[David Mittnacht]"}
76	{ "ipprotocolname": "WSN", "ipprotocolnumber": "74", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Victor Dafoulas]"}
77	{ "ipprotocolname": "PVP", "ipprotocolnumber": "75", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steve_Casner]"}
78	{ "ipprotocolname": "BR-SAT-MON", "ipprotocolnumber": "76", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
79	{ "ipprotocolname": "SUN-ND", "ipprotocolnumber": "77", "servicename": "", "portnumber": "", "type": "protocol", "description": "[William_Melohn]"}
80	{ "ipprotocolname": "WB-MON", "ipprotocolnumber": "78", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
81	{ "ipprotocolname": "WB-EXPAK", "ipprotocolnumber": "79", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Steven_Blumenthal]"}
82	{ "ipprotocolname": "ISO-IP", "ipprotocolnumber": "80", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Marshall_T_Rose]"}
83	{ "ipprotocolname": "VMTP", "ipprotocolnumber": "81", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Dave_Cheriton]"}
84	{ "ipprotocolname": "SECURE-VMTP", "ipprotocolnumber": "82", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Dave_Cheriton]"}
85	{ "ipprotocolname": "VINES", "ipprotocolnumber": "83", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Brian Horn]"}
86	{ "ipprotocolname": "TTP", "ipprotocolnumber": "84", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Jim_Stevens]"}
87	{ "ipprotocolname": "IPTM", "ipprotocolnumber": "84", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Jim_Stevens]"}
88	{ "ipprotocolname": "NSFNET-IGP", "ipprotocolnumber": "85", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Hans_Werner_Braun]"}
89	{ "ipprotocolname": "DGP", "ipprotocolnumber": "86", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[M/A-COM Government Systems  'Dissimilar Gateway Protocol Specification  Draft Version'  Contract no. CS901145  November 16  1987.][Mike_Little]'"}
90	{ "ipprotocolname": "TCF", "ipprotocolnumber": "87", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Guillermo_A_Loyola]"}
91	{ "ipprotocolname": "EIGRP", "ipprotocolnumber": "88", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC7868]"}
92	{ "ipprotocolname": "OSPFIGP", "ipprotocolnumber": "89", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC1583][RFC2328][RFC5340][John_Moy]"}
93	{ "ipprotocolname": "Sprite-RPC", "ipprotocolnumber": "90", "servicename": "", "portnumber": "", "type": "protocol", "description": "'[Welch  B.  'The Sprite Remote Procedure Call System'  Technical Report  UCB/Computer Science Dept.  86/302  University of California at Berkeley  June 1986.][Bruce Willins]'"}
94	{ "ipprotocolname": "LARP", "ipprotocolnumber": "91", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Brian Horn]"}
95	{ "ipprotocolname": "MTP", "ipprotocolnumber": "92", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Susie_Armstrong]"}
96	{ "ipprotocolname": "AX.25", "ipprotocolnumber": "93", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Brian_Kantor]"}
97	{ "ipprotocolname": "IPIP", "ipprotocolnumber": "94", "servicename": "", "portnumber": "", "type": "protocol", "description": "[John_Ioannidis]"}
98	{ "ipprotocolname": "MICP (deprecated)", "ipprotocolnumber": "95", "servicename": "", "portnumber": "", "type": "protocol", "description": "[John_Ioannidis]"}
99	{ "ipprotocolname": "SCC-SP", "ipprotocolnumber": "96", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Howard_Hart]"}
100	{ "ipprotocolname": "ETHERIP", "ipprotocolnumber": "97", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3378]"}
101	{ "ipprotocolname": "ENCAP", "ipprotocolnumber": "98", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC1241][Robert_Woodburn]"}
102	{ "ipprotocolname": "", "ipprotocolnumber": "99", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
103	{ "ipprotocolname": "GMTP", "ipprotocolnumber": "100", "servicename": "", "portnumber": "", "type": "protocol", "description": "[[RXB5]]"}
104	{ "ipprotocolname": "IFMP", "ipprotocolnumber": "101", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Bob_Hinden][November 1995  1997.]"}
105	{ "ipprotocolname": "PNNI", "ipprotocolnumber": "102", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Ross_Callon]"}
106	{ "ipprotocolname": "PIM", "ipprotocolnumber": "103", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC7761][Dino_Farinacci]"}
107	{ "ipprotocolname": "ARIS", "ipprotocolnumber": "104", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Nancy_Feldman]"}
108	{ "ipprotocolname": "SCPS", "ipprotocolnumber": "105", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Robert_Durst]"}
109	{ "ipprotocolname": "QNX", "ipprotocolnumber": "106", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Michael_Hunter]"}
110	{ "ipprotocolname": "A/N", "ipprotocolnumber": "107", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Bob_Braden]"}
111	{ "ipprotocolname": "IPComp", "ipprotocolnumber": "108", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC2393]"}
112	{ "ipprotocolname": "SNP", "ipprotocolnumber": "109", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Manickam_R_Sridhar]"}
113	{ "ipprotocolname": "Compaq-Peer", "ipprotocolnumber": "110", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Victor_Volpe]"}
114	{ "ipprotocolname": "IPX-in-IP", "ipprotocolnumber": "111", "servicename": "", "portnumber": "", "type": "protocol", "description": "[CJ_Lee]"}
115	{ "ipprotocolname": "VRRP", "ipprotocolnumber": "112", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC5798]"}
116	{ "ipprotocolname": "PGM", "ipprotocolnumber": "113", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Tony_Speakman]"}
117	{ "ipprotocolname": "", "ipprotocolnumber": "114", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
118	{ "ipprotocolname": "L2TP", "ipprotocolnumber": "115", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3931][Bernard_Aboba]"}
119	{ "ipprotocolname": "DDX", "ipprotocolnumber": "116", "servicename": "", "portnumber": "", "type": "protocol", "description": "[John_Worley]"}
120	{ "ipprotocolname": "IATP", "ipprotocolnumber": "117", "servicename": "", "portnumber": "", "type": "protocol", "description": "[John_Murphy]"}
121	{ "ipprotocolname": "STP", "ipprotocolnumber": "118", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Jean_Michel_Pittet]"}
122	{ "ipprotocolname": "SRP", "ipprotocolnumber": "119", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Mark_Hamilton]"}
123	{ "ipprotocolname": "UTI", "ipprotocolnumber": "120", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Peter_Lothberg]"}
124	{ "ipprotocolname": "SMP", "ipprotocolnumber": "121", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Leif_Ekblad]"}
125	{ "ipprotocolname": "SM (deprecated)", "ipprotocolnumber": "122", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Jon_Crowcroft][draft-perlman-simple-multicast]"}
126	{ "ipprotocolname": "PTP", "ipprotocolnumber": "123", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Michael_Welzl]"}
127	{ "ipprotocolname": "ISIS over IPv4", "ipprotocolnumber": "124", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Tony_Przygienda]"}
128	{ "ipprotocolname": "FIRE", "ipprotocolnumber": "125", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Criag_Partridge]"}
129	{ "ipprotocolname": "CRTP", "ipprotocolnumber": "126", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Robert_Sautter]"}
130	{ "ipprotocolname": "CRUDP", "ipprotocolnumber": "127", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Robert_Sautter]"}
131	{ "ipprotocolname": "SSCOPMCE", "ipprotocolnumber": "128", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Kurt_Waber]"}
132	{ "ipprotocolname": "IPLT", "ipprotocolnumber": "129", "servicename": "", "portnumber": "", "type": "protocol", "description": "[[Hollbach]]"}
133	{ "ipprotocolname": "SPS", "ipprotocolnumber": "130", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Bill_McIntosh]"}
134	{ "ipprotocolname": "PIPE", "ipprotocolnumber": "131", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Bernhard_Petri]"}
135	{ "ipprotocolname": "SCTP", "ipprotocolnumber": "132", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Randall_R_Stewart]"}
136	{ "ipprotocolname": "FC", "ipprotocolnumber": "133", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Murali_Rajagopal][RFC6172]"}
137	{ "ipprotocolname": "RSVP-E2E-IGNORE", "ipprotocolnumber": "134", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3175]"}
138	{ "ipprotocolname": "Mobility Header", "ipprotocolnumber": "135", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC6275]"}
139	{ "ipprotocolname": "UDPLite", "ipprotocolnumber": "136", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3828]"}
140	{ "ipprotocolname": "MPLS-in-IP", "ipprotocolnumber": "137", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC4023]"}
141	{ "ipprotocolname": "manet", "ipprotocolnumber": "138", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC5498]"}
142	{ "ipprotocolname": "HIP", "ipprotocolnumber": "139", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC7401]"}
143	{ "ipprotocolname": "Shim6", "ipprotocolnumber": "140", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC5533]"}
144	{ "ipprotocolname": "WESP", "ipprotocolnumber": "141", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC5840]"}
145	{ "ipprotocolname": "ROHC", "ipprotocolnumber": "142", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC5858]"}
146	{ "ipprotocolname": "", "ipprotocolnumber": "143-252", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
147	{ "ipprotocolname": "", "ipprotocolnumber": "253", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3692]"}
148	{ "ipprotocolname": "", "ipprotocolnumber": "254", "servicename": "", "portnumber": "", "type": "protocol", "description": "[RFC3692]"}
149	{ "ipprotocolname": "Reserved", "ipprotocolnumber": "255", "servicename": "", "portnumber": "", "type": "protocol", "description": "[Internet_Assigned_Numbers_Authority]"}
\.


--
-- Name: protocols_id_seq; Type: SEQUENCE SET; Schema: flow; Owner: flowuser
--

SELECT pg_catalog.setval('protocols_id_seq', 149, true);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

