
--     INDIAN BANK SQL Capstone Project

USE INDIAN_BANK;

--     INDIAN BANK Data Dictionary

/*
1. ProductMaster
Stores the types of financial products offered by the bank.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| PID | CHAR(2) | PRIMARY KEY | Unique Product ID (e.g., 'SB', 'LA'). |
| ProductName | VARCHAR(25) | NOT NULL | Full name of the banking product. |



2. RegionMaster
Defines the geographical regions where the bank operates.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| RID | INT | PRIMARY KEY | Unique identifier for the region. |
| RegionName | CHAR(6) | NOT NULL | Name of the region (North, South, etc.). |



3. BranchMaster
Contains details for each individual bank branch.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| BRID | CHAR(3) | PRIMARY KEY | Unique Branch ID (e.g., 'BR1'). |
| BranchName | VARCHAR(30) | NOT NULL | Name of the city/location of the branch. |
| BranchAddress| VARCHAR(50) | NOT NULL | Physical mailing address of the branch. |
| RID | INT | FOREIGN KEY | References RegionMaster(RID). |



4. UserMaster
Records administrative staff and their roles.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| UserID | INT | PRIMARY KEY | Unique employee identifier. |
| UserName | VARCHAR(30) | NOT NULL | Full name of the bank employee. |
| Designation | CHAR(1) | CHECK (M, T, C, O) | Staff role: Manager, Teller, Cashier, or Officer. |



5. AccountMaster
The central table for customer account information.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| ACID | INT | PRIMARY KEY | Unique Account ID. |
| NAME | VARCHAR(40) | NOT NULL | Name of the account holder. |
| ADDRESS | VARCHAR(50) | NOT NULL | Customer's residence/mailing address. |
| BRID | CHAR(3) | FOREIGN KEY | Branch where the account was opened. |
| PID | CHAR(2) | FOREIGN KEY | Product type (Savings, Loan, etc.). |
| DOO | DATETIME | NOT NULL | Date of Opening. |
| CBALANCE | DECIMAL(12,2)| - | Current available balance. |
| UBALANCE | DECIMAL(12,2)| - | Uncleared/Total balance. |
| STATUS | CHAR(1) | CHECK (O, I, C) | Status: Open (O), Inactive (I), or Closed (C). |



6. TxnMaster
Logs every financial transaction performed in the system.
| Column | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| TNO | INT | PRIMARY KEY | Unique Transaction Number (Auto-increment). |
| DOT | DATETIME | NOT NULL | Date of Transaction. |
| ACID | INT | FOREIGN KEY | Account involved in the transaction. |
| BRID | CHAR(3) | FOREIGN KEY | Branch where the transaction occurred. |
| TXN_TYPE | CHAR(3) | CHECK (CW, CD, COD)| Type: Cash Withdrawal, Deposit, or Check. |
| CHQ_NO | INT | NULL | Check number (if applicable). |
| CHQ_DATE | DATETIME | NULL | Date on the check (if applicable). |
| TXN_AMOUNT | DECIMAL(12,2)| NOT NULL | Monetary value of the transaction. |
| UserID | INT | FOREIGN KEY | Employee who processed the transaction. |*/





--     Part 1: Basic Queries

# 1. Accounts with Branch and Product Details

SELECT A.ACID, A.NAME, B.BranchName, P.ProductName, A.CBALANCE
FROM AccountMaster A
JOIN BranchMaster B ON A.BRID = B.BRID
JOIN ProductMaster P ON A.PID = P.PID;

# 2. Total Accounts per Branch

SELECT B.BranchName, COUNT(A.ACID) AS TotalAccounts
FROM BranchMaster B
LEFT JOIN AccountMaster A ON B.BRID = A.BRID
GROUP BY B.BranchName;

# 3. Total Balance per Product Type

SELECT P.ProductName, SUM(A.CBALANCE) AS TotalProductBalance
FROM ProductMaster P
JOIN AccountMaster A ON P.PID = A.PID
GROUP BY P.ProductName;

# 4. Find Inactive Accounts

SELECT ACID, NAME, STATUS 
FROM AccountMaster 
WHERE STATUS = 'I';

# 5. Transactions with User Names

SELECT T.TNO, T.DOT, T.TXN_AMOUNT, U.UserName
FROM TxnMaster T
JOIN UserMaster U ON T.UserID = U.UserID;


--       Part 2: Intermediate Queries

# 1. Top 3 Branches by Transaction Amount

SELECT B.BranchName, SUM(T.TXN_AMOUNT) AS TotalVolume
FROM BranchMaster B
JOIN TxnMaster T ON B.BRID = T.BRID
GROUP BY B.BranchName
ORDER BY TotalVolume DESC
LIMIT 3;


