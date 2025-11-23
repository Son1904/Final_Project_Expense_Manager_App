import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

/// Auth Repository - Handles authentication operations
class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  //REGISTER

  /// Register new user
  /// Returns UserModel on success
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,  // Backend expects camelCase
          if (phone != null) 'phone': phone,
        },
      );

      // Parse nested response structure
      final data = response.data['data'] as Map<String, dynamic>;

      // Save tokens
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      
      // Set auth token in API service
      _apiService.setAuthToken(accessToken);

      // Save user data
      final userData = data['user'] as Map<String, dynamic>;
      await _storageService.saveUserData(userData);
      await _storageService.setLoggedIn(true);

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //LOGIN 

  /// Login user
  /// Returns UserModel on success
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      // Parse nested response structure
      final data = response.data['data'] as Map<String, dynamic>;
      
      // Save tokens
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      
      // Set auth token in API service
      _apiService.setAuthToken(accessToken);

      // Save user data
      final userData = data['user'] as Map<String, dynamic>;
      await _storageService.saveUserData(userData);
      await _storageService.setLoggedIn(true);

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //LOGOUT 

  /// Logout user
  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      
      if (refreshToken != null) {
        await _apiService.post(
          ApiConstants.logout,
          data: {'refresh_token': refreshToken},
        );
      }

      // Clear all local data
      await _storageService.clearAll();
      _apiService.removeAuthToken();
    } on DioException catch (e) {
      // Even if API call fails, clear local data
      await _storageService.clearAll();
      _apiService.removeAuthToken();
      throw _handleError(e);
    }
  }

  //GET PROFILE 

  /// Get current user profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      final userData = response.data['user'] as Map<String, dynamic>;
      
      // Update stored user data
      await _storageService.saveUserData(userData);
      
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //REFRESH TOKEN 

  /// Refresh access token
  Future<String> refreshAccessToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final response = await _apiService.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      await _storageService.saveAccessToken(newAccessToken);
      _apiService.setAuthToken(newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      // If refresh fails, logout user
      await _storageService.clearAll();
      _apiService.removeAuthToken();
      throw _handleError(e);
    }     
  }

  //CHECK AUTH STATUS 

  /// Check if user is logged in
  bool isLoggedIn() {
    return _storageService.isLoggedIn();
  }

  /// Get stored user data
  UserModel? getStoredUser() {
    final userData = _storageService.getUserData();
    if (userData == null) return null;
    return UserModel.fromJson(userData);
  }

  //ERROR HANDLING  

  /// Handle Dio errors and return meaningful messages
  String _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
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
