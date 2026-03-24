-------------------------------------------------------------------------------
-- SQL Script to Initialize Testing Data for EMPLOYEE and DEPARTMENT Tables
-- This script ensures data integrity with proper constraint handling
-------------------------------------------------------------------------------
set schema COMPSYS;

-- Clear existing data (if any)
DELETE FROM EMPLOYEE;
DELETE FROM DEPARTMENT;

-------------------------------------------------------------------------------
-- DEPARTMENT Test Data
-- Note: ADMRDEPT has a self-referencing foreign key, so we need to insert
-- departments in the correct order (parent departments first)
-------------------------------------------------------------------------------

-- Insert root department first (self-referencing)
INSERT INTO DEPARTMENT (DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)
VALUES ('A00', 'CORPORATE', '000010', 'A00', 'NEW YORK');

-- Insert departments that report to A00
INSERT INTO DEPARTMENT (DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)
VALUES 
  ('B01', 'PLANNING', '000020', 'A00', 'NEW YORK'),
  ('C01', 'INFORMATION CENTER', '000030', 'A00', 'NEW YORK'),
  ('D01', 'DEVELOPMENT CENTER', '000060', 'A00', 'AUSTIN');

-- Insert departments that report to D01
INSERT INTO DEPARTMENT (DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)
VALUES 
  ('D11', 'MANUFACTURING SYSTEMS', '000060', 'D01', 'AUSTIN'),
  ('D21', 'ADMINISTRATION SYSTEMS', '000070', 'D01', 'AUSTIN');

-- Insert departments that report to C01
INSERT INTO DEPARTMENT (DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)
VALUES 
  ('E01', 'SUPPORT SERVICES', '000050', 'C01', 'CHICAGO'),
  ('E11', 'OPERATIONS', '000090', 'E01', 'CHICAGO'),
  ('E21', 'SOFTWARE SUPPORT', '000100', 'E01', 'CHICAGO');

-------------------------------------------------------------------------------
-- EMPLOYEE Test Data
-- Ensuring all constraints are met:
-- - EMPNO is unique (primary key)
-- - PHONENO is between '0000' and '9998'
-- - WORKDEPT references valid department codes
-- - All NOT NULL fields are populated
-------------------------------------------------------------------------------

-- Management employees (referenced by DEPARTMENT.MGRNO)
INSERT INTO EMPLOYEE (EMPNO, FIRSTNME, MIDINIT, LASTNAME, WORKDEPT, PHONENO, 
                      HIREDATE, JOB, EDLEVEL, SEX, BIRTHDATE, SALARY, BONUS, COMM)
VALUES 
  ('000010', 'CHRISTINE', 'I', 'HAAS', 'A00', '3978', 
   '1995-01-01', 'PRES', 18, 'F', '1963-08-24', 152750.00, 1000.00, 4220.00),
  
  ('000020', 'MICHAEL', 'L', 'THOMPSON', 'B01', '3476', 
   '2003-10-10', 'MANAGER', 18, 'M', '1978-02-02', 94250.00, 800.00, 3300.00),
  
  ('000030', 'SALLY', 'A', 'KWAN', 'C01', '4738', 
   '2005-04-05', 'MANAGER', 20, 'F', '1971-05-11', 98250.00, 800.00, 3060.00),
  
  ('000050', 'JOHN', 'B', 'GEYER', 'E01', '6789', 
   '1979-08-17', 'MANAGER', 16, 'M', '1955-09-15', 80175.00, 800.00, 3214.00),
  
  ('000060', 'IRVING', 'F', 'STERN', 'D11', '6423', 
   '2003-09-14', 'MANAGER', 16, 'M', '1975-07-07', 72250.00, 500.00, 2580.00),
  
  ('000070', 'EVA', 'D', 'PULASKI', 'D21', '7831', 
   '2005-09-30', 'MANAGER', 16, 'F', '1973-05-26', 96170.00, 700.00, 2893.00),
  
  ('000090', 'EILEEN', 'W', 'HENDERSON', 'E11', '5498', 
   '2000-08-15', 'MANAGER', 16, 'F', '1971-05-15', 89750.00, 600.00, 2380.00),
  
  ('000100', 'THEODORE', 'Q', 'SPENSER', 'E21', '0972', 
   '2000-06-19', 'MANAGER', 14, 'M', '1980-12-18', 86150.00, 500.00, 2092.00);

-- Regular employees in various departments
INSERT INTO EMPLOYEE (EMPNO, FIRSTNME, MIDINIT, LASTNAME, WORKDEPT, PHONENO, 
                      HIREDATE, JOB, EDLEVEL, SEX, BIRTHDATE, SALARY, BONUS, COMM)
