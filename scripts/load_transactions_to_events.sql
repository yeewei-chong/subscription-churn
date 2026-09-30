-- STAGING TABLES
CREATE TEMP TABLE transactions_staging_copy (
    member_id TEXT,
    payment_method VARCHAR(2),
    payment_plan_days INT,
    plan_list_price INT,
    amount INT,
    is_auto_renew BOOLEAN,
    transaction_date TIMESTAMP,
    expiration_date TIMESTAMP,
    is_cancel BOOLEAN
);

CREATE TEMP TABLE transactions_staging_join (
    member_id TEXT,
    amount INT,
    registration_date TIMESTAMP,
    transaction_date TIMESTAMP,
    expiration_date TIMESTAMP,
    is_cancel BOOLEAN
);

CREATE TEMP TABLE events_staging (
    member_id TEXT,
    amount INT,
    start_day INT,
    end_day INT,
    event BOOLEAN
);

--COPYING TRANSACTION DATA
\copy transactions_staging_copy FROM 'data/transactions.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy transactions_staging_copy FROM 'data/transactions_v2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');



INSERT INTO transactions_staging_join (
    member_id,
    amount,
    registration_date,
    transaction_date,
    expiration_date,
    is_cancel
)
SELECT 
    members.member_id,
    amount,
    registration_date,
    transaction_date,
    expiration_date,
    is_cancel
FROM members
INNER JOIN transactions_staging_copy
ON members.member_id = transactions_staging_copy.member_id;


WITH modify_end_date AS (
    SELECT 
        member_id,
        amount,
        registration_date,
        transaction_date,
        (CASE 
            WHEN is_cancel THEN transaction_date + INTERVAL '1 day'
            WHEN expiration_date < '2017-03-31 00:00:00' THEN expiration_date
            ELSE '2017-03-31 00:00:00'
        END
        ) AS end_date,
        is_cancel
    FROM transactions_staging_join
)
INSERT INTO events_staging (
    member_id,
    amount,
    start_day,
    end_day,
    event
)
SELECT 
    member_id,
    amount,
    EXTRACT(EPOCH FROM (transaction_date - registration_date + INTERVAL '1 day')) / 60 / 60 / 24,
    EXTRACT(EPOCH FROM (end_date - registration_date + INTERVAL '1 day')) / 60 / 60 / 24,

    -- EVENT LOGIC
    (
        LEAD(transaction_date) OVER w IS NOT NULL 
        AND end_date + INTERVAL '30 days' < LEAD(transaction_date) OVER w
    ) OR (
        transaction_date = MAX(transaction_date) OVER (PARTITION BY member_id) 
        AND end_date + INTERVAL '30 days' < '2017-03-31 00:00:00'
    ) AS event

    
    FROM modify_end_date
    WINDOW w AS (PARTITION BY member_id ORDER BY transaction_date);



WITH choose_transaction AS (
    SELECT 
        member_id,
        SUM(CASE WHEN event THEN 0 ELSE amount END) AS latest_amount,
        start_day,
        MAX(end_day) AS max_end_day,
        MIN(event::INT) = 1 AS min_event
    FROM events_staging
    GROUP BY member_id, start_day
), cumulative AS (
    SELECT 
        member_id,
        SUM(min_event::INT) OVER (PARTITION BY member_id ORDER BY start_day) AS cumsum,
        latest_amount AS amount,
        start_day,
        max_end_day AS end_day,
        min_event AS event
    FROM choose_transaction
), before_agg AS (
    SELECT 
        member_id,
        COALESCE(LAG(cumsum) OVER (
            PARTITION BY member_id 
            ORDER BY start_day 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 0
        ) + 1 AS tenure,
        amount,
        start_day,
        end_day,
        event
    FROM cumulative
    WHERE start_day >= 1 AND end_day > start_day
)
INSERT INTO events (
    member_id,
    tenure,
    amount,
    start_day,
    end_day,
    event
)
SELECT 
    member_id,
    tenure,
    SUM(amount),
    MIN(start_day),
    MAX(end_day),
    MAX(event::INT) = 1
FROM before_agg
GROUP BY member_id, tenure
ORDER BY member_id, tenure;