# 2. Customers with Balance Above Branch Average

SELECT NAME, CBALANCE, BRID
FROM AccountMaster A1
WHERE CBALANCE > (
    SELECT AVG(CBALANCE) 
    FROM AccountMaster A2 
    WHERE A1.BRID = A2.BRID
);

# 3. Region-wise Total Deposits

SELECT R.RegionName, SUM(T.TXN_AMOUNT) AS TotalDeposits
FROM RegionMaster R
JOIN BranchMaster B ON R.RID = B.RID
JOIN TxnMaster T ON B.BRID = T.BRID
WHERE T.TXN_TYPE = 'CD' 
GROUP BY R.RegionName;


# 4. Customers with More Than 3 Transactions

SELECT A.NAME, COUNT(T.TNO) AS TransactionCount
FROM AccountMaster A
JOIN TxnMaster T ON A.ACID = T.ACID
GROUP BY A.ACID, A.NAME
HAVING COUNT(T.TNO) > 3;

# 5. Running Balance per Account

SELECT ACID, DOT, TXN_TYPE, TXN_AMOUNT,
       SUM(CASE WHEN TXN_TYPE = 'CD' THEN TXN_AMOUNT 
                WHEN TXN_TYPE = 'CW' THEN -TXN_AMOUNT 
                ELSE 0 END) 
       OVER (PARTITION BY ACID ORDER BY DOT) AS RunningBalance
FROM TxnMaster;

# 6. Highest Transaction per Branch

SELECT BranchName, MaxTxnAmount
FROM (
    SELECT B.BranchName, T.TXN_AMOUNT AS MaxTxnAmount,
           RANK() OVER (PARTITION BY B.BRID ORDER BY T.TXN_AMOUNT DESC) AS TxnRank
    FROM BranchMaster B
    JOIN TxnMaster T ON B.BRID = T.BRID
) AS RankedTxns
WHERE TxnRank = 1;



--     Part 3 – Advanced SQL


# 1. Create a Stored Procedure to transfer amount between accounts.

DELIMITER //

