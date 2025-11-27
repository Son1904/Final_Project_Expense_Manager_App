import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';
import '../../core/constants/api_constants.dart';

/// Category Repository - Handles category operations
class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository({required ApiService apiService})
      : _apiService = apiService;

  // GET ALL CATEGORIES 

  /// Get all categories (default + custom)
  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams[ApiConstants.typeParam] = type;

      final response = await _apiService.get(
        ApiConstants.categories,
        queryParameters: queryParams,
      );

      final categories = response.data['data']['categories'] as List;
      return categories
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET CATEGORY BY ID 

  /// Get single category by ID
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _apiService.get(ApiConstants.categoryById(id));

      return CategoryModel.fromJson(
          response.data['data']['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // CREATE CATEGORY 

  /// Create new custom category
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.categories,
        data: {
          'name': name,
          'type': type,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
        },
      );

      return CategoryModel.fromJson(
          response.data['data']['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // UPDATE CATEGORY 

  /// Update category (custom only)
  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (icon != null) data['icon'] = icon;
      if (color != null) data['color'] = color;

      final response = await _apiService.put(
        ApiConstants.categoryById(id),
        data: data,
      );

      return CategoryModel.fromJson(
          response.data['data']['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE CATEGORY 

  /// Delete category (custom only)
  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.delete(ApiConstants.categoryById(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ERROR HANDLING 

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
