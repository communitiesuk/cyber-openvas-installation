create role dba with superuser noinherit;
grant dba to gvm;
create extension "uuid-ossp";
CREATE EXTENSION pgcrypto;
\q
