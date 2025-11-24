import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';

/// API Service - Handles all HTTP requests using Dio
class ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          ApiConstants.contentType: ApiConstants.applicationJson,
          ApiConstants.accept: ApiConstants.applicationJson,
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_loggingInterceptor());
  }

  /// Logging interceptor - Logs all requests and responses
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
        _logger.d('Headers: ${options.headers}');
        _logger.d('Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        _logger.i('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        _logger.e('Message: ${error.message}');
        _logger.e('Data: ${error.response?.data}');
        return handler.next(error);
      },
    );
  }

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers[ApiConstants.authorization] = ApiConstants.bearer(token);
    _logger.d('Auth token set');
  }

  /// Remove authorization token
  void removeAuthToken() {
    _dio.options.headers.remove(ApiConstants.authorization);
    _logger.d('Auth token removed');
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      _logger.e('GET request failed: $e');
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      _logger.e('PUT request failed: $e');
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      _logger.e('DELETE request failed: $e');
      rethrow;
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      _logger.e('PATCH request failed: $e');
      rethrow;
    }
  }
}
