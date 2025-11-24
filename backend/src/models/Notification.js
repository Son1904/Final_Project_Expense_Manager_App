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
      'BUDGET_EXCEEDED',      // Budget vượt quá giới hạn
      'BUDGET_WARNING',       // Budget đạt 80%
      'BUDGET_ON_TRACK',      // Budget đang ổn định
      'RECURRING_UPCOMING',   // Giao dịch định kỳ sắp đến
      'RECURRING_MISSED',     // Giao dịch định kỳ bị bỏ lỡ
      'WEEKLY_SUMMARY',       // Tổng kết tuần
      'MONTHLY_SUMMARY',      // Tổng kết tháng
      'GOAL_ACHIEVED',        // Đạt được mục tiêu
      'LARGE_TRANSACTION',    // Giao dịch lớn
      'SPENDING_SPIKE',       // Chi tiêu tăng đột biến
      'SAVINGS_TIP',          // Mẹo tiết kiệm
      'ACHIEVEMENT',          // Thành tích
      'SYSTEM'                // Thông báo hệ thống
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
  // Reference data cho navigation
  referenceType: {
    type: String,
    enum: ['BUDGET', 'TRANSACTION', 'CATEGORY', 'NONE'],
    default: 'NONE'
  },
  referenceId: {
    type: String,
    default: null
  },
  // Metadata bổ sung
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

// Index compound để query nhanh
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

// Method để đánh dấu đã đọc
notificationSchema.methods.markAsRead = async function() {
  this.isRead = true;
  this.readAt = new Date();
  return this.save();
};

// Static method để tạo notification
notificationSchema.statics.createNotification = async function(data) {
  const notification = new this(data);
  return notification.save();
};

// Static method để lấy notifications chưa đọc
notificationSchema.statics.getUnreadCount = async function(userId) {
  return this.countDocuments({ userId, isRead: false });
};

// Static method để đánh dấu tất cả đã đọc
notificationSchema.statics.markAllAsRead = async function(userId) {
  return this.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true, readAt: new Date() } }
  );
};

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
