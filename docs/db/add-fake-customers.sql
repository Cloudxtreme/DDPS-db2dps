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
    valid,
	description
) values
(1, 'DeICi2', 'DTU','','','','Anders And',        'aa@dtu.dk',           '12345678',143.00,200.00,20.00,'aa@dtu.dk',                '12345678','www.dtu.dk',          '11112222','1234567890123',true, 'fake customer')
;

insert into flow.administrators (customerid, kind, name, phone, username, password, valid, lastlogin, lastpasswordchange) 
    values 
(1, 'netadmin', 'Anders And', '8888', 'aa', crypt('nFdb0Jn6Kw8o', gen_salt('bf', 10)), true, now(), now())
;

insert into flow.customernetworks
(
customernetworkid,
customerid,
name,
kind,
net,
description
) values
( 1, 1, 'kontornet', 'ipv4', '10.0.0.0/24', 'RNDs legenet' )
;

