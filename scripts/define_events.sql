WITH member_transaction_join AS (
    SELECT 
        members.member_id,
        amount,
        registration_date,
        transaction_date,
        expiration_date,
        is_cancel
    FROM members
    INNER JOIN transactions
    ON members.member_id = transactions.member_id 
    WHERE transaction_date >= registration_date
), encode_start_end_days AS (
    SELECT
    member_id,
    amount,
    EXTRACT(EPOCH FROM (transaction_date - registration_date + INTERVAL '1 day')) / 60 / 60 / 24 AS start_day,
    EXTRACT(EPOCH FROM (expiration_date - registration_date + INTERVAL '1 day')) / 60 / 60 / 24 AS end_day,
    -- EVENT LOGIC
    (
        LEAD(transaction_date) OVER w IS NOT NULL 
        AND expiration_date + INTERVAL '30 days' < LEAD(transaction_date) OVER w
    ) OR (
        transaction_date = MAX(transaction_date) OVER (PARTITION BY member_id) 
        AND expiration_date + INTERVAL '30 days' < '2017-03-31 00:00:00'
    ) AS event 
    FROM member_transaction_join
    WINDOW w AS (PARTITION BY member_id ORDER BY transaction_date)
), cumulative AS (
    SELECT 
        member_id,
        SUM(event::INT) OVER (PARTITION BY member_id ORDER BY start_day) AS cumsum,
        amount,
        start_day,
        end_day,
        event
    FROM encode_start_end_days
), identify_tenures AS (
    SELECT 
        member_id,
        COALESCE(
            LAG(cumsum) OVER (PARTITION BY member_id ORDER BY start_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 
            0
        ) AS tenure_id,
        amount,
        start_day,
        end_day,
        event
    FROM cumulative
)
INSERT INTO events (
    member_id,
    tenure_id,
    avg_price,
    start_day,
    end_day,
    event
)
SELECT 
    member_id,
    tenure_id,
    AVG(amount),
    MIN(start_day),
    MAX(end_day),
    MAX(event::INT) = 1
FROM identify_tenures 
GROUP BY member_id, tenure_id
ORDER BY member_id, tenure_id;
