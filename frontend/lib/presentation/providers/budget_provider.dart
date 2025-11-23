import 'package:flutter/foundation.dart';
import '../../data/models/budget_model.dart';
import '../../data/services/budget_service.dart';

/// Budget Provider - Manages budget state
class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService;

  BudgetProvider({required BudgetService budgetService})
      : _budgetService = budgetService;

  // ==================== STATE ====================

  List<BudgetModel> _budgets = [];
  List<BudgetModel> get budgets => _budgets;

  BudgetModel? _selectedBudget;
  BudgetModel? get selectedBudget => _selectedBudget;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Budget status summary
  Map<String, dynamic>? _statusSummary;
  Map<String, dynamic>? get statusSummary => _statusSummary;

  // Filters
  String? _filterPeriod;
  bool? _filterActive;
  String? _filterCategoryId;

  String? get filterPeriod => _filterPeriod;
  bool? get filterActive => _filterActive;
  String? get filterCategoryId => _filterCategoryId;

  // ==================== GETTERS ====================

  /// Get active budgets only
  List<BudgetModel> get activeBudgets {
    return _budgets.where((budget) => budget.isActive).toList();
  }

  /// Get budgets by status
  List<BudgetModel> getBudgetsByStatus(String status) {
    return _budgets.where((budget) => budget.getStatus() == status).toList();
  }

  /// Get budgets that need alerts
  List<BudgetModel> get alertBudgets {
    return _budgets.where((budget) => budget.shouldAlert()).toList();
  }

  /// Count budgets by status
  Map<String, int> get statusCounts {
    final ok = _budgets.where((b) => b.getStatus() == 'ok').length;
    final warning = _budgets.where((b) => b.getStatus() == 'warning').length;
    final exceeded = _budgets.where((b) => b.getStatus() == 'exceeded').length;
    return {'ok': ok, 'warning': warning, 'exceeded': exceeded};
  }

  // ==================== FETCH BUDGETS ====================

  /// Fetch all budgets with optional filters
  Future<void> fetchBudgets({
    String? period,
    bool? active,
    String? categoryId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _budgets = [];
    }

    _setLoading(true);
    _clearError();

    // Update filters
    _filterPeriod = period ?? _filterPeriod;
    _filterActive = active ?? _filterActive;
    _filterCategoryId = categoryId ?? _filterCategoryId;

    try {
      final fetchedBudgets = await _budgetService.getBudgets(
        period: _filterPeriod,
        active: _filterActive,
        categoryId: _filterCategoryId,
      );

      _budgets = fetchedBudgets;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch active budgets only
  Future<void> fetchActiveBudgets({bool refresh = false}) async {
    if (refresh) {
      _budgets = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final fetchedBudgets = await _budgetService.getActiveBudgets();
      _budgets = fetchedBudgets;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch budget status summary
  Future<void> fetchBudgetStatus() async {
    _setLoading(true);
    _clearError();

    try {
      final status = await _budgetService.getBudgetStatus();
      _statusSummary = status;
      
      // Update budgets list with categorized budgets
      final allBudgets = <BudgetModel>[
        ...(status['budgets']['ok'] as List<BudgetModel>),
        ...(status['budgets']['warning'] as List<BudgetModel>),
        ...(status['budgets']['exceeded'] as List<BudgetModel>),
      ];
      _budgets = allBudgets;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch a single budget by ID
  Future<void> fetchBudgetById(String budgetId) async {
    _setLoading(true);
    _clearError();

    try {
      final budget = await _budgetService.getBudgetById(budgetId);
      _selectedBudget = budget;
      
      // Update in list if exists
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        _budgets[index] = budget;
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CREATE BUDGET ====================

  /// Create a new budget
  Future<bool> createBudget(CreateBudgetRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final newBudget = await _budgetService.createBudget(request);
      _budgets.insert(0, newBudget);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPDATE BUDGET ====================

  /// Update an existing budget
  Future<bool> updateBudget(String budgetId, UpdateBudgetRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedBudget = await _budgetService.updateBudget(budgetId, request);
      
      // Update in list
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        _budgets[index] = updatedBudget;
      }
      
      // Update selected budget if it's the same
      if (_selectedBudget?.id == budgetId) {
        _selectedBudget = updatedBudget;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== DELETE BUDGET ====================

  /// Delete a budget (soft delete)
  Future<bool> deleteBudget(String budgetId) async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.deleteBudget(budgetId);
      
      // Remove from list completely
      _budgets.removeWhere((b) => b.id == budgetId);
      
      // Clear selected budget if it was deleted
      if (_selectedBudget?.id == budgetId) {
        _selectedBudget = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Permanently delete a budget
  Future<bool> deleteBudgetPermanently(String budgetId) async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.deleteBudgetPermanently(budgetId);
      
      // Remove from list
      _budgets.removeWhere((b) => b.id == budgetId);
      
      // Clear selected if it's the same
      if (_selectedBudget?.id == budgetId) {
        _selectedBudget = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== REFRESH BUDGETS ====================

  /// Refresh spent amount for a budget
  Future<bool> refreshBudget(String budgetId) async {
    _setLoading(true);
    _clearError();

    try {
      final refreshedBudget = await _budgetService.refreshBudget(budgetId);
      
      // Update in list
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        _budgets[index] = refreshedBudget;
      }
      
      // Update selected budget if it's the same
      if (_selectedBudget?.id == budgetId) {
        _selectedBudget = refreshedBudget;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all active budgets
  Future<bool> refreshAllBudgets() async {
    _setLoading(true);
    _clearError();

    try {
      await _budgetService.refreshAllBudgets();
      
      // Re-fetch all budgets to get updated data
      await fetchBudgets(refresh: true);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FILTERS ====================

  /// Set period filter
  void setPeriodFilter(String? period) {
    _filterPeriod = period;
    notifyListeners();
  }

  /// Set active filter
  void setActiveFilter(bool? active) {
    _filterActive = active;
    notifyListeners();
  }

  /// Set category filter
  void setCategoryFilter(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filterPeriod = null;
    _filterActive = null;
    _filterCategoryId = null;
    notifyListeners();
  }

  // ==================== SELECTED BUDGET ====================

  /// Set selected budget
  void setSelectedBudget(BudgetModel? budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  /// Clear selected budget
  void clearSelectedBudget() {
    _selectedBudget = null;
    notifyListeners();
  }

  // ==================== HELPER METHODS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear all data (useful for logout)
  void clearAll() {
    _budgets = [];
    _selectedBudget = null;
    _statusSummary = null;
    _filterPeriod = null;
    _filterActive = null;
    _filterCategoryId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
