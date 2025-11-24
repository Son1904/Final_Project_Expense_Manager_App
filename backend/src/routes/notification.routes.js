const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middleware/auth.middleware');

// Apply authentication middleware to all routes
router.use(authenticate);

// Get all notifications
router.get('/', notificationController.getNotifications);

// Get unread count
router.get('/unread-count', notificationController.getUnreadCount);

// Mark all as read
router.patch('/mark-all-read', notificationController.markAllAsRead);

// Clear all notifications (must be before /:id routes)
router.delete('/clear-all', notificationController.clearAll);

// Mark notification as read
router.patch('/:id/read', notificationController.markAsRead);

// Delete notification
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
