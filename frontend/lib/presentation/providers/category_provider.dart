import 'package:flutter/foundation.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

/// Category Provider - Manages category state
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  CategoryProvider({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository;

  // ==================== STATE ====================

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================== FETCH CATEGORIES ====================

  /// Fetch all categories
  Future<void> fetchCategories({String? type}) async {
    _setLoading(true);
    _clearError();

    try {
      _categories = await _categoryRepository.getCategories(type: type);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ==================== GET CATEGORIES BY TYPE ====================

  /// Get income categories
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  /// Get expense categories
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  // ==================== CREATE CATEGORY ====================

  /// Create new category
  Future<bool> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newCategory = await _categoryRepository.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );

      _categories.add(newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPDATE CATEGORY ====================

  /// Update category
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedCategory = await _categoryRepository.updateCategory(
        id: id,
        name: name,
        icon: icon,
        color: color,
      );

      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
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

  // ==================== DELETE CATEGORY ====================

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
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

  /// Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