CREATE PROCEDURE sp_TransferAmount(
    IN FromAccount INT,
    IN ToAccount INT,
    IN TransferAmount DECIMAL(12,2),
    IN ExecutingUser INT,
    IN BranchID CHAR(3)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
        -- 1. Deduct from sender
        UPDATE AccountMaster 
        SET CBALANCE = CBALANCE - TransferAmount 
        WHERE ACID = FromAccount;

        -- 2. Add to receiver
        UPDATE AccountMaster 
        SET CBALANCE = CBALANCE + TransferAmount 
        WHERE ACID = ToAccount;

        -- 3. Record the transaction (Debit)
        INSERT INTO TxnMaster (DOT, ACID, BRID, TXN_TYPE, TXN_AMOUNT, UserID)
        VALUES (NOW(), FromAccount, BranchID, 'CW', TransferAmount, ExecutingUser);

        -- 4. Record the transaction (Credit)
        INSERT INTO TxnMaster (DOT, ACID, BRID, TXN_TYPE, TXN_AMOUNT, UserID)
        VALUES (NOW(), ToAccount, BranchID, 'CD', TransferAmount, ExecutingUser);
    COMMIT;
END //

DELIMITER ;

CALL SP_TRANSFERAMOUNT(101, 102, 5000.00, 1, 'BR1');

SELECT * FROM TxnMaster;

/*-- Transaction Control Explanation:
-- START TRANSACTION makes all below operations (debit, credit, entries)
-- execute as one single unit of work.
-- If all statements succeed, COMMIT permanently saves the changes.
-- If any error occurs, EXIT HANDLER triggers ROLLBACK,
-- which cancels all changes and restores previous balance.
-- This ensures data consistency and prevents partial money transfer.*/


# 2. Create a trigger to prevent negative balance

DELIMITER //

CREATE TRIGGER trg_CheckBalance
BEFORE UPDATE ON AccountMaster
FOR EACH ROW
BEGIN
    IF NEW.CBALANCE < 0 THEN
        SIGNAL SQLSTATE '45000'       #It raises a custom error and update operation is immediately stopped.   
        SET MESSAGE_TEXT = 'Insufficient Funds: Transaction denied to prevent negative balance.';
    END IF;
END //

DELIMITER ;


SELECT ACID, NAME, CBALANCE FROM ACCOUNTMASTER WHERE ACID = 101;


UPDATE ACCOUNTMASTER 
SET CBALANCE = CBALANCE -10000 
WHERE ACID = 101;

drop trigger trg_CheckBalance;

SHOW TRIGGERS LIKE 'AccountMaster';


# 3.Create a view for branch performance summary

CREATE VIEW vw_BranchPerformance AS
SELECT 
    B.BranchName,
    COUNT(T.TNO) AS TotalTransactions,
    SUM(T.TXN_AMOUNT) AS TotalVolume,
    COUNT(DISTINCT A.ACID) AS ActiveCustomers
FROM BranchMaster B
LEFT JOIN TxnMaster T ON B.BRID = T.BRID
LEFT JOIN AccountMaster A ON B.BRID = A.BRID
GROUP BY B.BRID, B.BranchName;

select * from vw_BranchPerformance;


# 4. Use window functions to rank branches by performance.

SELECT 
    BranchName,
    TotalVolume,
    RANK() OVER (ORDER BY TotalVolume DESC) AS PerformanceRank
FROM vw_BranchPerformance;


# 5. Optimize slow query using indexing.

SELECT * FROM TxnMaster WHERE ACID = 101 AND DOT > '2025-01-01';

CREATE INDEX idx_txn_acid_dot ON TxnMaster(ACID, DOT);

explain analyze SELECT * FROM TxnMaster WHERE ACID = 101 AND DOT > '2025-01-01';

 DROP INDEX idx_txn_acid_dot ON TxnMaster;
 
# 6.  Compare JOIN vs Subquery performance using EXPLAIN.

EXPLAIN SELECT DISTINCT A.NAME 
FROM AccountMaster A 
JOIN TxnMaster T ON A.ACID = T.ACID 
WHERE T.BRID = 'BR1';


/*'-> Table scan on <temporary>  (cost=3.86..5.77 rows=4)\n   
 -> Temporary table with deduplication  (cost=3.22..3.22 rows=4)\n       
 -> Nested loop inner join  (cost=2.3 rows=4)\n            
 -> Index lookup on T using BRID (BRID = \'BR1\'), with index condition: (T.BRID = \'BR1\')  (cost=0.9 rows=4)\n          
 -> Single-row index lookup on A using PRIMARY (ACID = T.ACID)  (cost=0.275 rows=1)\n'
*/

EXPLAIN SELECT NAME 
FROM AccountMaster 
WHERE ACID IN (SELECT ACID FROM TxnMaster WHERE BRID = 'BR1');

/*'-> Nested loop inner join  (cost=3.25 rows=20)\n    -> Table scan on AccountMaster  (cost=0.75 rows=5)\n    
-> Single-row index lookup on <subquery2> using <auto_distinct_key> (ACID = accountmaster.ACID) 
 (cost=1.97..1.97 rows=1)\n        -> Materialize with deduplication  (cost=1.82..1.82 rows=4)\n         
 -> Index lookup on TxnMaster using BRID (BRID = \'BR1\'), with index condition: (txnmaster.BRID = \'BR1\')  (cost=0.9 rows=4)\n'
*/


/*The JOIN query performs better because it uses index lookups and avoids full table scans.
The subquery requires materialization and scans AccountMaster, increasing execution cost.
Therefore, JOIN is generally more efficient than subquery for this case.*/








--     Part 4 – Performance & Optimization


# 1. Create appropriate indexes.

-- Composite index to speed up account-specific transaction history lookups
CREATE INDEX idx_txn_acid_dot ON TxnMaster(ACID, DOT);

-- Index for filtering by transaction type
CREATE INDEX idx_txn_type ON TxnMaster(TXN_TYPE);

-- Index for identifying branch locations quickly
CREATE INDEX idx_branch_region ON BranchMaster(RID);



# 2. Analyze query performance using EXPLAIN.

EXPLAIN SELECT * FROM TxnMaster WHERE ACID = 101 AND DOT > '2019-01-01';



# 3.Demonstrate effect of composite index.

-- Create a composite index on Account ID and Date of Transaction
# CREATE INDEX idx_txn_acid_dot ON TxnMaster(ACID, DOT);

EXPLAIN SELECT * FROM TxnMaster 
WHERE ACID = 101 AND DOT BETWEEN '2019-01-01' AND '2019-12-31';


# 4 . Identify query that causes full table scan.

-- Since 'ADDRESS' is not indexed , so select need to scan the whole table
SELECT NAME FROM AccountMaster WHERE ADDRESS LIKE '%Mumbai%';

EXPLAIN SELECT NAME FROM AccountMaster WHERE ADDRESS LIKE '%Mumbai%';

# 5. Provide optimization recommendation report.

/*-- Optimization Recommendations:
-- 1. Proper indexing (BRID, ACID, composite index) improves query speed.
-- 2. JOIN is preferred over subquery for better index usage and lower cost.
-- 3. START TRANSACTION, COMMIT, and ROLLBACK ensure safe and consistent transfers.
-- 4. BEFORE UPDATE trigger prevents negative balance and enforces business rules.*/











