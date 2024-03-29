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

--
-- Name: flow; Type: SCHEMA; Schema: -; Owner: flowuser
--

CREATE SCHEMA flow;


ALTER SCHEMA flow OWNER TO flowuser;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = flow, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: administrators; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE administrators (
    administratorid integer NOT NULL,
    customerid integer NOT NULL,
    kind character varying(12) NOT NULL,
    name character varying(80) NOT NULL,
    phone character varying(80),
    username character varying(32) NOT NULL,
    password character varying(64) NOT NULL,
    valid boolean NOT NULL,
    lastlogin timestamp with time zone,
    lastpasswordchange timestamp with time zone,
    description character varying(256),
    edupersonprincipalname character varying(255),
    email character varying(255),
    edupersonprimaryaffiliation character varying(64),
    organizationname character varying(255),
    edupersontargetedid character varying(128),
    schachomeorganization character varying(64),
    CONSTRAINT administrators_kind_check CHECK (((kind)::text = ANY (ARRAY[('globaladmin'::character varying)::text, ('dbadmin'::character varying)::text, ('netadmin'::character varying)::text]))),
    CONSTRAINT administrators_password_check CHECK ((length((password)::text) >= 12))
);


ALTER TABLE administrators OWNER TO flowuser;

--
-- Name: administrators_administratorid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE administrators_administratorid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE administrators_administratorid_seq OWNER TO flowuser;

--
-- Name: administrators_administratorid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE administrators_administratorid_seq OWNED BY administrators.administratorid;


--
-- Name: customernetworkobjects; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE customernetworkobjects (
    customernetworkobjectid integer NOT NULL,
    customernetworkid integer,
    name character varying(32) NOT NULL,
    kind character(4) NOT NULL,
    net inet NOT NULL,
    description character varying(256),
    CONSTRAINT customernetworkobjects_kind_check CHECK ((kind = ANY (ARRAY['IPv4'::bpchar, 'IPv6'::bpchar])))
);


ALTER TABLE customernetworkobjects OWNER TO flowuser;

--
-- Name: customernetworkobjects_customernetworkobjectid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE customernetworkobjects_customernetworkobjectid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customernetworkobjects_customernetworkobjectid_seq OWNER TO flowuser;

--
-- Name: customernetworkobjects_customernetworkobjectid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE customernetworkobjects_customernetworkobjectid_seq OWNED BY customernetworkobjects.customernetworkobjectid;


--
-- Name: customernetworks; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE customernetworks (
    customernetworkid bigint NOT NULL,
    customerid integer NOT NULL,
    name character varying(32) NOT NULL,
    kind character(4) NOT NULL,
    net cidr NOT NULL,
    description character varying(256),
    CONSTRAINT customernetworks_kind_check CHECK ((kind = ANY (ARRAY['ipv4'::bpchar, 'ipv6'::bpchar])))
);


ALTER TABLE customernetworks OWNER TO flowuser;

--
-- Name: customernetworks_customernetworkid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE customernetworks_customernetworkid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customernetworks_customernetworkid_seq OWNER TO flowuser;

--
-- Name: customernetworks_customernetworkid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE customernetworks_customernetworkid_seq OWNED BY customernetworks.customernetworkid;


--
-- Name: customers; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE customers (
    customerid integer NOT NULL,
    companyname character varying(80) NOT NULL,
    companyadr1 character varying(80) NOT NULL,
    companyadr2 character varying(80) NOT NULL,
    companyadr3 character varying(80) NOT NULL,
    companyadr4 character varying(80) NOT NULL,
    accountantname character varying(80) NOT NULL,
    accountantemail character varying(80) NOT NULL,
    accountantphone character varying(80) NOT NULL,
    hourlyrate numeric(10,2) NOT NULL,
    subscriptionfee numeric(10,2) NOT NULL,
    deductionpct numeric(10,2) NOT NULL,
    mainmail character varying(80),
    mainphone character varying(80),
    mainurl character varying(80),
    cvr character(8),
    ean character(13),
    valid boolean NOT NULL,
    description character varying(256)
);


