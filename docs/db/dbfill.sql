--
-- Version 30 MAJ 2016 
-- Frank Thingholm
--
-- KUN MYSQL

--
-- Version 6. juni 2016
-- Kasper Sort
-- postgresql

\c netflow;

-- ----------------------------------------
-- GLOBAL OBJECTS - valid for all customers
-- ----------------------------------------


insert into flow.globalserviceobjects(
    globalserviceobjectid,
    ipprotocolname,
    ipprotocolnumber,
    servicename,
    portnumber,
    description
) values
(1, 'TCP',   6, 'SSH',  22,   'SSH (TCP)'  ),
(2, 'TCP',   6, 'SMTP', 25,   'SMTP (TCP)' ),
(3, 'TCP',   6, 'DNS',  53,   'DNS (TCP)'  ),
(4, 'UDP',  17, 'DNS',  53,   'DNS (UDP)'  ),
(5, 'ICMP',  8, 'PING', NULL, 'PING (ICMP)')
;

insert into flow.globalnetworkobjects(
    globalnetworkobjectid,
    name,
    sti    
) values
(1, 'Land: Japan',   '/tmp/country-flags/JP.png'),
(2, 'Land: Sverige', '/tmp/country-flags/SE.png')
;

insert into flow.globalnetworkobjectcidrs(
    globalnetworkobjectcidrid,
    globalnetworkobjectid,
    name,
    net,
    kind
) values
(1, 1, 'Japan del 1', '1.1.1/24',   'IPv4'),
(2, 1, 'Japan del 2', '2.2.2/24',   'IPv4'),
(3, 2, 'Sverige del 1', '3.3.3/24', 'IPv4'),
(4, 2, 'Sverige del 2', '4.4.4/24', 'IPv4')
;


-- --------------------------------------------
-- CUSTOMERS, THEIR NETWORKS AND ADMINISTRATORS
-- --------------------------------------------


insert into flow.customers (
    customerid,     
    companyname,        
    companyadr1,        
    companyadr2,        
    companyadr3,        
    companyadr4,        
    accountantname,
    accountantemail,
    accountantphone,
    hourlyrate,     
    subscriptionfee,
    deductionpct,   
    mainmail,       
    mainphone,      
    mainurl,            
    cvr,                
    ean,                
    valid   		    
) values
(1, 'Statens Arkiver', 'Rigsdagsgården','','','','Søren Jørgensen',        'soej@ra.sa.dk',           '12345678',143.00,200.00,20.00,'sa@sa.dk',                '12345678','www.sa.dk',          '11112222','1234567890123',true),
(2, 'It''s Learning',   'København',     '','','','Rasmus, Reza og Henning','drift.dk@itslearning.com','12345678',143.00,200.00,20.00,'drift.dk@itslearning.com','12345678','www.itslearning.com','11112223','1234567890133',true)
;

insert into flow.administrators (customerid, kind, name, phone, username, password, valid, lastlogin, lastpasswordchange) 
    values 
(2, 'netadmin', 'Kasper Sort', '88233', 'sort', crypt('nFdb0Jn6Kw8o', gen_salt('bf', 10)), true, now(), now());

