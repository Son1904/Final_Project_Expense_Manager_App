import 'category_model.dart';

/// Transaction Model - Represents transaction data from API
class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryId;
  final DateTime date;
  final String? description;
  final String? paymentMethod;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated category (optional, from API response)
  final CategoryModel? category;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.description,
    this.paymentMethod,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  /// Create TransactionModel from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Extract category ID from either category object or category_id field
    String categoryId;
    if (json['category'] is Map<String, dynamic>) {
      // Backend sends populated category object with _id inside
      categoryId = (json['category'] as Map<String, dynamic>)['_id'] as String;
    } else if (json['category'] is String) {
      // Backend sends category as string ID
      categoryId = json['category'] as String;
    } else {
      // Fallback to old snake_case format
      categoryId = json['category_id'] as String? ?? '';
    }

    return TransactionModel(
      id: json['_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      categoryId: categoryId,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert TransactionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'payment_method': paymentMethod,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
    };
  }

  /// Create a copy with modified fields
  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? categoryId,
    DateTime? date,
    String? description,
    String? paymentMethod,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  /// Check if transaction is income
  bool get isIncome => type == 'income';

  /// Check if transaction is expense
  bool get isExpense => type == 'expense';

  /// Get category name (from populated category)
  String? get categoryName => category?.name;

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, type: $type, date: $date)';
  }
}
