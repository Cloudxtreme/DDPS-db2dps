-- Role: postgres
-- DROP ROLE postgres;
-- CREATE ROLE postgres LOGIN
--   ENCRYPTED PASSWORD 'md5942f4da0211ffd357caaecc3abb437b5'
--     SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;

-- required for dropping admin who owns the netflow database
DROP DATABASE netflow;

-- Role: flowuser
DROP ROLE flowuser;
CREATE ROLE flowuser LOGIN
--  ENCRYPTED PASSWORD 'md593ee683b9569f87adb14477e44c04fff'
    PASSWORD '1qazxsw2'
    NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

-- Role: dbadmin
DROP ROLE dbadmin;
CREATE ROLE dbadmin LOGIN
  PASSWORD 'hopsasa'
    SUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION;

-- Role: admin
DROP ROLE admin;
CREATE ROLE admin LOGIN
  ENCRYPTED PASSWORD 'md58dc2a5cd22dd2fd394aef9968e4977b9'
    SUPERUSER INHERIT NOCREATEDB NOCREATEROLE REPLICATION;

--
-- Extension: pgcrypto
--
DROP EXTENSION pgcrypto;
CREATE EXTENSION pgcrypto
  SCHEMA public
  VERSION "1.2";

