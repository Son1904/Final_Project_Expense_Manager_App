-- Seed Data for Development/Testing
-- Creates sample user and data for testing

\echo 'Seeding test data...'

-- Insert test user
INSERT INTO users (email, password_hash, full_name, phone, email_verified, is_active)
VALUES 
    ('test@example.com', '$2a$10$XYZ...', 'Test User', '0901234567', TRUE, TRUE),
    ('demo@example.com', '$2a$10$ABC...', 'Demo User', '0907654321', TRUE, TRUE)
ON CONFLICT (email) DO NOTHING;

-- Insert user settings for test users
INSERT INTO user_settings (user_id)
SELECT id FROM users WHERE email IN ('test@example.com', 'demo@example.com')
ON CONFLICT (user_id) DO NOTHING;

\echo 'Test data seeded successfully!'
\echo 'Test credentials:'
\echo '  Email: test@example.com'
\echo '  Email: demo@example.com'
