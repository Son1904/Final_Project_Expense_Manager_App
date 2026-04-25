import 'category_model.dart';

/// Recurring Transaction Model
class RecurringTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryId;
  final String? description;
  final String? paymentMethod;
  final String? notes;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? dayOfWeek;
  final int? dayOfMonth;
  final int? monthOfYear;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextExecutionDate;
  final DateTime? lastExecutedAt;
  final int executionCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated category
  final CategoryModel? category;

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    this.paymentMethod,
    this.notes,
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
    this.monthOfYear,
    required this.startDate,
    this.endDate,
    required this.nextExecutionDate,
    this.lastExecutedAt,
    required this.executionCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    // Extract category ID
    String categoryId;
    if (json['category'] is Map<String, dynamic>) {
      categoryId = (json['category'] as Map<String, dynamic>)['_id'] as String;
    } else if (json['category'] is String) {
      categoryId = json['category'] as String;
    } else {
      categoryId = '';
    }

    return RecurringTransactionModel(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      categoryId: categoryId,
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
      frequency: json['frequency'] as String,
      dayOfWeek: json['dayOfWeek'] as int?,
      dayOfMonth: json['dayOfMonth'] as int?,
      monthOfYear: json['monthOfYear'] as int?,
      startDate: DateTime.parse(json['startDate'] as String).toLocal(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String).toLocal() : null,
      nextExecutionDate: DateTime.parse(json['nextExecutionDate'] as String).toLocal(),
      lastExecutedAt: json['lastExecutedAt'] != null
          ? DateTime.parse(json['lastExecutedAt'] as String).toLocal()
          : null,
      executionCount: json['executionCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'category': categoryId,
      'description': description,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'frequency': frequency,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'monthOfYear': monthOfYear,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  String? get categoryName => category?.name;

  /// Human-readable frequency label
  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Every day';
      case 'weekly':
        return 'Every ${_dayOfWeekName(dayOfWeek ?? 0)}';
      case 'monthly':
        return 'Monthly on the ${_ordinal(dayOfMonth ?? 1)}';
      case 'yearly':
        return 'Yearly on ${_monthName(monthOfYear ?? 1)} ${_ordinal(dayOfMonth ?? 1)}';
      default:
        return frequency;
    }
  }

  static String _dayOfWeekName(int day) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[day % 7];
  }

  static String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month.clamp(1, 12)];
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  @override
  String toString() {
    return 'RecurringTransactionModel(id: $id, amount: $amount, type: $type, frequency: $frequency)';
  }
}
