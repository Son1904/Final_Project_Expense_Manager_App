/// Category Model - Represents category data from API
class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;
  final bool isDefault;
  final String? userId;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.isDefault,
    this.userId,
    required this.createdAt,
  });

  /// Create CategoryModel from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'expense',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      createdAt: () {
        try {
          final createdAtStr = json['createdAt'] as String?;
          final createdAtSnake = json['created_at'] as String?;
          if (createdAtStr != null) return DateTime.parse(createdAtStr);
          if (createdAtSnake != null) return DateTime.parse(createdAtSnake);
        } catch (e) {
          print('Error parsing createdAt: $e');
        }
        return DateTime.now();
      }(),
    );
  }

  /// Convert CategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isDefault,
    String? userId,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if category is income
  bool get isIncome => type == 'income';

  /// Check if category is expense
  bool get isExpense => type == 'expense';

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: $type, isDefault: $isDefault)';
  }
}
