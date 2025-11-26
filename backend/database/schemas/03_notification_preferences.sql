-- Create user_notification_preferences table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_type)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_notification_prefs_user_id ON user_notification_preferences(user_id);

-- Insert default preferences for existing users
INSERT INTO user_notification_preferences (user_id, notification_type, is_enabled)
SELECT id, notification_type, TRUE
FROM users
CROSS JOIN (
    VALUES 
        ('BUDGET_EXCEEDED'),
        ('BUDGET_WARNING'),
        ('BUDGET_ON_TRACK'),
        ('LARGE_TRANSACTION')
) AS types(notification_type)
ON CONFLICT (user_id, notification_type) DO NOTHING;
