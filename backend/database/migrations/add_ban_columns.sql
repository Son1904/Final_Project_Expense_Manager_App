-- Add Ban Columns to Users Table
-- Adds is_banned and ban_reason columns for user suspension functionality

-- Step 1: Add columns
ALTER TABLE users 
ADD COLUMN is_banned BOOLEAN DEFAULT false,
ADD COLUMN ban_reason TEXT;

-- Step 2: Add index for faster filtering of banned users
CREATE INDEX idx_users_is_banned ON users(is_banned);

-- Verify the changes
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name IN ('is_banned', 'ban_reason');
