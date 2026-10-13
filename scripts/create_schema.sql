DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS members;

CREATE TABLE members (
    member_id TEXT PRIMARY KEY,
    city TEXT,
    registration_method TEXT,
    registration_date TIMESTAMP,
    is_complete_age_gender BOOLEAN,
    obs_start_day INT,
    obs_end_day INT
);

CREATE TABLE transactions (
    member_id TEXT REFERENCES members(member_id),
    payment_method TEXT,
    amount INT,
    is_auto_renew BOOLEAN,
    transaction_date TIMESTAMP,
    expiration_date TIMESTAMP,
    is_cancel BOOLEAN
);

CREATE TABLE events (
    member_id TEXT REFERENCES members(member_id),
    tenure_id TEXT,
    avg_price INT,
    start_day INT,
    end_day INT,
    event BOOLEAN
);