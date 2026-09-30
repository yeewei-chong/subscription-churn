@echo off

set "PGPASSWORD=postgres"

psql -U postgres -d subscription_churn -f .\scripts\schema.sql
psql -U postgres -d subscription_churn -f .\scripts\load_members.sql
psql -U postgres -d subscription_churn -f .\scripts\load_transactions_to_events.sql

set "PGPASSWORD="
echo Done.