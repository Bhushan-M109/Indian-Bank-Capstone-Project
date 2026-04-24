
/*****************************************************************************************
Name    : INDIAN BANK DB 
*****************************************************************************************/

CREATE DATABASE IF NOT EXISTS INDIAN_BANK;
USE INDIAN_BANK;

-- =========================================================
-- ProductMaster
-- =========================================================
CREATE TABLE ProductMaster (
    PID CHAR(2) PRIMARY KEY,
    ProductName VARCHAR(25) NOT NULL
);

INSERT INTO ProductMaster VALUES
('SB','Savings Bank'),
('LA','Loan Account'),
('FD','Fixed Deposit'),
('RD','Recurring Deposit');

-- =========================================================
-- RegionMaster
-- =========================================================
CREATE TABLE RegionMaster (
    RID INT PRIMARY KEY,
    RegionName CHAR(6) NOT NULL
);

INSERT INTO RegionMaster VALUES
(1,'South'),
(2,'North'),
(3,'East'),
(4,'West');

-- =========================================================
-- BranchMaster
-- =========================================================
CREATE TABLE BranchMaster (
    BRID CHAR(3) PRIMARY KEY,
    BranchName VARCHAR(30) NOT NULL,
    BranchAddress VARCHAR(50) NOT NULL,
    RID INT,
    FOREIGN KEY (RID) REFERENCES RegionMaster(RID)
);

INSERT INTO BranchMaster VALUES
('BR1','Goa','Opp: KLM Mall, Panaji, Goa-677123',4),
('BR2','Hyd','Hitech city, Hitex, Hyd-500012',1),
('BR3','Delhi','Opp: Ambuja Mall, Sadar Bazar, Delhi-110006',2),
('BR4','Mumbai','Suman city, Hitex, Mumbai-490001',4),
('BR5','Nagpur','Opp: Aman Mall, Nagpur-677178',4),
('BR6','Raipur','Chetak city, Raipur-492001',3),
('BR7','Kolkata','Opp: Shyam Mall, Howrah, Kolkata-485177',3),
('BR8','Chennai','Sona city, Chennai-504212',1),
('BR9','Trichy','Eltronic city, Hitex, Trichy-400012',1);

-- =========================================================
-- UserMaster
-- =========================================================
CREATE TABLE UserMaster (
    UserID INT PRIMARY KEY,
    UserName VARCHAR(30) NOT NULL,
    Designation CHAR(1) NOT NULL,
    CHECK (Designation IN ('M','T','C','O'))
);

INSERT INTO UserMaster VALUES
(1,'Bhaskar Jogi','M'),
(2,'Amit','O'),
(3,'Hemanth','M'),
(4,'John K','C'),
(5,'Aman Pandey','T'),
(6,'Priyanko','C');

-- =========================================================
-- AccountMaster
-- =========================================================
CREATE TABLE AccountMaster (
    ACID INT PRIMARY KEY,
    NAME VARCHAR(40) NOT NULL,
    ADDRESS VARCHAR(50) NOT NULL,
    BRID CHAR(3) NOT NULL,
    PID CHAR(2) NOT NULL,
    DOO DATETIME NOT NULL,
    CBALANCE DECIMAL(12,2),
    UBALANCE DECIMAL(12,2),
    STATUS CHAR(1) NOT NULL,
    FOREIGN KEY (BRID) REFERENCES BranchMaster(BRID),
    FOREIGN KEY (PID) REFERENCES ProductMaster(PID),
    CHECK (STATUS IN ('O','I','C'))
);

INSERT INTO AccountMaster VALUES
(101,'Amit Patel','USA','BR1','SB','2018-12-23',1000,1000,'O'),
(102,'Ahmed Patel','Mumbai','BR3','SB','2018-12-27',2000,2000,'O'),
(103,'Ramesh Jogi','Hyd','BR2','LA','2019-01-01',4000,2000,'O'),
(104,'Nita Sahu','Pune','BR4','FD','2019-01-11',9000,9000,'C'),
(105,'Venu G','Chennai','BR5','SB','2019-01-15',10000,10000,'I');

-- =========================================================
-- TxnMaster
-- =========================================================
CREATE TABLE TxnMaster (
    TNO INT PRIMARY KEY AUTO_INCREMENT,
    DOT DATETIME NOT NULL,
    ACID INT NOT NULL,
    BRID CHAR(3) NOT NULL,
    TXN_TYPE CHAR(3) NOT NULL,
    CHQ_NO INT NULL,
    CHQ_DATE DATETIME NULL,
    TXN_AMOUNT DECIMAL(12,2) NOT NULL,
    UserID INT NOT NULL,
    FOREIGN KEY (ACID) REFERENCES AccountMaster(ACID),
    FOREIGN KEY (BRID) REFERENCES BranchMaster(BRID),
    FOREIGN KEY (UserID) REFERENCES UserMaster(UserID),
    CHECK (TXN_TYPE IN ('CW','CD','COD'))
);

INSERT INTO TxnMaster
(DOT, ACID, BRID, TXN_TYPE, CHQ_NO, CHQ_DATE, TXN_AMOUNT, UserID)
VALUES
('2019-01-12',101,'BR1','CD',NULL,NULL,1000,1),
('2019-01-12',102,'BR3','CD',NULL,NULL,4000,3),
('2019-01-15',102,'BR3','CW',NULL,NULL,2000,4),
('2019-02-01',101,'BR1','CD',NULL,NULL,5000,6),
('2019-02-10',103,'BR2','COD',2354,'2019-02-07',500,4);

