import 'package:flutter/foundation.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/services/recurring_service.dart';

/// Recurring Provider - Manages recurring transaction state
class RecurringProvider extends ChangeNotifier {
  final RecurringService _service;

  RecurringProvider({required RecurringService service}) : _service = service;

  // STATE
  List<RecurringTransactionModel> _items = [];
  List<RecurringTransactionModel> get items => _items;

  List<RecurringTransactionModel> _upcoming = [];
  List<RecurringTransactionModel> get upcoming => _upcoming;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // GETTERS
  List<RecurringTransactionModel> get activeItems =>
      _items.where((item) => item.isActive).toList();

  List<RecurringTransactionModel> get pausedItems =>
      _items.where((item) => !item.isActive).toList();

  List<RecurringTransactionModel> get incomeItems =>
      _items.where((item) => item.isIncome).toList();

  List<RecurringTransactionModel> get expenseItems =>
      _items.where((item) => item.isExpense).toList();

  // FETCH
  Future<void> fetchAll({bool refresh = false}) async {
    if (refresh) _items = [];
    _setLoading(true);
    _clearError();

    try {
      _items = await _service.getAll();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUpcoming({int days = 7}) async {
    try {
      _upcoming = await _service.getUpcoming(days: days);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // CREATE
  Future<bool> create(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      final item = await _service.create(data);
      _items.insert(0, item);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // UPDATE
  Future<bool> update(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _service.update(id, data);
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // TOGGLE
  Future<bool> toggle(String id) async {
    _clearError();

    try {
      final updated = await _service.toggle(id);
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // DELETE
  Future<bool> delete(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.delete(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // HELPERS
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

  void clearAll() {
    _items = [];
    _upcoming = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
