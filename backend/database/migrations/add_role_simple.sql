-- Simple Admin Role Migration
-- Adds minimal role field to support admin-only dashboard

-- Step 1: Create enum type for user roles
CREATE TYPE user_role AS ENUM ('user', 'admin');

-- Step 2: Add role column to users table
ALTER TABLE users 
ADD COLUMN role user_role DEFAULT 'user' NOT NULL;

-- Step 3: Automatically promote first registered user to admin
-- This ensures there's always at least one admin in the system
UPDATE users 
SET role = 'admin' 
WHERE id = (
    SELECT id FROM users 
    ORDER BY created_at ASC 
    LIMIT 1
);

-- Step 4: Add index for faster role-based queries
CREATE INDEX idx_users_role ON users(role);

-- Verify the changes
SELECT 
    email, 
    full_name, 
    role, 
    created_at
FROM users 
ORDER BY created_at ASC
LIMIT 5;
