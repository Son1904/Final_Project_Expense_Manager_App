import 'package:intl/intl.dart';

class Formatters {
  // Currency formatter (default USD)
  static String currency(double amount, {String? symbol}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol ?? '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Currency formatter with decimal
  static String currencyWithDecimal(double amount, {String? symbol}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol ?? '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Number formatter
  static String number(double number) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(number);
  }

  // Number with decimal formatter
  static String numberWithDecimal(double number, {int decimalDigits = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}', 'en_US');
    return formatter.format(number);
  }

  // Date formatter
  static String date(DateTime date, {String format = 'MM/dd/yyyy'}) {
    final formatter = DateFormat(format, 'en_US');
    return formatter.format(date);
  }

  // Date time formatter
  static String dateTime(DateTime dateTime, {String format = 'MM/dd/yyyy HH:mm'}) {
    final formatter = DateFormat(format, 'en_US');
    return formatter.format(dateTime);
  }

  // Time formatter
  static String time(DateTime time, {String format = 'HH:mm'}) {
    final formatter = DateFormat(format, 'en_US');
    return formatter.format(time);
  }

  // Relative time formatter (e.g., "2 hours ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Month year formatter
  static String monthYear(DateTime date) {
    final formatter = DateFormat('MMMM yyyy', 'en_US');
    return formatter.format(date);
  }

  // Short date formatter
  static String shortDate(DateTime date) {
    final formatter = DateFormat('MMM dd', 'en_US');
    return formatter.format(date);
  }

  // Full date formatter
  static String fullDate(DateTime date) {
    final formatter = DateFormat('EEEE, MMMM dd, yyyy', 'en_US');
    return formatter.format(date);
  }

  // Compact currency (e.g., 1.5K, 2.3M)
  static String compactCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  // Percentage formatter
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Phone number formatter (International)
  static String phoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      // Format: (xxx) xxx-xxxx
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // Format: +1 (xxx) xxx-xxxx
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Title case
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Truncate text
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }
}
