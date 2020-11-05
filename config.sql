connect SYS/Oradoc_db1 AS SYSDBA
alter session set container = ORCLPDB1;

-- Setup 1 schema for openjdk
create user data_owner1 identified by "password01";
grant create session to data_owner1;
grant create table to data_owner1;
alter user data_owner1 quota unlimited on users;
grant create view, create procedure, create sequence to data_owner1;
commit;

-- Setup 2 schema for graal EE jit
create user data_owner2 identified by "password01";
grant create session to data_owner2;
grant create table to data_owner2;
alter user data_owner2 quota unlimited on users;
grant create view, create procedure, create sequence to data_owner2;
commit;

-- Setup 3 schema for graal EE native image
create user data_owner3 identified by "password01";
grant create session to data_owner3;
grant create table to data_owner3;
alter user data_owner3 quota unlimited on users;
grant create view, create procedure, create sequence to data_owner3;
commit;