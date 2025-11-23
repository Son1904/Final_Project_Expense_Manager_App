import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

/// Storage Service - Handles local data storage
/// Uses SharedPreferences for general data and FlutterSecureStorage for tokens
class StorageService {
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Initialize storage - Must be called before using any methods
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  //TOKEN MANAGEMENT 

  /// Save access token (secure storage)
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: ApiConstants.accessTokenKey,
      value: token,
    );
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: ApiConstants.accessTokenKey);
  }

  /// Save refresh token (secure storage)
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: ApiConstants.refreshTokenKey,
      value: token,
    );
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: ApiConstants.refreshTokenKey);
  }

  /// Remove all tokens
  Future<void> removeTokens() async {
    await _secureStorage.delete(key: ApiConstants.accessTokenKey);
    await _secureStorage.delete(key: ApiConstants.refreshTokenKey);
  }

  //USER DATA 

  /// Save user data as JSON string
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _prefs.setString(ApiConstants.userKey, jsonString);
  }

  /// Get user data
  Map<String, dynamic>? getUserData() {
    final jsonString = _prefs.getString(ApiConstants.userKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Remove user data
  Future<void> removeUserData() async {
    await _prefs.remove(ApiConstants.userKey);
  }

  //LOGIN STATUS 

  /// Set login status
  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(ApiConstants.isLoggedInKey, value);
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(ApiConstants.isLoggedInKey) ?? false;
  }

  //CLEAR ALL DATA 

  /// Clear all storage data (logout)
  Future<void> clearAll() async {
    await removeTokens();
    await removeUserData();
    await setLoggedIn(false);
  }

  //GENERIC METHODS 

  /// Save string
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Get string
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save int
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// Get int
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Save bool
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Get bool
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Remove specific key
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
