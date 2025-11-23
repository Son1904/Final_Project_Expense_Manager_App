/// Model for spending grouped by category
class SpendingByCategory {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double total;
  final int count;

  SpendingByCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.total,
    required this.count,
  });

  factory SpendingByCategory.fromJson(Map<String, dynamic> json) {
    return SpendingByCategory(
      categoryId: json['_id'] ?? '',
      categoryName: json['categoryName'] ?? 'Unknown',
      categoryIcon: json['categoryIcon'] ?? 'help_outline',
      categoryColor: json['categoryColor'] ?? '#9E9E9E',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'total': total,
      'count': count,
    };
  }
}
