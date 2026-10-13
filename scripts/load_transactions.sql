CREATE TEMP TABLE transactions_staging (
    member_id TEXT,
    payment_method TEXT,
    payment_plan_days INT,
    plan_list_price INT,
    amount INT,
    is_auto_renew BOOLEAN,
    transaction_date TIMESTAMP,
    expiration_date TIMESTAMP,
    is_cancel BOOLEAN
);


--COPYING TRANSACTION DATA
\copy transactions_staging FROM 'data/transactions.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy transactions_staging FROM 'data/transactions_v2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');


-- HANDLING DUPLICATE TRANSACTION RECORDS IN A DAY
-- CHOOSING THE ONE THAT IS NOT CANCELLED
WITH remove_cancel_for_change AS (
    SELECT DISTINCT t1.*
    FROM transactions_staging t1
    JOIN (
      SELECT 
        member_id, 
        transaction_date, 
        MIN(is_cancel::INT) = 1 AS min_cancel,
        MIN(is_auto_renew::INT) = 1 AS min_auto
      FROM transactions_staging
      GROUP BY member_id, transaction_date
    ) t2
    ON t1.transaction_date = t2.transaction_date 
        AND t1.member_id = t2.member_id 
        AND t1.is_cancel = t2.min_cancel
        AND t1.is_auto_renew = t2.min_auto
    WHERE t1.amount > 0 AND t1.payment_plan_days > 0
-- ASSUMING CHANGE OF PLANS ARE FROM THE SHORTER SUBSCRIPTION TO THE LONGER
), choose_longest_sub AS (
    SELECT DISTINCT t1.*
    FROM remove_cancel_for_change t1
    JOIN (
      SELECT 
        member_id, 
        transaction_date, 
        MAX(payment_plan_days) AS max_sub
      FROM remove_cancel_for_change
      GROUP BY member_id, transaction_date
    ) t2
    ON t1.transaction_date = t2.transaction_date 
        AND t1.member_id = t2.member_id 
        AND t1.payment_plan_days = t2.max_sub
-- FOR THE SAME SUBSCRIPTION LENGTH, CHOOSE THE WORST CASE SCENARIO WHICH IS THE LOWER AMOUNT
), choose_least_amt AS (
    SELECT DISTINCT t1.*
    FROM choose_longest_sub t1
    JOIN (
      SELECT 
        member_id, 
        transaction_date, 
        MIN(amount) AS min_amt
      FROM choose_longest_sub
      GROUP BY member_id, transaction_date
    ) t2
    ON t1.transaction_date = t2.transaction_date 
        AND t1.member_id = t2.member_id 
        AND t1.amount = t2.min_amt
-- MODIFY THE END DATE BASED ON CANCELLATION BEFORE CHOOSING DISTINCT ROWS
), modify_end_date AS (
    SELECT DISTINCT
        member_id,
        payment_plan_days,
        payment_method,
        amount,
        is_auto_renew,
        transaction_date,
        (CASE 
            WHEN is_cancel THEN transaction_date + INTERVAL '1 day'
            WHEN expiration_date < '2017-03-31 00:00:00' THEN expiration_date
            ELSE '2017-03-31 00:00:00'
        END
        ) AS end_date,
        is_cancel
    FROM choose_least_amt
-- IF THERE STILL EXISTS MULTIPLE TRANSACTION METHODS, DROP THE MEMBER
), drop_remaining AS (
    SELECT 
        *, 
        COUNT(*) OVER (PARTITION BY member_id, transaction_date) AS row_count
    FROM modify_end_date
)
INSERT INTO transactions (
    member_id,
    payment_method,
    amount,
    is_auto_renew,
    transaction_date,
    expiration_date,
    is_cancel
)
SELECT
    t.member_id,
    payment_method,
    amount,
    is_auto_renew,
    transaction_date,
    end_date,
    is_cancel
FROM drop_remaining AS t
INNER JOIN members AS m
ON m.member_id = t.member_id
WHERE t.row_count = 1 AND end_date > transaction_date;






