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
-- Name: icmp_types; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE icmp_types (
    id integer NOT NULL,
    icmp json NOT NULL
);


ALTER TABLE icmp_types OWNER TO flowuser;

--
-- Name: icmp_types_id_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE icmp_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE icmp_types_id_seq OWNER TO flowuser;

--
-- Name: icmp_types_id_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE icmp_types_id_seq OWNED BY icmp_types.id;


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_types ALTER COLUMN id SET DEFAULT nextval('icmp_types_id_seq'::regclass);


--
-- Data for Name: icmp_types; Type: TABLE DATA; Schema: flow; Owner: flowuser
--

COPY icmp_types (id, icmp) FROM stdin;
1	{"type": "0", "name":\t"Echo Reply", "reference": "[RFC792]" }
2	{"type": "1", "name": "Unassigned", "reference": "[JBP]" }
3	{"type": "2", "name": "Unassigned", "reference": "[JBP]" }
4	{"type": "3", "name": "Destination Unreachable", "reference": "[RFC792]" }
5	{"type": "4", "name": "Source Quench", "reference": " [RFC792]" }
6	{"type": "5", "name": "Redirect", "reference": "[RFC792]" }
7	{"type": "6", "name": "Alternate Host Address", "reference": " [JBP]" }
8	{"type": "7", "name": "Unassigned", "reference": " [JBP]" }
9	{"type": "8", "name": "Echo", "reference": "[RFC792]" }
10	{"type": "9", "name": "Router Advertisement", "reference": "[RFC1256]" }
11	{"type": "10", "name": "Router Selection", "reference": "[RFC1256]" }
12	{"type": "11", "name": "Time Exceeded", "reference": "[RFC792]" }
13	{"type": "12", "name": "Parameter Problem", "reference": "[RFC792]" }
14	{"type": "13", "name": "Timestamp", "reference": "[RFC792]" }
15	{"type": "14", "name": "Timestamp Reply", "reference": "[RFC792]" }
16	{"type": "15", "name": "Information Request", "reference": "[RFC792]" }
17	{"type": "16", "name": "Information Reply", "reference": "[RFC792]" }
18	{"type": "17", "name": "Address Mask Request", "reference": " [RFC950]" }
19	{"type": "18", "name": "Address Mask Reply", "reference": "[RFC950]" }
20	{"type": "19", "name": "Reserved (for Security)", "reference": " [Solo]" }
21	{"type": "20", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
22	{"type": "21", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
23	{"type": "22", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
24	{"type": "23", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
25	{"type": "24", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
26	{"type": "25", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
27	{"type": "26", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
28	{"type": "27", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
29	{"type": "28", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
30	{"type": "29", "name": "Reserved (for Robustness Experiment)", "reference": "[ZSu]" }
31	{"type": "30", "name": "Traceroute", "reference": "[RFC1393]" }
32	{"type": "31", "name": "Datagram Conversion Error", "reference": "[RFC1475]" }
33	{"type": "32", "name": "Mobile Host Redirect", "reference": "[David Johnson]" }
34	{"type": "33", "name": "IPv6 Where-Are-You ", "reference": "[Bill Simpson]" }
35	{"type": "34", "name": "IPv6 I-Am-Here", "reference": "[Bill Simpson]" }
36	{"type": "35", "name": "Mobile Registration Request", "reference": "[Bill Simpson]" }
37	{"type": "36", "name": "Mobile Registration Reply", "reference": "[Bill Simpson]" }
38	{"type": "37", "name": "Domain Name Request", "reference": "[Simpson]" }
39	{"type": "38", "name": "Domain Name Reply ", "reference": "[Simpson]" }
40	{"type": "39", "name": "SKIP ", "reference": "[Markson]" }
41	{"type": "40", "name": "Photuris", "reference": "Simpson]" }
42	{"type": "41", "name": "Reserved", "reference": "JBP]" }
\.


--
-- Name: icmp_types_id_seq; Type: SEQUENCE SET; Schema: flow; Owner: flowuser
--

SELECT pg_catalog.setval('icmp_types_id_seq', 42, true);


--
-- Name: icmp_types_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_types
     ADD CONSTRAINT icmp_types_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

