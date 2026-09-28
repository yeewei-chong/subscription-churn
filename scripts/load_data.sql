CREATE TEMP TABLE members_staging (
    id TEXT,
    city VARCHAR(2),
    age INT,
    gender TEXT,
    registration_method VARCHAR(2),
    registration_date TIMESTAMP
);

CREATE TEMP TABLE transactions_staging (
    id TEXT,
    payment_method VARCHAR(2),
    payment_plan_days INT,
    plan_list_price INT,
    actual_amount_paid INT,
    is_auto_renew BOOLEAN,
    transaction_date TIMESTAMP,
    expiration_date TIMESTAMP,
    is_cancel BOOLEAN
);

\copy members_staging FROM 'data/members_v3.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

ALTER TABLE members_staging
    ADD COLUMN is_complete_age_gender BOOLEAN;

UPDATE members_staging
    SET is_complete_age_gender = CASE WHEN age > 0 AND age <= 111 AND gender IS NOT NULL THEN TRUE ELSE FALSE END;

INSERT INTO members (
    id,
    city,
    registration_method,
    registration_date,
    is_complete_age_gender
)
SELECT 
    id,
    city,
    registration_method,
    registration_date,
    is_complete_age_gender
FROM members_staging;




