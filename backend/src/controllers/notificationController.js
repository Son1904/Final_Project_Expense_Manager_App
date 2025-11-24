const Notification = require('../models/Notification');

// Get all notifications for user
exports.getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, isRead } = req.query;
    const userId = req.user.id.toString();

    const query = { userId };
    if (isRead !== undefined) {
      query.isRead = isRead === 'true';
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit))
      .lean();

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.getUnreadCount(userId);

    res.json({
      success: true,
      data: notifications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      },
      unreadCount
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications',
      error: error.message
    });
  }
};

// Get unread count
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id.toString();
    const count = await Notification.getUnreadCount(userId);

    res.json({
      success: true,
      count
    });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch unread count',
      error: error.message
    });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id.toString();

    const notification = await Notification.findOne({ _id: id, userId });
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    await notification.markAsRead();

    res.json({
      success: true,
      data: notification
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
      error: error.message
    });
  }
};

// Mark all as read
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id.toString();

    const result = await Notification.markAllAsRead(userId);

    res.json({
      success: true,
      message: 'All notifications marked as read',
      modifiedCount: result.modifiedCount
    });
  } catch (error) {
    console.error('Error marking all as read:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all as read',
      error: error.message
    });
  }
};

// Delete a notification
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id.toString();

    const notification = await Notification.findOneAndDelete({ _id: id, userId });
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted'
    });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification',
      error: error.message
    });
  }
};

// Clear all notifications
exports.clearAll = async (req, res) => {
  try {
    const userId = req.user.id.toString();

    const result = await Notification.deleteMany({ userId });

    res.json({
      success: true,
      message: 'All notifications cleared',
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Error clearing notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear notifications',
      error: error.message
    });
  }
};

// Helper function to create notification (used by other controllers)
exports.createNotification = async (userId, notificationData) => {
  try {
    return await Notification.createNotification({
      userId,
      ...notificationData
    });
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};
