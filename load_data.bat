@echo off

set "PGPASSWORD=postgres"

echo CREATE SCHEMA
psql -U postgres -d subscription_churn -f .\scripts\create_schema.sql

echo LOAD MEMBERS
psql -U postgres -d subscription_churn -f .\scripts\load_members.sql

echo LOAD TRANSACTIONS
psql -U postgres -d subscription_churn -f .\scripts\load_transactions.sql

echo DEFINE EVENTS
psql -U postgres -d subscription_churn -f .\scripts\define_events.sql

set "PGPASSWORD="
echo DONE