import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/spending_by_category.dart';
import '../../data/repositories/transaction_repository.dart';

/// Transaction Provider - Manages transaction state
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  TransactionProvider({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository;

  // ==================== STATE ====================

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Summary data
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;

  // Spending by category
  List<SpendingByCategory> _spendingByCategory = [];
  List<SpendingByCategory> get spendingByCategory => _spendingByCategory;

  // Filters
  String? _searchQuery;
  String? _filterType;
  String? _filterCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  String? get searchQuery => _searchQuery;
  String? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  // ==================== FETCH TRANSACTIONS ====================

  /// Fetch all transactions with optional filters
  Future<void> fetchTransactions({
    int? page,
    int? limit,
    String? search,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      _transactions = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final fetchedTransactions = await _transactionRepository.getTransactions(
        page: page,
        limit: limit ?? 50,
        search: search ?? _searchQuery,
        type: type ?? _filterType,
        categoryId: categoryId ?? _filterCategoryId,
        startDate: startDate ?? _filterStartDate,
        endDate: endDate ?? _filterEndDate,
        sortBy: 'date',
        order: 'desc',
      );

      _transactions = fetchedTransactions;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch recent transactions (limited)
  Future<void> fetchRecentTransactions({int limit = 5}) async {
    _setLoading(true);
    _clearError();

    try {
      final fetchedTransactions = await _transactionRepository.getTransactions(
        limit: limit,
        sortBy: 'date',
        order: 'desc',
      );

      _transactions = fetchedTransactions;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FETCH SUMMARY ====================

  /// Fetch transaction summary (income, expense, balance)
  Future<void> fetchSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use provided dates, filter dates, or default to last 30 days
      final effectiveStartDate = startDate ?? 
          _filterStartDate ?? 
          DateTime.now().subtract(const Duration(days: 365));
      final effectiveEndDate = endDate ?? 
          _filterEndDate ?? 
          DateTime.now();

      final summary = await _transactionRepository.getSummary(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      _totalIncome = (summary['income'] as num?)?.toDouble() ?? 0;
      _totalExpense = (summary['expense'] as num?)?.toDouble() ?? 0;
      _balance = (summary['balance'] as num?)?.toDouble() ?? 0;

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ==================== FETCH SPENDING BY CATEGORY ====================

  /// Fetch spending grouped by category
  Future<void> fetchSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use provided dates, filter dates, or default to last 365 days
      final effectiveStartDate = startDate ?? 
          _filterStartDate ?? 
          DateTime.now().subtract(const Duration(days: 365));
      final effectiveEndDate = endDate ?? 
          _filterEndDate ?? 
          DateTime.now();

      final data = await _transactionRepository.getSpendingByCategory(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      _spendingByCategory = data.map((json) => SpendingByCategory.fromJson(json)).toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ==================== CREATE TRANSACTION ====================

  /// Create new transaction
  Future<bool> createTransaction({
    required double amount,
    required String type,
    required String categoryId,
    required DateTime date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newTransaction = await _transactionRepository.createTransaction(
        amount: amount,
        type: type,
        categoryId: categoryId,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        tags: tags,
      );

      // Add to list
      _transactions.insert(0, newTransaction);

      // Refresh summary
      await fetchSummary();

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('ERROR in createTransaction: $e');
      print('STACK TRACE: $stackTrace');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPDATE TRANSACTION ====================

  /// Update existing transaction
  Future<bool> updateTransaction({
    required String id,
    double? amount,
    String? type,
    String? categoryId,
    DateTime? date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedTransaction = await _transactionRepository.updateTransaction(
        id: id,
        amount: amount,
        type: type,
        categoryId: categoryId,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        tags: tags,
      );

      // Update in list
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }

      // Refresh summary
      await fetchSummary();

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== DELETE TRANSACTION ====================

  /// Delete transaction
  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _transactionRepository.deleteTransaction(id);

      // Remove from list
      _transactions.removeWhere((t) => t.id == id);

      // Refresh summary
      await fetchSummary();

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FILTERS ====================

  /// Apply filters and search
  void applyFilters({
    String? search,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _searchQuery = search;
    _filterType = type;
    _filterCategoryId = categoryId;
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    
    // Reload transactions with new filters
    fetchTransactions(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _filterType = null;
    _filterCategoryId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    
    // Reload transactions without filters
    fetchTransactions(refresh: true);
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return _searchQuery != null ||
        _filterType != null ||
        _filterCategoryId != null ||
        _filterStartDate != null ||
        _filterEndDate != null;
  }

  // ==================== REFRESH ALL DATA ====================

  /// Refresh all transaction data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchRecentTransactions(),
      fetchSummary(),
      fetchSpendingByCategory(),
    ]);
  }

  // ==================== HELPER METHODS ====================

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
  }

  /// Get transaction by ID from current list
  TransactionModel? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get transactions by type
  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  /// Get income transactions
  List<TransactionModel> get incomeTransactions =>
      getTransactionsByType('income');

  /// Get expense transactions
  List<TransactionModel> get expenseTransactions =>
      getTransactionsByType('expense');
}
