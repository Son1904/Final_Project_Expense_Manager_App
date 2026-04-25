import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/recurring_transaction_model.dart';
import 'api_service.dart';

/// Recurring Transaction Service - Handles all recurring-related API calls
class RecurringService {
  final ApiService _apiService;
  final Logger _logger = Logger();

  RecurringService(this._apiService);

  /// Create a new recurring transaction
  Future<RecurringTransactionModel> create(Map<String, dynamic> data) async {
    try {
      _logger.d('Creating recurring transaction');
      final response = await _apiService.post(
        '/api/recurring-transactions',
        data: data,
      );

      if (response.data['status'] == 'success') {
        return RecurringTransactionModel.fromJson(response.data['data']['recurring']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create recurring transaction');
      }
    } on DioException catch (e) {
      _logger.e('Create recurring error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to create recurring transaction. Please try again.');
    } catch (e) {
      _logger.e('Create recurring error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get all recurring transactions
  Future<List<RecurringTransactionModel>> getAll({
    String? frequency,
    String? type,
    bool? active,
  }) async {
    try {
      _logger.d('Fetching recurring transactions');
      final queryParams = <String, dynamic>{};
      if (frequency != null) queryParams['frequency'] = frequency;
      if (type != null) queryParams['type'] = type;
      if (active != null) queryParams['active'] = active.toString();

      final response = await _apiService.get(
        '/api/recurring-transactions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['status'] == 'success') {
        final list = (response.data['data']['recurring'] as List)
            .map((json) => RecurringTransactionModel.fromJson(json))
            .toList();
        _logger.d('Fetched ${list.length} recurring transactions');
        return list;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch recurring transactions');
      }
    } on DioException catch (e) {
      _logger.e('Get recurring error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to fetch recurring transactions. Please try again.');
    } catch (e) {
      _logger.e('Get recurring error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get upcoming recurring transactions
  Future<List<RecurringTransactionModel>> getUpcoming({int days = 7}) async {
    try {
      _logger.d('Fetching upcoming recurring transactions');
      final response = await _apiService.get(
        '/api/recurring-transactions/upcoming',
        queryParameters: {'days': days.toString()},
      );

      if (response.data['status'] == 'success') {
        return (response.data['data']['upcoming'] as List)
            .map((json) => RecurringTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch upcoming');
      }
    } on DioException catch (e) {
      _logger.e('Get upcoming error: ${e.message}');
      throw Exception('Failed to fetch upcoming transactions.');
    } catch (e) {
      _logger.e('Get upcoming error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Update a recurring transaction
  Future<RecurringTransactionModel> update(String id, Map<String, dynamic> data) async {
    try {
      _logger.d('Updating recurring: $id');
      final response = await _apiService.put(
        '/api/recurring-transactions/$id',
        data: data,
      );

      if (response.data['status'] == 'success') {
        return RecurringTransactionModel.fromJson(response.data['data']['recurring']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update');
      }
    } on DioException catch (e) {
      _logger.e('Update recurring error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to update. Please try again.');
    } catch (e) {
      _logger.e('Update recurring error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Toggle pause/resume
  Future<RecurringTransactionModel> toggle(String id) async {
    try {
      _logger.d('Toggling recurring: $id');
      final response = await _apiService.patch('/api/recurring-transactions/$id/toggle');

      if (response.data['status'] == 'success') {
        return RecurringTransactionModel.fromJson(response.data['data']['recurring']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to toggle');
      }
    } on DioException catch (e) {
      _logger.e('Toggle recurring error: ${e.message}');
      throw Exception('Failed to toggle. Please try again.');
    } catch (e) {
      _logger.e('Toggle recurring error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Delete a recurring transaction
  Future<void> delete(String id) async {
    try {
      _logger.d('Deleting recurring: $id');
      final response = await _apiService.delete('/api/recurring-transactions/$id');

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to delete');
      }
    } on DioException catch (e) {
      _logger.e('Delete recurring error: ${e.message}');
      throw Exception('Failed to delete. Please try again.');
    } catch (e) {
      _logger.e('Delete recurring error: $e');
      throw Exception('An unexpected error occurred');
    }
  }
}
