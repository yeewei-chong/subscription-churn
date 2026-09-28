DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS members;

CREATE TABLE members (
    id TEXT PRIMARY KEY,
    city VARCHAR(2),
    registration_method VARCHAR(2),
    registration_date TIMESTAMP,
    is_complete_age_gender BOOLEAN
);

CREATE TABLE events (
    id TEXT REFERENCES members(id),
    tenure INT,
    start_day INT,
    end_day INT,
    event BOOLEAN
);