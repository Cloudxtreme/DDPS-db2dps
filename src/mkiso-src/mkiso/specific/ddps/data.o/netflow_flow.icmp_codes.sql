--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.5.7

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
-- Name: icmp_codes; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE icmp_codes (
    id integer NOT NULL,
    code json NOT NULL
);


ALTER TABLE icmp_codes OWNER TO flowuser;

--
-- Name: icmp_codes_id_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE icmp_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE icmp_codes_id_seq OWNER TO flowuser;

--
-- Name: icmp_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE icmp_codes_id_seq OWNED BY icmp_codes.id;


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_codes ALTER COLUMN id SET DEFAULT nextval('icmp_codes_id_seq'::regclass);


--
-- Data for Name: icmp_codes; Type: TABLE DATA; Schema: flow; Owner: flowuser
--

COPY icmp_codes (id, code) FROM stdin;
1	{"type": "0", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
2	{"type": "3", "codeno": "0", "code": "Net Unreachable", "reference": "" }
3	{"type": "3", "codeno": "1", "code": "Host Unreachable", "reference": "" }
4	{"type": "3", "codeno": "2", "code": "Protocol Unreachable", "reference": "" }
5	{"type": "3", "codeno": "3", "code": "Port Unreachable", "reference": "" }
6	{"type": "3", "codeno": "4", "code": "Fragmentation Needed and Don't Fragment was Set", "reference": "" }
7	{"type": "3", "codeno": "5", "code": "Source Route Failed", "reference": "" }
8	{"type": "3", "codeno": "6", "code": "Destination Network Unknown", "reference": "" }
9	{"type": "3", "codeno": "7", "code": "Destination Host Unknown", "reference": "" }
10	{"type": "3", "codeno": "8", "code": "Source Host Isolated", "reference": "" }
11	{"type": "3", "codeno": "9", "code": "Communication with Destination Network is Administratively Prohibited", "reference": "" }
12	{"type": "3", "codeno": "10", "code": "Communication with Destination Host is Administratively Prohibited", "reference": "" }
13	{"type": "3", "codeno": "11", "code": "Destination Network Unreachable for Type of Service", "reference": "" }
14	{"type": "3", "codeno": "12", "code": "Destination Host Unreachable for Type of Service", "reference": "" }
15	{"type": "3", "codeno": "13", "code": "Communication Administratively Prohibited", "reference": "[RFC1812]" }
16	{"type": "3", "codeno": "14", "code": "Host Precedence Violation", "reference": "[RFC1812]" }
17	{"type": "3", "codeno": "15", "code": "Precedence cutoff in effect", "reference": "[RFC1812]" }
18	{"type": "4", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
19	{"type": "5", "codeno": "0", "code": "Redirect Datagram for the Network (or subnet)", "reference": "" }
20	{"type": "5", "codeno": "1", "code": "Redirect Datagram for the Host", "reference": "" }
21	{"type": "5", "codeno": "2", "code": "Redirect Datagram for the Type of Service and Network", "reference": "" }
22	{"type": "5", "codeno": "3", "code": "Redirect Datagram for the Type of Service and Host", "reference": "" }
23	{"type": "6", "codeno": "0", "code": "Alternate Address for Host", "reference": "[JBP]" }
24	{"type": "8", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
25	{"type": "9", "codeno": "0", "code": "No Code", "reference": "[RFC1256]" }
26	{"type": "10", "codeno": "0", "code": "No Code", "reference": "[RFC1256]" }
27	{"type": "11", "codeno": "0", "code": "Time to Live exceeded in Transit", "reference": "[RFC792]" }
28	{"type": "11", "codeno": "1", "code": "Fragment Reassembly Time Exceeded", "reference": "[RFC792]" }
29	{"type": "12", "codeno": "0", "code": "Pointer indicates the error", "reference": "[RFC1108]" }
30	{"type": "12", "codeno": "1", "code": "Missing a Required Option", "reference": "[RFC1108]" }
31	{"type": "12", "codeno": "2", "code": "Bad Length", "reference": "[RFC1108]" }
32	{"type": "13", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
33	{"type": "14", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
34	{"type": "15", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
35	{"type": "16", "codeno": "0", "code": "No Code", "reference": "[RFC792]" }
36	{"type": "17", "codeno": "0", "code": "No Code", "reference": "[RFC950]" }
37	{"type": "18", "codeno": "0", "code": "No Code", "reference": "[RFC950]" }
38	{"type": "40", "codeno": "0", "code": "Reserved", "reference": "" }
39	{"type": "40", "codeno": "1", "code": "unknown security parameters index", "reference": "" }
40	{"type": "40", "codeno": "2", "code": "valid security parameters, but authentication failed", "reference": "" }
41	{"type": "40", "codeno": "3", "code": "valid security parameters, but decryption failed", "reference": "" }
\.


--
-- Name: icmp_codes_id_seq; Type: SEQUENCE SET; Schema: flow; Owner: flowuser
--

SELECT pg_catalog.setval('icmp_codes_id_seq', 41, true);


--
-- Name: icmp_codes_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_codes
    ADD CONSTRAINT icmp_codes_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

