CREATE TEMP TABLE members_staging (
    member_id TEXT,
    city VARCHAR(2),
    age INT,
    gender TEXT,
    registration_method VARCHAR(2),
    registration_date TIMESTAMP
);

\copy members_staging FROM 'data/members_v3.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO members (
    member_id,
    city,
    registration_method,
    registration_date,
    is_complete_age_gender,
    obs_start_day,
    obs_end_day
)
SELECT 
    member_id,
    city,
    registration_method,
    registration_date,
    CASE WHEN age > 0 AND age <= 111 AND gender IS NOT NULL THEN TRUE ELSE FALSE END,
    EXTRACT(EPOCH FROM ('2015-01-01 00:00:00' - registration_date + INTERVAL '1 day')) / 60 / 60 / 24,
    EXTRACT(EPOCH FROM ('2017-03-31 00:00:00' - registration_date + INTERVAL '1 day')) / 60 / 60 / 24
FROM members_staging 
WHERE registration_date < '2017-03-31 00:00:00';








