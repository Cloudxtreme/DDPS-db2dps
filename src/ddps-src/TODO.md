
# TODO:

  - fix db2dps så der testes for om første felt er validt + de andre !!!

  - hvis db insert fejler så må db2dps ikke gå ned, men slette/flytte regelfilen til senere analyse
    db2dps and db error handling, see https://docstore.mik.ua/orelly/linux/dbi/ch04_05.htm afsnit 4.5.1.3. Mixed error checking

  - fix db2dps så det undersøges om $admin / $fastnetmon har lov til at lave regler for $dst


``````sql
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
``````


 - kill_switch_restart_all_exabgp.pl: change libssh2 to openssh pm

DONE

  - db2dps og replikering
    -  ca linie 370: Start normalt lav DB forbindelse og hæng i et loop så længe
       pg_is_in_recovery, når den ikke længere er det så fortsæt men vend tilbage for
       hver iteration, dvs først i loopet
    -  test i loop om der ligger regelfiler && flyt dem til aktive server
    - read clmembers = xxxx yyyy from db.ini; check own IP address and connect to remote ok

  - skriv apply-default-rules om, så den anvender ddpsrules
  - replace buggy ssh2 code with openssh check on exabgp

  - apply-default-rules.sh får db2dps til at fejle

  - DB replikering vil påvirke db2dps. Check.
    - firewalls: test om process findes / findes på active/passive www.ddps og send scp til aktive
 

