import 'category_model.dart';

/// Budget Model - Represents budget data from API
class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final double spent;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final List<CategoryModel> categories;
  final double alertThreshold;
  final bool alertEnabled;
  final bool isActive;
  final bool repeatAutomatically;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated fields (from backend virtuals)
  final double? remaining;
  final double? percentageUsed;
  final String? status; // 'ok', 'warning', 'exceeded'
  final bool? needsAlert;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.alertThreshold,
    required this.alertEnabled,
    required this.isActive,
    required this.repeatAutomatically,
    required this.createdAt,
    required this.updatedAt,
    this.remaining,
    this.percentageUsed,
    this.status,
    this.needsAlert,
  });

  /// Create BudgetModel from JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    // Parse categories - can be array of objects or array of strings
    List<CategoryModel> categoryList = [];
    try {
      if (json['categories'] != null) {
        final cats = json['categories'];
        if (cats is List) {
          for (var cat in cats) {
            if (cat is Map<String, dynamic>) {
              // Categories are populated objects
              try {
                categoryList.add(CategoryModel.fromJson(cat));
              } catch (e) {
                print('Error parsing category object: $e');
              }
            } else if (cat is String) {
              // Categories are just IDs - create minimal CategoryModel objects
              categoryList.add(CategoryModel(
                id: cat,
                name: '', // Will be populated separately
                type: 'expense',
                isDefault: false,
                createdAt: DateTime.now(),
              ));
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing categories in BudgetModel: $e');
      categoryList = [];
    }

    return BudgetModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? 'monthly',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now(),
      categories: categoryList,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 80.0,
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      repeatAutomatically: json['repeatAutomatically'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      remaining: (json['remaining'] as num?)?.toDouble(),
      percentageUsed: (json['percentageUsed'] as num?)?.toDouble(),
      status: json['status'] as String?,
      needsAlert: json['needsAlert'] as bool?,
    );
  }

  /// Convert BudgetModel to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'categories': categories.map((cat) => cat.id).toList(),
      'alertThreshold': alertThreshold,
      'alertEnabled': alertEnabled,
      'repeatAutomatically': repeatAutomatically,
    };
  }

  /// Create a copy with modified fields
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    double? spent,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    List<CategoryModel>? categories,
    double? alertThreshold,
    bool? alertEnabled,
    bool? isActive,
    bool? repeatAutomatically,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? remaining,
    double? percentageUsed,
    String? status,
    bool? needsAlert,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      isActive: isActive ?? this.isActive,
      repeatAutomatically: repeatAutomatically ?? this.repeatAutomatically,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remaining: remaining ?? this.remaining,
      percentageUsed: percentageUsed ?? this.percentageUsed,
      status: status ?? this.status,
      needsAlert: needsAlert ?? this.needsAlert,
    );
  }

  /// Calculate remaining amount if not provided by backend
  double getRemaining() {
    return remaining ?? (amount - spent).clamp(0.0, double.infinity);
  }

  /// Calculate percentage used if not provided by backend
  double getPercentageUsed() {
    return percentageUsed ?? (amount > 0 ? (spent / amount) * 100 : 0.0);
  }

  /// Get status if not provided by backend
  String getStatus() {
    if (status != null) return status!;
    final percentage = getPercentageUsed();
    if (percentage >= 100) return 'exceeded';
    if (percentage >= alertThreshold) return 'warning';
    return 'ok';
  }

  /// Check if alert is needed
  bool shouldAlert() {
    return needsAlert ?? (alertEnabled && getPercentageUsed() >= alertThreshold);
  }

  /// Check if budget is currently active (within date range)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get formatted period label
  String get periodLabel {
    switch (period) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'custom':
        return 'Custom';
      default:
        return period;
    }
  }

  /// Get category names as comma-separated string
  String get categoryNames {
    if (categories.isEmpty) return 'All Categories';
    return categories.map((cat) => cat.name).join(', ');
  }

  /// Check if budget has specific category
  bool hasCategory(String categoryId) {
    return categories.any((cat) => cat.id == categoryId);
  }

  /// Get days remaining in budget period
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get total days in budget period
  int get totalDays {
    return endDate.difference(startDate).inDays;
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, name: $name, amount: $amount, spent: $spent, status: ${getStatus()})';
  }
}

/// Budget creation request model
class CreateBudgetRequest {
  final String name;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categoryIds;
  final double alertThreshold;
  final bool alertEnabled;
  final bool repeatAutomatically;

  CreateBudgetRequest({
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.categoryIds,
    this.alertThreshold = 80.0,
    this.alertEnabled = true,
    this.repeatAutomatically = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'categories': categoryIds,
      'alertThreshold': alertThreshold,
      'alertEnabled': alertEnabled,
      'repeatAutomatically': repeatAutomatically,
    };
  }
}

/// Budget update request model
class UpdateBudgetRequest {
  final String? name;
  final double? amount;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final double? alertThreshold;
  final bool? alertEnabled;
  final bool? repeatAutomatically;
  final bool? isActive;

  UpdateBudgetRequest({
    this.name,
    this.amount,
    this.period,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.alertThreshold,
    this.alertEnabled,
    this.repeatAutomatically,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (amount != null) json['amount'] = amount;
    if (period != null) json['period'] = period;
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    if (categoryIds != null) json['categories'] = categoryIds;
    if (alertThreshold != null) json['alertThreshold'] = alertThreshold;
    if (alertEnabled != null) json['alertEnabled'] = alertEnabled;
    if (repeatAutomatically != null) json['repeatAutomatically'] = repeatAutomatically;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }
}
