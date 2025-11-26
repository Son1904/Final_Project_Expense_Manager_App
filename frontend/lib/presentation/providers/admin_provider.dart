import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  AdminProvider(this._adminService);

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _systemOverview;
  List<dynamic> _users = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get systemOverview => _systemOverview;
  List<dynamic> get users => _users;

  /// Load system overview stats
  Future<void> loadSystemOverview() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _systemOverview = await _adminService.getSystemOverview();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get system stats and return them directly
  Future<Map<String, dynamic>> getSystemStats() async {
    await loadSystemOverview();
    if (_error != null) {
      throw Exception(_error);
    }
    return _systemOverview ?? {};
  }

  /// Load users list
  Future<void> loadUsers({String search = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _adminService.getAllUsers(search: search);
      _users = data['users'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle ban status
  Future<bool> toggleBanUser(String userId, String? reason) async {
    try {
      final success = await _adminService.toggleBanUser(userId, reason);
      if (success) {
        // Refresh user list locally
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          final currentStatus = _users[index]['is_banned'] == true;
          _users[index]['is_banned'] = !currentStatus;
          // Update reason locally too
          if (!currentStatus) {
             _users[index]['ban_reason'] = reason;
          } else {
             _users[index]['ban_reason'] = null;
          }
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      final success = await _adminService.deleteUser(userId);
      if (success) {
        // Remove from list locally
        _users.removeWhere((u) => u['id'] == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
