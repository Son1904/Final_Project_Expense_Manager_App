const express = require('express');
const {
  getNotificationPreferences,
  updateNotificationPreferences,
} = require('../controllers/settingsController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Notification preferences
router.get('/notifications', getNotificationPreferences);
router.put('/notifications', updateNotificationPreferences);

module.exports = router;
