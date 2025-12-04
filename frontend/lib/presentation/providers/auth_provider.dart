import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';

/// Auth Provider - Manages authentication state
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final ApiService _apiService;

  // State
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthProvider({
    required AuthRepository authRepository,
    required StorageService storageService,
    required ApiService apiService,
  })  : _authRepository = authRepository,
        _storageService = storageService,
        _apiService = apiService;

  // INITIALIZE 

  /// Initialize auth state from storage
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Check if user is logged in
      _isAuthenticated = _authRepository.isLoggedIn();

      if (_isAuthenticated) {
        // Get stored user
        _user = _authRepository.getStoredUser();

        // Set auth token in API service
        final accessToken = await _storageService.getAccessToken();
        if (accessToken != null) {
          _apiService.setAuthToken(accessToken);
        }

        // Optionally refresh user data from server
        // await getProfile();
      }
    } catch (e) {
      _setError('Initialization failed: $e');
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // REGISTER 

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // LOGIN 

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.login(
        email: email,
        password: password,
      );

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      String message = e.toString();
      
      if (e is DioException) {
        final response = e.response;
        if (response?.data != null) {
          if (response!.data is Map) {
            final data = response.data as Map;
            if (data['message'] != null) {
              message = data['message'].toString();
            }
          }
        }
      }
      
      _setError(message);
      _setLoading(false);
      return false;
    }
  }

  // LOGOUT 

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // GET PROFILE 

  /// Get current user profile
  Future<void> getProfile() async {
    try {
      _user = await _authRepository.getProfile();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // CHANGE PASSWORD 

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // REFRESH TOKEN 

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      await _authRepository.refreshAccessToken();
      return true;
    } catch (e) {
      // If refresh fails, logout user
      await logout();
      return false;
    }
  }

  // HELPER METHODS 

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }
}
