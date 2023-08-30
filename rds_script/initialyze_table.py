#After a connection using tcp "mysql -h database-topflight-app.cqa8k6awsmjm.us-east-1.rds.amazonaws.com -u admin -p"

create database db;
use db;
CREATE TABLE employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  age INT,
  salary DECIMAL(10, 2)
);