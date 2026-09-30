DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS members;

CREATE TABLE members (
    member_id TEXT PRIMARY KEY,
    city VARCHAR(2),
    registration_method VARCHAR(2),
    registration_date TIMESTAMP,
    is_complete_age_gender BOOLEAN,
    obs_start_day INT,
    obs_end_day INT
);

CREATE TABLE events (
    member_id TEXT REFERENCES members(member_id),
    tenure TEXT,
    amount INT,
    start_day INT,
    end_day INT,
    event BOOLEAN
);