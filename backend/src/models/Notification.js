const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true
  },
  type: {
    type: String,
    required: true,
    enum: [
      'BUDGET_EXCEEDED',      // Budget exceeded
      'BUDGET_WARNING',       // Budget reached warning threshold (80%)
      'BUDGET_ON_TRACK',      // Budget on track
      'RECURRING_UPCOMING',   // Upcoming recurring transaction
      'RECURRING_MISSED',     // Missed recurring transaction
      'WEEKLY_SUMMARY',       // Weekly summary
      'MONTHLY_SUMMARY',      // Monthly summary
      'GOAL_ACHIEVED',        // Goal achieved
      'LARGE_TRANSACTION',    // Large transaction
      'SPENDING_SPIKE',       // Spending spike
      'SAVINGS_TIP',          // Savings tip
      'ACHIEVEMENT',          // Achievement
      'SYSTEM'                // System notification
    ]
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  priority: {
    type: String,
    enum: ['LOW', 'MEDIUM', 'HIGH'],
    default: 'MEDIUM'
  },
  isRead: {
    type: Boolean,
    default: false
  },
  // Reference data for navigation
  referenceType: {
    type: String,
    enum: ['BUDGET', 'TRANSACTION', 'CATEGORY', 'NONE'],
    default: 'NONE'
  },
  referenceId: {
    type: String,
    default: null
  },
  // Additional metadata
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  readAt: {
    type: Date,
    default: null
  }
});

// Compound index for fast queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

// Method to mark as read
notificationSchema.methods.markAsRead = async function() {
  this.isRead = true;
  this.readAt = new Date();
  return this.save();
};

// Static method to create notification
notificationSchema.statics.createNotification = async function(data) {
  const notification = new this(data);
  return notification.save();
};

// Static method to get unread notifications
notificationSchema.statics.getUnreadCount = async function(userId) {
  return this.countDocuments({ userId, isRead: false });
};

// Static method to mark all as read
notificationSchema.statics.markAllAsRead = async function(userId) {
  return this.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true, readAt: new Date() } }
  );
};

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
