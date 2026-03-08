-- Create the default ianseo database along with the ianseo default
-- user and password.

USE mysql;

CREATE DATABASE ianseo;
CREATE USER 'ianseo'@'%' IDENTIFIED BY 'ianseo';
-- CREATE USER 'ianseo'@'%' IDENTIFIED WITH mysql_native_password BY 'ianseo';
GRANT ALL PRIVILEGES ON ianseo.* TO 'ianseo'@'%';
FLUSH PRIVILEGES;