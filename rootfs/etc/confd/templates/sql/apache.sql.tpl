CREATE DATABASE IF NOT EXISTS {{getv "/drupal/db"}} CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER USER IF EXISTS {{getv "/drupal/db/user"}} IDENTIFIED BY '{{getv "/drupal/db/pass"}}';
CREATE USER IF NOT EXISTS '{{getv "/drupal/db/user"}}'@'%' IDENTIFIED BY '{{getv "/drupal/db/pass"}}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, ALTER ROUTINE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, EVENT, EXECUTE, LOCK TABLES, REFERENCES, SHOW VIEW, TRIGGER ON {{getv "/drupal/db"}}.* TO '{{getv "/drupal/db/user"}}'@'%';
FLUSH PRIVILEGES;
