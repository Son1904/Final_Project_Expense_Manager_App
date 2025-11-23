import '../../data/models/category_model.dart';

/// Service to suggest category based on merchant/description keywords
/// Uses keyword matching to intelligently map merchants to categories
class CategorySuggestionService {
  /// Suggest category ID based on merchant name or description
  /// Returns null if no good match is found
  static String? suggestCategoryId(
    String? merchant,
    String? description,
    List<CategoryModel> availableCategories,
  ) {
    if (availableCategories.isEmpty) return null;

    final text = '${merchant ?? ''} ${description ?? ''}'.toLowerCase();
    if (text.trim().isEmpty) return null;

    // Try to find matching category based on keywords
    for (final category in availableCategories) {
      final keywords = _getCategoryKeywords(category.name);
      for (final keyword in keywords) {
        if (text.contains(keyword.toLowerCase())) {
          return category.id;
        }
      }
    }

    return null;
  }

  /// Get keywords associated with each category
  static List<String> _getCategoryKeywords(String categoryName) {
    final name = categoryName.toLowerCase();

    // Food & Dining
    if (name.contains('food') || name.contains('dining')) {
      return [
        // Coffee shops
        'starbucks',
        'highlands',
        'coffee house',
        'trung nguyen',
        'phuc long',
        'cong caphe',
        'cafe',
        'coffee',
        'caphe',
        
        // Fast food
        'kfc',
        'lotteria',
        'jollibee',
        'pizza',
        'burger king',
        'mcdonald',
        'popeyes',
        'texas chicken',
        
        // Food delivery
        'grab food',
        'grabfood',
        'gojek',
        'shopeefood',
        'baemin',
        'foody',
        
        // Restaurants
        'restaurant',
        'nha hang',
        'quan an',
        'com',
        'pho',
        'bun',
        'banh mi',
        'food court',
        'buffet',
      ];
    }

    // Transportation
    if (name.contains('transport')) {
      return [
        'grab',
        'be',
        'gojek',
        'uber',
        'taxi',
        'xe om',
        'petrolimex',
        'pvoil',
        'xang',
        'gas',
        'fuel',
        'parking',
        'bai do xe',
        'toll',
        'phi duong',
        'vinfast',
        'bus',
        'xe buyt',
        'metro',
        'train',
        'tau',
      ];
    }

    // Shopping
    if (name.contains('shop')) {
      return [
        'vinmart',
        'coopmart',
        'big c',
        'lotte mart',
        'circle k',
        '7-eleven',
        'ministop',
        'family mart',
        'guardian',
        'watsons',
        'pharmacity',
        'uniqlo',
        'h&m',
        'zara',
        'muji',
        'miniso',
        'daiso',
        'shopee',
        'lazada',
        'tiki',
        'sendo',
        'fashion',
        'clothing',
        'shoes',
        'giay',
        'quan ao',
      ];
    }

    // Entertainment
    if (name.contains('entertainment')) {
      return [
        'netflix',
        'spotify',
        'youtube',
        'apple music',
        'zing mp3',
        'cgv',
        'galaxy cinema',
        'lotte cinema',
        'mega gs',
        'cinema',
        'rap phim',
        'game',
        'steam',
        'playstation',
        'xbox',
        'karaoke',
        'bar',
        'club',
        'gym',
        'fitness',
        'yoga',
      ];
    }

    // Bills & Utilities
    if (name.contains('bill') || name.contains('utilit')) {
      return [
        'evn',
        'dien',
        'electricity',
        'water',
        'nuoc',
        'vnpt',
        'viettel',
        'fpt',
        'mobifone',
        'vinaphone',
        'internet',
        'wifi',
        'gas',
        'petrovietnam gas',
        'pvgas',
        'apartment',
        'can ho',
        'management fee',
        'phi quan ly',
      ];
    }

    // Healthcare
    if (name.contains('health')) {
      return [
        'hospital',
        'benh vien',
        'clinic',
        'phong kham',
        'pharmacy',
        'pharmacity',
        'nha thuoc',
        'doctor',
        'bac si',
        'dental',
        'nha khoa',
        'medicine',
        'thuoc',
        'insurance',
        'bao hiem',
        'vaccination',
        'tiem chung',
      ];
    }

    // Education
    if (name.contains('educat')) {
      return [
        'school',
        'truong',
        'university',
        'dai hoc',
        'course',
        'khoa hoc',
        'tuition',
        'hoc phi',
        'book',
        'sach',
        'fahasa',
        'phuong nam',
        'udemy',
        'coursera',
        'skillshare',
        'english',
        'tieng anh',
      ];
    }

    // Salary (Income)
    if (name.contains('salary')) {
      return [
        'salary',
        'luong',
        'wage',
        'payroll',
        'cong ty',
        'company',
      ];
    }

    // Freelance (Income)
    if (name.contains('freelance')) {
      return [
        'freelance',
        'upwork',
        'fiverr',
        'project',
        'du an',
        'contract',
        'hop dong',
      ];
    }

    // Investment (Income)
    if (name.contains('invest')) {
      return [
        'stock',
        'co phieu',
        'dividend',
        'co tuc',
        'bond',
        'trai phieu',
        'fund',
        'quy',
        'crypto',
        'bitcoin',
      ];
    }

    // Gift (Income)
    if (name.contains('gift')) {
      return [
        'gift',
        'qua',
        'lucky money',
        'li xi',
        'bonus',
        'thuong',
      ];
    }

    // Default: return category name itself as keyword
    return [name];
  }

  /// Get suggested category name (for display purposes)
  static String? suggestCategoryName(
    String? merchant,
    String? description,
    List<CategoryModel> availableCategories,
  ) {
    final categoryId = suggestCategoryId(merchant, description, availableCategories);
    if (categoryId == null) return null;

    return availableCategories
        .firstWhere((cat) => cat.id == categoryId, orElse: () => availableCategories.first)
        .name;
  }

  /// Check if a merchant matches a specific category
  static bool matchesCategory(
    String? merchant,
    String categoryName,
  ) {
    if (merchant == null || merchant.isEmpty) return false;

    final keywords = _getCategoryKeywords(categoryName);
    final merchantLower = merchant.toLowerCase();

    return keywords.any((keyword) => merchantLower.contains(keyword.toLowerCase()));
  }
}
