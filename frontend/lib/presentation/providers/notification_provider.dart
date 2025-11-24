import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationProvider({required ApiService apiService})
      : _apiService = apiService;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get notifications grouped by date
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER': [],
    };

    for (var notification in _notifications) {
      final group = NotificationModel.getDateGroup(notification.createdAt);
      grouped[group]?.add(notification);
    }

    return grouped;
  }

  // Load notifications
  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _apiService.get(
        '/api/notifications',
        queryParameters: {'limit': '50'},
      );

      if (response.data['success']) {
        _notifications = (response.data['data'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _unreadCount = response.data['unreadCount'] ?? 0;
        _error = null;
      } else {
        _error = response.data['message'] ?? 'Failed to load notifications';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load unread count only
  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.get('/api/notifications/unread-count');

      if (response.data['success']) {
        _unreadCount = response.data['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response =
          await _apiService.patch('/api/notifications/$notificationId/read');

      if (response.data['success']) {
        // Update local state
        final index =
            _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final response =
          await _apiService.patch('/api/notifications/mark-all-read');

      if (response.data['success']) {
        // Update local state
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      throw e;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response =
          await _apiService.delete('/api/notifications/$notificationId');

      if (response.data['success']) {
        // Update local state
        final notification =
            _notifications.firstWhere((n) => n.id == notificationId);
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw e;
    }
  }

  // Clear all notifications
  Future<void> clearAll() async {
    try {
      final response = await _apiService.delete('/api/notifications/clear-all');

      if (response.data['success']) {
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      throw e;
    }
  }

  // Refresh notifications (silent reload)
  Future<void> refresh() async {
    await loadNotifications(showLoading: false);
  }
}
