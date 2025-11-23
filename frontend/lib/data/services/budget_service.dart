import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/budget_model.dart';
import 'api_service.dart';

/// Budget Service - Handles all budget-related API calls
class BudgetService {
  final ApiService _apiService;
  final Logger _logger = Logger();

  BudgetService(this._apiService);

  /// Create a new budget
  Future<BudgetModel> createBudget(CreateBudgetRequest request) async {
    try {
      _logger.d('Creating budget: ${request.name}');
      final response = await _apiService.post(
        '/api/budgets',
        data: request.toJson(),
      );

      if (response.data['status'] == 'success') {
        return BudgetModel.fromJson(response.data['data']['budget']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create budget');
      }
    } on DioException catch (e) {
      _logger.e('Create budget error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to create budget. Please try again.');
    } catch (e) {
      _logger.e('Create budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get all budgets for the authenticated user
  /// Optional filters: period, active, category
  Future<List<BudgetModel>> getBudgets({
    String? period,
    bool? active,
    String? categoryId,
  }) async {
    try {
      _logger.d('Fetching budgets');
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (active != null) queryParams['active'] = active.toString();
      if (categoryId != null) queryParams['category'] = categoryId;

      final response = await _apiService.get(
        '/api/budgets',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['status'] == 'success') {
        final budgets = (response.data['data']['budgets'] as List)
            .map((json) => BudgetModel.fromJson(json))
            .toList();
        _logger.d('Fetched ${budgets.length} budgets');
        return budgets;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch budgets');
      }
    } on DioException catch (e) {
      _logger.e('Get budgets error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to fetch budgets. Please try again.');
    } catch (e) {
      _logger.e('Get budgets error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get active budgets only
  Future<List<BudgetModel>> getActiveBudgets() async {
    try {
      _logger.d('Fetching active budgets');
      final response = await _apiService.get('/api/budgets/active');

      if (response.data['status'] == 'success') {
        final budgets = (response.data['data']['budgets'] as List)
            .map((json) => BudgetModel.fromJson(json))
            .toList();
        _logger.d('Fetched ${budgets.length} active budgets');
        return budgets;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch active budgets');
      }
    } on DioException catch (e) {
      _logger.e('Get active budgets error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to fetch active budgets. Please try again.');
    } catch (e) {
      _logger.e('Get active budgets error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get budget status summary
  Future<Map<String, dynamic>> getBudgetStatus() async {
    try {
      _logger.d('Fetching budget status');
      final response = await _apiService.get('/api/budgets/status');

      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        return {
          'summary': data['summary'],
          'budgets': {
            'ok': (data['budgets']['ok'] as List)
                .map((json) => BudgetModel.fromJson(json))
                .toList(),
            'warning': (data['budgets']['warning'] as List)
                .map((json) => BudgetModel.fromJson(json))
                .toList(),
            'exceeded': (data['budgets']['exceeded'] as List)
                .map((json) => BudgetModel.fromJson(json))
                .toList(),
          },
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch budget status');
      }
    } on DioException catch (e) {
      _logger.e('Get budget status error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to fetch budget status. Please try again.');
    } catch (e) {
      _logger.e('Get budget status error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Get a single budget by ID
  Future<BudgetModel> getBudgetById(String budgetId) async {
    try {
      _logger.d('Fetching budget: $budgetId');
      final response = await _apiService.get('/api/budgets/$budgetId');

      if (response.data['status'] == 'success') {
        return BudgetModel.fromJson(response.data['data']['budget']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch budget');
      }
    } on DioException catch (e) {
      _logger.e('Get budget error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Budget not found');
      }
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to fetch budget. Please try again.');
    } catch (e) {
      _logger.e('Get budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Update a budget
  Future<BudgetModel> updateBudget(String budgetId, UpdateBudgetRequest request) async {
    try {
      _logger.d('Updating budget: $budgetId');
      final response = await _apiService.put(
        '/api/budgets/$budgetId',
        data: request.toJson(),
      );

      if (response.data['status'] == 'success') {
        return BudgetModel.fromJson(response.data['data']['budget']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update budget');
      }
    } on DioException catch (e) {
      _logger.e('Update budget error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Budget not found');
      }
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to update budget. Please try again.');
    } catch (e) {
      _logger.e('Update budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Delete a budget (soft delete)
  Future<void> deleteBudget(String budgetId) async {
    try {
      _logger.d('Deleting budget: $budgetId');
      final response = await _apiService.delete('/api/budgets/$budgetId');

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to delete budget');
      }
    } on DioException catch (e) {
      _logger.e('Delete budget error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Budget not found');
      }
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to delete budget. Please try again.');
    } catch (e) {
      _logger.e('Delete budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Permanently delete a budget
  Future<void> deleteBudgetPermanently(String budgetId) async {
    try {
      _logger.d('Permanently deleting budget: $budgetId');
      final response = await _apiService.delete('/api/budgets/$budgetId/permanent');

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to delete budget permanently');
      }
    } on DioException catch (e) {
      _logger.e('Permanently delete budget error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Budget not found');
      }
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to delete budget. Please try again.');
    } catch (e) {
      _logger.e('Permanently delete budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Refresh spent amount for a budget
  Future<BudgetModel> refreshBudget(String budgetId) async {
    try {
      _logger.d('Refreshing budget: $budgetId');
      final response = await _apiService.post('/api/budgets/$budgetId/refresh');

      if (response.data['status'] == 'success') {
        return BudgetModel.fromJson(response.data['data']['budget']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to refresh budget');
      }
    } on DioException catch (e) {
      _logger.e('Refresh budget error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Budget not found');
      }
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to refresh budget. Please try again.');
    } catch (e) {
      _logger.e('Refresh budget error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  /// Refresh all active budgets
  Future<int> refreshAllBudgets() async {
    try {
      _logger.d('Refreshing all budgets');
      final response = await _apiService.post('/api/budgets/refresh-all');

      if (response.data['status'] == 'success') {
        return response.data['data']['count'] as int;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to refresh budgets');
      }
    } on DioException catch (e) {
      _logger.e('Refresh all budgets error: ${e.message}');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to refresh budgets. Please try again.');
    } catch (e) {
      _logger.e('Refresh all budgets error: $e');
      throw Exception('An unexpected error occurred');
    }
  }
}
