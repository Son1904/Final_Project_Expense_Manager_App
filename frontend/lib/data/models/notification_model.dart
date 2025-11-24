class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String priority;
  final bool isRead;
  final String referenceType;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.isRead,
    required this.referenceType,
    this.referenceId,
    this.metadata,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      isRead: json['isRead'] ?? false,
      referenceType: json['referenceType'] ?? 'NONE',
      referenceId: json['referenceId'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'priority': priority,
      'isRead': isRead,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? priority,
    bool? isRead,
    String? referenceType,
    String? referenceId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper method to get icon based on type
  String getIcon() {
    switch (type) {
      case 'BUDGET_EXCEEDED':
        return '🔴';
      case 'BUDGET_WARNING':
        return '🟡';
      case 'BUDGET_ON_TRACK':
        return '🟢';
      case 'RECURRING_UPCOMING':
      case 'RECURRING_MISSED':
        return '📅';
      case 'WEEKLY_SUMMARY':
      case 'MONTHLY_SUMMARY':
        return '📊';
      case 'GOAL_ACHIEVED':
        return '🏆';
      case 'LARGE_TRANSACTION':
        return '⚠️';
      case 'SPENDING_SPIKE':
        return '📉';
      case 'SAVINGS_TIP':
        return '💡';
      case 'ACHIEVEMENT':
        return '🎉';
      case 'SYSTEM':
        return '✅';
      default:
        return '🔔';
    }
  }

  // Helper method to get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Helper method to group notifications by date
  static String getDateGroup(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'TODAY';
    } else if (difference.inDays == 1) {
      return 'YESTERDAY';
    } else {
      return 'EARLIER';
    }
  }
}
