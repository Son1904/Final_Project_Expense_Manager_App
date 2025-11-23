class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://localhost:3000';
  static const String apiVersion = '/api';
  
  // Endpoints
  // Auth
  static const String register = '$apiVersion/auth/register';
  static const String login = '$apiVersion/auth/login';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String logout = '$apiVersion/auth/logout';
  static const String profile = '$apiVersion/auth/profile';

  // Categories
  static const String categories = '$apiVersion/categories';
  static String categoryById(String id) => '$categories/$id';

  // Transactions
  static const String transactions = '$apiVersion/transactions';
  static String transactionById(String id) => '$transactions/$id';
  static const String transactionSummary = '$transactions/summary';
  static const String spendingByCategory = '$transactions/spending-by-category';

  // Headers
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String accept = 'Accept';

  // Header Values
  static const String applicationJson = 'application/json';
  static String bearer(String token) => 'Bearer $token';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultPage = 1;

  // Query Parameters
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String typeParam = 'type';
  static const String categoryParam = 'category';
  static const String startDateParam = 'startDate';
  static const String endDateParam = 'endDate';
  static const String sortByParam = 'sortBy';
  static const String orderParam = 'order';
}
