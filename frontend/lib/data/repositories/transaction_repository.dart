import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import '../../core/constants/api_constants.dart';

/// Transaction Repository - Handles transaction operations
class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository({required ApiService apiService})
      : _apiService = apiService;

  // ==================== CREATE TRANSACTION ====================

  /// Create new transaction
  Future<TransactionModel> createTransaction({
    required double amount,
    required String type,
    required String categoryId,
    required DateTime date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.transactions,
        data: {
          'amount': amount,
          'type': type,
          'category': categoryId,
          'date': date.toIso8601String(),
          if (description != null) 'description': description,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (tags != null) 'tags': tags,
        },
      );

      return TransactionModel.fromJson(
          response.data['data']['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== GET TRANSACTIONS ====================

  /// Get all transactions with filters
  Future<List<TransactionModel>> getTransactions({
    int? page,
    int? limit,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams[ApiConstants.pageParam] = page;
      if (limit != null) queryParams[ApiConstants.limitParam] = limit;
      if (type != null) queryParams[ApiConstants.typeParam] = type;
      if (categoryId != null) {
        queryParams[ApiConstants.categoryParam] = categoryId;
      }
      if (startDate != null) {
        queryParams[ApiConstants.startDateParam] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams[ApiConstants.endDateParam] = endDate.toIso8601String();
      }
      if (sortBy != null) queryParams[ApiConstants.sortByParam] = sortBy;
      if (order != null) queryParams[ApiConstants.orderParam] = order;

      final response = await _apiService.get(
        ApiConstants.transactions,
        queryParameters: queryParams,
      );

      final transactions = response.data['data']['transactions'] as List;
      return transactions
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== GET TRANSACTION BY ID ====================

  /// Get single transaction by ID
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final response =
          await _apiService.get(ApiConstants.transactionById(id));

      return TransactionModel.fromJson(
          response.data['data']['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== UPDATE TRANSACTION ====================

  /// Update transaction
  Future<TransactionModel> updateTransaction({
    required String id,
    double? amount,
    String? type,
    String? categoryId,
    DateTime? date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (amount != null) data['amount'] = amount;
      if (type != null) data['type'] = type;
      if (categoryId != null) data['category'] = categoryId;
      if (date != null) data['date'] = date.toIso8601String();
      if (description != null) data['description'] = description;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (tags != null) data['tags'] = tags;

      final response = await _apiService.put(
        ApiConstants.transactionById(id),
        data: data,
      );

      return TransactionModel.fromJson(
          response.data['data']['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== DELETE TRANSACTION ====================

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _apiService.delete(ApiConstants.transactionById(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== GET SUMMARY ====================

  /// Get transaction summary (income, expense, balance)
  Future<Map<String, dynamic>> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams[ApiConstants.startDateParam] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams[ApiConstants.endDateParam] = endDate.toIso8601String();
      }

      final response = await _apiService.get(
        ApiConstants.transactionSummary,
        queryParameters: queryParams,
      );

      return response.data['data']['summary'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== GET SPENDING BY CATEGORY ====================

  /// Get spending grouped by category
  Future<List<Map<String, dynamic>>> getSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams[ApiConstants.startDateParam] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams[ApiConstants.endDateParam] = endDate.toIso8601String();
      }

      final response = await _apiService.get(
        ApiConstants.spendingByCategory,
        queryParameters: queryParams,
      );

      final spending = response.data['data']['spending'] as List;
      return spending.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Handle Dio errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Could not connect to server';
    } else {
      return 'Unknown error: ${error.message}';
    }
  }
}