ALTER TABLE customers OWNER TO flowuser;

--
-- Name: customers_customerid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE customers_customerid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customers_customerid_seq OWNER TO flowuser;

--
-- Name: customers_customerid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE customers_customerid_seq OWNED BY customers.customerid;


--
-- Name: fastnetmon_conf; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE fastnetmon_conf (
    id integer,
    fastnetmoninstanceid integer,
    ban_for_pps character varying(3) DEFAULT 'on'::character varying,
    ban_for_bandwidth character varying(3) DEFAULT 'on'::character varying,
    ban_for_flows character varying(3) DEFAULT 'on'::character varying,
    threshold_pps bigint DEFAULT 200,
    threshold_mbps bigint DEFAULT 200,
    threshold_flows bigint DEFAULT 2000,
    threshold_tcp_mbps bigint DEFAULT 100,
    threshold_udp_mbps bigint DEFAULT 100,
    threshold_icmp_mbps bigint DEFAULT 100,
    threshold_tcp_pps bigint DEFAULT 1000,
    threshold_udp_pps bigint DEFAULT 1000,
    threshold_icmp_pps bigint DEFAULT 500,
    ban_for_tcp_bandwidth character varying(3) DEFAULT 'on'::character varying,
    ban_for_udp_bandwidth character varying(3) DEFAULT 'on'::character varying,
    ban_for_icmp_bandwidth character varying(3) DEFAULT 'on'::character varying,
    ban_for_tcp_pps character varying(3) DEFAULT 'on'::character varying,
    ban_for_udp_pps character varying(3) DEFAULT 'on'::character varying,
    ban_for_icmp_pps character varying(3) DEFAULT 'on'::character varying,
    CONSTRAINT fastnetmon_conf_ban_for_bandwidth_check CHECK (((ban_for_bandwidth)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_flows_check CHECK (((ban_for_flows)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_icmp_bandwidth_check CHECK (((ban_for_icmp_bandwidth)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_icmp_pps_check CHECK (((ban_for_icmp_pps)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_pps_check CHECK (((ban_for_pps)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_tcp_bandwidth_check CHECK (((ban_for_tcp_bandwidth)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_tcp_pps_check CHECK (((ban_for_tcp_pps)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_udp_bandwidth_check CHECK (((ban_for_udp_bandwidth)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[]))),
    CONSTRAINT fastnetmon_conf_ban_for_udp_pps_check CHECK (((ban_for_udp_pps)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[])))
);


ALTER TABLE fastnetmon_conf OWNER TO flowuser;

--
-- Name: fastnetmoninstances; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE fastnetmoninstances (
    fastnetmoninstanceid integer NOT NULL,
    customerid integer,
    mode character varying(7),
    CONSTRAINT fastnetmoninstances_mode_check CHECK (((mode)::text = ANY ((ARRAY['detect'::character varying, 'enforce'::character varying])::text[])))
);


ALTER TABLE fastnetmoninstances OWNER TO flowuser;

--
-- Name: fastnetmoninstances_fastnetmoninstanceid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE fastnetmoninstances_fastnetmoninstanceid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fastnetmoninstances_fastnetmoninstanceid_seq OWNER TO flowuser;

--
-- Name: fastnetmoninstances_fastnetmoninstanceid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE fastnetmoninstances_fastnetmoninstanceid_seq OWNED BY fastnetmoninstances.fastnetmoninstanceid;


--
-- Name: flowspecrules; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE flowspecrules (
    flowspecruleid bigint NOT NULL,
    rule_name character varying(128),
    administratorid integer NOT NULL,
    direction character varying(3) NOT NULL,
    validfrom timestamp with time zone NOT NULL,
    validto timestamp with time zone NOT NULL,
    fastnetmoninstanceid integer,
    isactivated boolean NOT NULL,
    isexpired boolean NOT NULL,
    destinationprefix inet,
    sourceprefix inet,
    ipprotocol character varying(64),
    srcordestport character varying(128),
    destinationport character varying(128),
    sourceport character varying(128),
    icmptype character varying(128),
    icmpcode character varying(128),
    tcpflags character varying(32),
    packetlength character varying(128),
    dscp character varying(128),
    fragmentencoding character varying(128),
    description character varying(256),
    customerid integer DEFAULT 0 NOT NULL,
    action character varying(255),
    CONSTRAINT flowspecrules_check CHECK ((validto > validfrom)),
    CONSTRAINT flowspecrules_direction_check CHECK (((direction)::text = ANY ((ARRAY['in'::character varying, 'out'::character varying])::text[])))
);


ALTER TABLE flowspecrules OWNER TO flowuser;

--
-- Name: flowspecrules_flowspecruleid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE flowspecrules_flowspecruleid_seq
    START WITH 30
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE flowspecrules_flowspecruleid_seq OWNER TO flowuser;

--
-- Name: flowspecrules_flowspecruleid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE flowspecrules_flowspecruleid_seq OWNED BY flowspecrules.flowspecruleid;


--
-- Name: globalnetworkobjectcidrs; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE globalnetworkobjectcidrs (
    globalnetworkobjectcidrid integer NOT NULL,
    globalnetworkobjectid integer,
    name character varying(32) NOT NULL,
    net cidr NOT NULL,
    kind character(4) NOT NULL,
    description character varying(256),
    CONSTRAINT globalnetworkobjectcidrs_kind_check CHECK ((kind = ANY (ARRAY['IPv4'::bpchar, 'IPv6'::bpchar])))
);


ALTER TABLE globalnetworkobjectcidrs OWNER TO flowuser;

--
-- Name: globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq OWNER TO flowuser;

--
-- Name: globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq OWNED BY globalnetworkobjectcidrs.globalnetworkobjectcidrid;


--
-- Name: globalnetworkobjects; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE globalnetworkobjects (
    globalnetworkobjectid integer NOT NULL,
    name character varying(32) NOT NULL,
    sti character varying(128) NOT NULL,
    description character varying(256)
);


ALTER TABLE globalnetworkobjects OWNER TO flowuser;

--
-- Name: globalnetworkobjects_globalnetworkobjectid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE globalnetworkobjects_globalnetworkobjectid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE globalnetworkobjects_globalnetworkobjectid_seq OWNER TO flowuser;

--
-- Name: globalnetworkobjects_globalnetworkobjectid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE globalnetworkobjects_globalnetworkobjectid_seq OWNED BY globalnetworkobjects.globalnetworkobjectid;


--
-- Name: globalserviceobjects; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE globalserviceobjects (
    globalserviceobjectid integer NOT NULL,
    ipprotocolname character varying(16) NOT NULL,
    ipprotocolnumber integer NOT NULL,
    servicename character varying(16) NOT NULL,
    portnumber integer,
    description character varying(256) NOT NULL,
    CONSTRAINT globalserviceobjects_portnumber_check CHECK (((portnumber >= 0) AND (portnumber <= 65535)))
);


ALTER TABLE globalserviceobjects OWNER TO flowuser;

--
-- Name: globalserviceobjects_globalserviceobjectid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE globalserviceobjects_globalserviceobjectid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE globalserviceobjects_globalserviceobjectid_seq OWNER TO flowuser;

--
-- Name: globalserviceobjects_globalserviceobjectid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE globalserviceobjects_globalserviceobjectid_seq OWNED BY globalserviceobjects.globalserviceobjectid;


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
-- Name: networkrights; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE networkrights (
    networkrightid integer NOT NULL,
    customernetworkid integer NOT NULL,
    administratorid integer NOT NULL,
    maxblockmins integer,
    description character varying(256),
    CONSTRAINT networkrights_maxblockmins_check CHECK ((maxblockmins > 0))
);


ALTER TABLE networkrights OWNER TO flowuser;

--
-- Name: networkrights_networkrightid_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE networkrights_networkrightid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE networkrights_networkrightid_seq OWNER TO flowuser;

--
-- Name: networkrights_networkrightid_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE networkrights_networkrightid_seq OWNED BY networkrights.networkrightid;


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
-- Name: services; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE services (
    id integer NOT NULL,
    service json NOT NULL
);


ALTER TABLE services OWNER TO flowuser;

--
-- Name: services_id_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE services_id_seq OWNER TO flowuser;

--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: tcpflags; Type: TABLE; Schema: flow; Owner: flowuser
--

CREATE TABLE tcpflags (
    id integer NOT NULL,
    tcpflag json
);


ALTER TABLE tcpflags OWNER TO flowuser;

--
-- Name: tcpflags_id_seq; Type: SEQUENCE; Schema: flow; Owner: flowuser
--

CREATE SEQUENCE tcpflags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tcpflags_id_seq OWNER TO flowuser;

--
-- Name: tcpflags_id_seq; Type: SEQUENCE OWNED BY; Schema: flow; Owner: flowuser
--

ALTER SEQUENCE tcpflags_id_seq OWNED BY tcpflags.id;


--
-- Name: administratorid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY administrators ALTER COLUMN administratorid SET DEFAULT nextval('administrators_administratorid_seq'::regclass);


--
-- Name: customernetworkobjectid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworkobjects ALTER COLUMN customernetworkobjectid SET DEFAULT nextval('customernetworkobjects_customernetworkobjectid_seq'::regclass);


--
-- Name: customernetworkid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworks ALTER COLUMN customernetworkid SET DEFAULT nextval('customernetworks_customernetworkid_seq'::regclass);


--
-- Name: customerid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customers ALTER COLUMN customerid SET DEFAULT nextval('customers_customerid_seq'::regclass);


--
-- Name: fastnetmoninstanceid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY fastnetmoninstances ALTER COLUMN fastnetmoninstanceid SET DEFAULT nextval('fastnetmoninstances_fastnetmoninstanceid_seq'::regclass);


--
-- Name: flowspecruleid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY flowspecrules ALTER COLUMN flowspecruleid SET DEFAULT nextval('flowspecrules_flowspecruleid_seq'::regclass);


--
-- Name: globalnetworkobjectcidrid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalnetworkobjectcidrs ALTER COLUMN globalnetworkobjectcidrid SET DEFAULT nextval('globalnetworkobjectcidrs_globalnetworkobjectcidrid_seq'::regclass);


--
-- Name: globalnetworkobjectid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalnetworkobjects ALTER COLUMN globalnetworkobjectid SET DEFAULT nextval('globalnetworkobjects_globalnetworkobjectid_seq'::regclass);


--
-- Name: globalserviceobjectid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalserviceobjects ALTER COLUMN globalserviceobjectid SET DEFAULT nextval('globalserviceobjects_globalserviceobjectid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_codes ALTER COLUMN id SET DEFAULT nextval('icmp_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_types ALTER COLUMN id SET DEFAULT nextval('icmp_types_id_seq'::regclass);


--
-- Name: networkrightid; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY networkrights ALTER COLUMN networkrightid SET DEFAULT nextval('networkrights_networkrightid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY tcpflags ALTER COLUMN id SET DEFAULT nextval('tcpflags_id_seq'::regclass);


--
-- Name: administrators_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY administrators
    ADD CONSTRAINT administrators_pkey PRIMARY KEY (administratorid);


--
-- Name: administrators_username_key; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY administrators
    ADD CONSTRAINT administrators_username_key UNIQUE (username);


--
-- Name: customernetworkobjects_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworkobjects
    ADD CONSTRAINT customernetworkobjects_pkey PRIMARY KEY (customernetworkobjectid);


--
-- Name: customernetworks_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworks
    ADD CONSTRAINT customernetworks_pkey PRIMARY KEY (customernetworkid);


--
-- Name: customers_cvr_key; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_cvr_key UNIQUE (cvr);


--
-- Name: customers_ean_key; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_ean_key UNIQUE (ean);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customerid);


--
-- Name: fastnetmoninstances_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY fastnetmoninstances
    ADD CONSTRAINT fastnetmoninstances_pkey PRIMARY KEY (fastnetmoninstanceid);


--
-- Name: flowspecrules_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY flowspecrules
    ADD CONSTRAINT flowspecrules_pkey PRIMARY KEY (flowspecruleid);


--
-- Name: globalnetworkobjectcidrs_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalnetworkobjectcidrs
    ADD CONSTRAINT globalnetworkobjectcidrs_pkey PRIMARY KEY (globalnetworkobjectcidrid);


--
-- Name: globalnetworkobjects_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalnetworkobjects
    ADD CONSTRAINT globalnetworkobjects_pkey PRIMARY KEY (globalnetworkobjectid);


--
-- Name: globalserviceobjects_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalserviceobjects
    ADD CONSTRAINT globalserviceobjects_pkey PRIMARY KEY (globalserviceobjectid);


--
-- Name: icmp_codes_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_codes
    ADD CONSTRAINT icmp_codes_pkey PRIMARY KEY (id);


--
-- Name: icmp_types_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY icmp_types
    ADD CONSTRAINT icmp_types_pkey PRIMARY KEY (id);


--
-- Name: networkrights_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY networkrights
    ADD CONSTRAINT networkrights_pkey PRIMARY KEY (networkrightid);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: tcpflags_pkey; Type: CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY tcpflags
    ADD CONSTRAINT tcpflags_pkey PRIMARY KEY (id);


--
-- Name: administrators_customerid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY administrators
    ADD CONSTRAINT administrators_customerid_fkey FOREIGN KEY (customerid) REFERENCES customers(customerid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: customernetworkobjects_customernetworkid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworkobjects
    ADD CONSTRAINT customernetworkobjects_customernetworkid_fkey FOREIGN KEY (customernetworkid) REFERENCES customernetworks(customernetworkid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: customernetworks_customerid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY customernetworks
    ADD CONSTRAINT customernetworks_customerid_fkey FOREIGN KEY (customerid) REFERENCES customers(customerid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fastnetmon_conf_fastnetmoninstanceid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY fastnetmon_conf
    ADD CONSTRAINT fastnetmon_conf_fastnetmoninstanceid_fkey FOREIGN KEY (fastnetmoninstanceid) REFERENCES fastnetmoninstances(fastnetmoninstanceid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: fastnetmoninstances_customerid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY fastnetmoninstances
    ADD CONSTRAINT fastnetmoninstances_customerid_fkey FOREIGN KEY (customerid) REFERENCES customers(customerid);


--
-- Name: flowspecrules_administratorid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY flowspecrules
    ADD CONSTRAINT flowspecrules_administratorid_fkey FOREIGN KEY (administratorid) REFERENCES administrators(administratorid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: flowspecrules_customerid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY flowspecrules
    ADD CONSTRAINT flowspecrules_customerid_fkey FOREIGN KEY (customerid) REFERENCES customers(customerid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: flowspecrules_fastnetmoninstanceid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY flowspecrules
    ADD CONSTRAINT flowspecrules_fastnetmoninstanceid_fkey FOREIGN KEY (fastnetmoninstanceid) REFERENCES fastnetmoninstances(fastnetmoninstanceid);


--
-- Name: globalnetworkobjectcidrs_globalnetworkobjectid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY globalnetworkobjectcidrs
    ADD CONSTRAINT globalnetworkobjectcidrs_globalnetworkobjectid_fkey FOREIGN KEY (globalnetworkobjectid) REFERENCES globalnetworkobjects(globalnetworkobjectid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: networkrights_administratorid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY networkrights
    ADD CONSTRAINT networkrights_administratorid_fkey FOREIGN KEY (administratorid) REFERENCES administrators(administratorid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: networkrights_customernetworkid_fkey; Type: FK CONSTRAINT; Schema: flow; Owner: flowuser
--

ALTER TABLE ONLY networkrights
    ADD CONSTRAINT networkrights_customernetworkid_fkey FOREIGN KEY (customernetworkid) REFERENCES customernetworks(customernetworkid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

