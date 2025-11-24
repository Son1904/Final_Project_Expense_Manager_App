/**
 * Settings Controller
 * Handles user notification preferences and other settings
 */

const { getPgPool } = require('../config/database');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const logger = require('../utils/logger');

// Notification types supported
const NOTIFICATION_TYPES = [
  'BUDGET_EXCEEDED',
  'BUDGET_WARNING',
  'BUDGET_ON_TRACK',
  'LARGE_TRANSACTION'
];

/**
 * Get user notification preferences
 * @route GET /api/settings/notifications
 * @access Private
 * @returns {object} Notification preferences
 */
const getNotificationPreferences = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const pool = getPgPool();

  // Create table if not exists (migration fallback)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS user_notification_preferences (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      notification_type VARCHAR(50) NOT NULL,
      is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, notification_type)
    )
  `);

  // Get user preferences
  const result = await pool.query(
    'SELECT notification_type, is_enabled FROM user_notification_preferences WHERE user_id = $1',
    [userId]
  );

  // If no preferences exist, create defaults
  if (result.rows.length === 0) {
    const insertPromises = NOTIFICATION_TYPES.map(type =>
      pool.query(
        'INSERT INTO user_notification_preferences (user_id, notification_type, is_enabled) VALUES ($1, $2, $3) ON CONFLICT (user_id, notification_type) DO NOTHING',
        [userId, type, true]
      )
    );
    await Promise.all(insertPromises);

    // Return defaults
    const preferences = {};
    NOTIFICATION_TYPES.forEach(type => {
      preferences[type] = true;
    });

    return res.json({
      success: true,
      data: preferences
    });
  }

  // Convert array to object
  const preferences = {};
  result.rows.forEach(row => {
    preferences[row.notification_type] = row.is_enabled;
  });

  // Ensure all types are present
  NOTIFICATION_TYPES.forEach(type => {
    if (preferences[type] === undefined) {
      preferences[type] = true;
    }
  });

  res.json({
    success: true,
    data: preferences
  });
});

/**
 * Update user notification preferences
 * @route PUT /api/settings/notifications
 * @access Private
 * @param {object} preferences - Object with notification types as keys and boolean values
 * @returns {object} Updated preferences
 */
const updateNotificationPreferences = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { preferences } = req.body;

  if (!preferences || typeof preferences !== 'object') {
    throw new AppError('Preferences object is required', 400);
  }

  const pool = getPgPool();

  // Update each preference
  const updatePromises = Object.entries(preferences).map(([type, isEnabled]) => {
    if (!NOTIFICATION_TYPES.includes(type)) {
      return null; // Skip invalid types
    }

    return pool.query(
      `INSERT INTO user_notification_preferences (user_id, notification_type, is_enabled, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (user_id, notification_type)
       DO UPDATE SET is_enabled = $3, updated_at = NOW()`,
      [userId, type, isEnabled]
    );
  });

  await Promise.all(updatePromises.filter(p => p !== null));

  logger.info(`User ${userId} updated notification preferences`);

  res.json({
    success: true,
    message: 'Notification preferences updated successfully',
    data: preferences
  });
});

/**
 * Get user notification preference for a specific type
 * Helper function for internal use
 * @param {string} userId - User ID
 * @param {string} notificationType - Type of notification
 * @returns {boolean} Whether notification is enabled
 */
async function isNotificationEnabled(userId, notificationType) {
  try {
    const pool = getPgPool();
    const result = await pool.query(
      'SELECT is_enabled FROM user_notification_preferences WHERE user_id = $1 AND notification_type = $2',
      [userId, notificationType]
    );

    // If no preference exists, default to enabled
    if (result.rows.length === 0) {
      return true;
    }

    return result.rows[0].is_enabled;
  } catch (error) {
    logger.error(`Error checking notification preference: ${error.message}`);
    // Default to enabled if there's an error
    return true;
  }
}

module.exports = {
  getNotificationPreferences,
  updateNotificationPreferences,
  isNotificationEnabled,
};
