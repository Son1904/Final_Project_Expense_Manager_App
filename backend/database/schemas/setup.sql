-- Database Setup Script
-- Run this file to create all tables in the correct order

\echo 'Creating Expense Manager Database Schema...'

\echo '1. Creating users table...'
\i 01_users.sql

\echo '2. Creating refresh_tokens table...'
\i 02_refresh_tokens.sql

\echo '3. Creating user_settings table...'
\i 03_user_settings.sql

\echo 'Database schema created successfully!'