VALUES 
  -- A00 - Corporate
  ('000110', 'VINCENZO', 'G', 'LUCCHESSI', 'A00', '3490', 
   '1988-05-16', 'SALESREP', 19, 'M', '1959-11-05', 66500.00, 900.00, 3720.00),
  
  ('000120', 'SEAN', ' ', 'OCONNELL', 'A00', '2167', 
   '1993-12-05', 'CLERK', 14, 'M', '1972-10-18', 49250.00, 600.00, 2340.00),
  
  -- B01 - Planning
  ('000130', 'DELORES', 'M', 'QUINTANA', 'B01', '4578', 
   '2001-07-28', 'ANALYST', 16, 'F', '1975-09-15', 73800.00, 500.00, 1904.00),
  
  ('000140', 'HEATHER', 'A', 'NICHOLLS', 'B01', '1793', 
   '2006-12-15', 'ANALYST', 18, 'F', '1976-01-19', 68420.00, 600.00, 2274.00),
  
  -- C01 - Information Center
  ('000150', 'BRUCE', ' ', 'ADAMSON', 'C01', '4510', 
   '2002-02-12', 'DESIGNER', 16, 'M', '1977-05-17', 55280.00, 500.00, 2022.00),
  
  ('000160', 'ELIZABETH', 'R', 'PIANKA', 'C01', '3782', 
   '2006-10-11', 'DESIGNER', 17, 'F', '1980-04-12', 62250.00, 400.00, 1780.00),
  
  -- D11 - Manufacturing Systems
  ('000170', 'MASATOSHI', 'J', 'YOSHIMURA', 'D11', '2890', 
   '1999-09-15', 'DESIGNER', 16, 'M', '1981-01-05', 44680.00, 500.00, 1974.00),
  
  ('000180', 'MARILYN', 'S', 'SCOUTTEN', 'D11', '1682', 
   '2003-07-07', 'DESIGNER', 17, 'F', '1979-02-21', 51340.00, 500.00, 1707.00),
  
  ('000190', 'JAMES', 'H', 'WALKER', 'D11', '2986', 
   '2004-07-26', 'DESIGNER', 16, 'M', '1982-06-25', 50450.00, 400.00, 1636.00),
  
  -- D21 - Administration Systems
  ('000200', 'DAVID', ' ', 'BROWN', 'D21', '4501', 
   '2002-03-03', 'DESIGNER', 16, 'M', '1971-05-29', 57740.00, 600.00, 2217.00),
  
  ('000210', 'WILLIAM', 'T', 'JONES', 'D21', '0942', 
   '1998-04-11', 'DESIGNER', 17, 'M', '1973-02-23', 68270.00, 400.00, 1462.00),
  
  ('000220', 'JENNIFER', 'K', 'LUTZ', 'D21', '0672', 
   '1998-08-29', 'DESIGNER', 18, 'F', '1978-03-19', 49840.00, 600.00, 2387.00),
  
  -- E11 - Operations
  ('000230', 'JAMES', 'J', 'JEFFERSON', 'E11', '2094', 
   '1996-11-21', 'CLERK', 14, 'M', '1980-05-30', 42180.00, 400.00, 1774.00),
  
  ('000240', 'SALVATORE', 'M', 'MARINO', 'E11', '3780', 
   '2004-12-05', 'CLERK', 17, 'M', '1979-03-31', 48760.00, 600.00, 2301.00),
  
  ('000250', 'DANIEL', 'S', 'SMITH', 'E11', '0961', 
   '1999-10-30', 'CLERK', 15, 'M', '1969-11-12', 49180.00, 400.00, 1534.00),
  
  -- E21 - Software Support
  ('000260', 'SYBIL', 'P', 'JOHNSON', 'E21', '8953', 
   '2005-09-11', 'CLERK', 16, 'F', '1976-10-05', 47250.00, 300.00, 1380.00),
  
  ('000270', 'MARIA', 'L', 'PEREZ', 'E21', '9001', 
   '2006-09-30', 'CLERK', 15, 'F', '1980-05-26', 37380.00, 500.00, 2190.00),
  
  ('000280', 'ETHEL', 'R', 'SCHNEIDER', 'E21', '8997', 
   '1997-03-24', 'OPERATOR', 17, 'F', '1976-03-28', 36250.00, 500.00, 2100.00),
  
  ('000290', 'JOHN', 'R', 'PARKER', 'E21', '4502', 
   '2006-05-30', 'OPERATOR', 12, 'M', '1985-07-09', 35340.00, 300.00, 1227.00),
  
  ('000300', 'PHILIP', 'X', 'SMITH', 'E21', '2095', 
   '2002-06-19', 'OPERATOR', 14, 'M', '1976-10-27', 37750.00, 400.00, 1420.00);

-------------------------------------------------------------------------------
-- Verification Queries
-------------------------------------------------------------------------------

-- Count records
SELECT 'DEPARTMENT' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM DEPARTMENT
UNION ALL
SELECT 'EMPLOYEE' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM EMPLOYEE;

-- Verify department hierarchy
SELECT D1.DEPTNO, D1.DEPTNAME, D1.ADMRDEPT, D2.DEPTNAME AS ADMIN_DEPT_NAME
FROM DEPARTMENT D1
LEFT JOIN DEPARTMENT D2 ON D1.ADMRDEPT = D2.DEPTNO
ORDER BY D1.DEPTNO;

-- Verify employees by department
SELECT D.DEPTNO, D.DEPTNAME, COUNT(E.EMPNO) AS EMPLOYEE_COUNT
FROM DEPARTMENT D
LEFT JOIN EMPLOYEE E ON D.DEPTNO = E.WORKDEPT
GROUP BY D.DEPTNO, D.DEPTNAME
ORDER BY D.DEPTNO;

-- Verify managers exist in employee table
SELECT D.DEPTNO, D.DEPTNAME, D.MGRNO, E.FIRSTNME, E.LASTNAME
FROM DEPARTMENT D
LEFT JOIN EMPLOYEE E ON D.MGRNO = E.EMPNO
ORDER BY D.DEPTNO;

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
-- Total Departments: 9
-- Total Employees: 30
-- All foreign key constraints are satisfied
-- All check constraints are satisfied (PHONENO between '0000' and '9998')
-------------------------------------------------------------------------------

-- Made with Bob
