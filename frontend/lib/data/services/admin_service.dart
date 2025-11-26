import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  /// Get system overview statistics
  Future<Map<String, dynamic>> getSystemOverview() async {
    try {
      final response = await _apiService.get('/api/admin/stats/overview');
      return response.data['data']['overview'];
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users with pagination and search
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': search,
        },
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle user ban status
  Future<bool> toggleBanUser(String userId, String? reason) async {
    try {
      final response = await _apiService.patch(
        '/api/admin/users/$userId/ban',
        data: {'reason': reason},
      );
      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _apiService.delete('/api/admin/users/$userId');
      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }
}
