/// Model for temporarily storing parsed transaction data from SMS
/// before user confirmation
class ParsedTransaction {
  final double amount;
  final String type; // 'income' or 'expense'
  final String description; // Merchant name from SMS
  final DateTime date;
  final String? bank; // Bank name (VCB, TCB, VPBank, etc.)
  final String? categoryId; // Suggested category ID
  final String? rawSms; // Original SMS text for reference

  ParsedTransaction({
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    this.bank,
    this.categoryId,
    this.rawSms,
  });

  // Create from SMS parser
  factory ParsedTransaction.fromSms({
    required double amount,
    required String type,
    required String description,
    required DateTime date,
    String? bank,
    String? rawSms,
  }) {
    return ParsedTransaction(
      amount: amount,
      type: type,
      description: description,
      date: date,
      bank: bank,
      rawSms: rawSms,
    );
  }

  // Convert to Transaction creation params
  Map<String, dynamic> toTransactionParams() {
    return {
      'amount': amount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
    };
  }

  // Copy with new values
  ParsedTransaction copyWith({
    double? amount,
    String? type,
    String? description,
    DateTime? date,
    String? bank,
    String? categoryId,
    String? rawSms,
  }) {
    return ParsedTransaction(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      bank: bank ?? this.bank,
      categoryId: categoryId ?? this.categoryId,
      rawSms: rawSms ?? this.rawSms,
    );
  }

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, type: $type, description: $description, bank: $bank)';
  }
}
