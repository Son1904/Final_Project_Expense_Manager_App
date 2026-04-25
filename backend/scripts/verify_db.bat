@echo off
set PGPASSWORD=justkidding1904
psql -U postgres -h 127.0.0.1 -d expense_manager -A -t -c "SELECT tablename FROM pg_tables WHERE schemaname='public';"
echo ---
psql -U postgres -h 127.0.0.1 -d expense_manager -A -t -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name='users' ORDER BY ordinal_position;"
