/*Part 5 – Case Study Assignment
 
Case: Fraud Detection Scenario
The bank suspects irregular transactions. Students must:
1. Detect accounts with unusually high transaction frequency.
2. Identify accounts with sudden large withdrawals.
3. Detect branches with abnormal transaction spikes.
4. Create fraud monitoring query using window functions.
5. Build summary report for management.

 */
 
 
 
 #1. Detect accounts with unusually high transaction frequency.
 
SELECT ACID, COUNT(TNO) AS Txn_Count
FROM TxnMaster
GROUP BY ACID
HAVING COUNT(TNO) > 2;

#2. Identify accounts with sudden large withdrawals.

SELECT A.NAME, T.TXN_AMOUNT, T.DOT, B.BranchName
FROM TxnMaster T
JOIN AccountMaster A ON T.ACID = A.ACID
JOIN BranchMaster B ON T.BRID = B.BRID
WHERE T.TXN_TYPE = 'CW' AND T.TXN_AMOUNT > 2000;

#3. Detect branches with abnormal transaction spikes.


SELECT *
FROM (
    SELECT 
        B.BRANCHNAME,
        DATE(T.DOT) AS TXN_DATE,
        SUM(T.TXN_AMOUNT) AS DAILY_TOTAL,
        AVG(SUM(T.TXN_AMOUNT)) OVER (PARTITION BY B.BRID) AS AVG_DAILY_TOTAL
    FROM BRANCHMASTER B
    JOIN TXNMASTER T ON B.BRID = T.BRID
    GROUP BY B.BRID, B.BRANCHNAME, DATE(T.DOT)
) AS X
WHERE DAILY_TOTAL > AVG_DAILY_TOTAL * 2;

/*Calculates daily transaction total per branch
Computes branch-wise average daily total
Filters records where daily total is more than 2× average*/

#4. Create fraud monitoring query using window functions.


SELECT ACID, DOT, TXN_AMOUNT,
       AVG(TXN_AMOUNT) OVER(PARTITION BY ACID) AS AvgAccountTxn,
       CASE 
          WHEN TXN_AMOUNT > (AVG(TXN_AMOUNT) OVER(PARTITION BY ACID) * 2) 
          THEN 'FLAG: Potential Fraud (High Spike)'
          ELSE 'Normal'
       END AS SecurityStatus
FROM TxnMaster;


# 5. Build summary report for management.

CREATE OR REPLACE VIEW BRANCH_LEVEL_REPORT AS
SELECT 
    B.BRANCHNAME,
    COUNT(DISTINCT A.ACID) AS TOTAL_ACCOUNTS,
    SUM(CASE WHEN A.STATUS = 'O' THEN 1 ELSE 0 END) AS ACTIVE_ACCOUNTS,
    SUM(T.TXN_AMOUNT) AS TOTAL_TXN_VOLUME,
    COUNT(T.TNO) AS TOTAL_TXN_COUNT,
    SUM(CASE WHEN T.TXN_TYPE = 'CD' THEN T.TXN_AMOUNT ELSE 0 END) AS TOTAL_DEPOSITS,
    SUM(CASE WHEN T.TXN_TYPE = 'CW' THEN T.TXN_AMOUNT ELSE 0 END) AS TOTAL_WITHDRAWALS
FROM BRANCHMASTER B
LEFT JOIN ACCOUNTMASTER A ON B.BRID = A.BRID
LEFT JOIN TXNMASTER T ON B.BRID = T.BRID
GROUP BY B.BRANCHNAME;

-- GENERATE THE REPORT
SELECT * FROM BRANCH_LEVEL_REPORT;


-- This view generates a branch-level management summary report.
-- It shows total accounts, active accounts, total transaction volume,
-- total transaction count, total deposits, and total withdrawals.
-- The report helps management monitor branch performance and activity.
