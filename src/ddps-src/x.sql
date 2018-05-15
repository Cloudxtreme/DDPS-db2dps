-- Hvem: uuid_administratorid
-- Hvad: netværksadresse (ipv4 eller ipv6)
 
-- Administratorer: flow.administrators (uuid_administratorid XXX, valid XXX, networks (multiliste) XXX, uuid_customerid XXX)
-- Netværk:         flow.customernetworks (customernetworkid XXX, net (ipv4 eller ipv6) XXX, uuid_customerid XXX)
 
select
    count(*)
from
    flow.administrators, flow.customernetworks
WHERE
    -- join
    flow.administrators.uuid_customerid = flow.customernetworks.uuid_customerid
    -- administrators
    and
    flow.administrators.uuid_administratorid = '179c31f4-bc12-4c99-8ef0-9ae388821975'
    and
    flow.administrators.valid = 'active'
    -- customernetworks
    and
    flow.customernetworks.net = '95.128.24.0/21'

    -- checks
    and
    flow.customernetworks.customernetworkid = ANY ( "networks" )
 
;
