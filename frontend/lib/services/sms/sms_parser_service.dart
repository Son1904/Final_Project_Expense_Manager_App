import '../../data/models/parsed_transaction.dart';

/// Service for parsing banking SMS notifications into structured transaction data
/// 
/// Supports multiple Vietnamese banks with different SMS formats:
/// - Vietcombank (VCB)
/// - Techcombank (TCB)
/// - VPBank
/// - ACB
/// - BIDV
class SmsParserService {
  /// Parse SMS text into ParsedTransaction
  /// 
  /// Returns null if SMS format is not recognized or parsing fails
  ParsedTransaction? parseSms(String smsBody, String? sender) {
    if (smsBody.isEmpty) return null;

    // Detect bank from sender or SMS content
    final bank = _detectBank(sender, smsBody);
    if (bank == null) return null;

    // Parse based on detected bank
    switch (bank) {
      case BankType.vietcombank:
        return _parseVietcombank(smsBody);
      case BankType.techcombank:
        return _parseTechcombank(smsBody);
      case BankType.vpbank:
        return _parseVPBank(smsBody);
      case BankType.acb:
        return _parseACB(smsBody);
      case BankType.bidv:
        return _parseBIDV(smsBody);
    }
  }

  /// Detect bank from sender ID or SMS content
  BankType? _detectBank(String? sender, String smsBody) {
    final content = (sender ?? '') + ' ' + smsBody;
    final contentUpper = content.toUpperCase();

    if (contentUpper.contains('VIETCOMBANK') || 
        contentUpper.contains('VCB') ||
        sender?.contains('9254') == true) {
      return BankType.vietcombank;
    }
    
    if (contentUpper.contains('TECHCOMBANK') || 
        contentUpper.contains('TCB') ||
        contentUpper.contains('TCB-EBANK')) {
      return BankType.techcombank;
    }
    
    if (contentUpper.contains('VPBANK') || 
        contentUpper.contains('VPBANKHN')) {
      return BankType.vpbank;
    }
    
    if (contentUpper.contains('ACB') || 
        contentUpper.contains('ACB-BANK')) {
      return BankType.acb;
    }
    
    if (contentUpper.contains('BIDV')) {
      return BankType.bidv;
    }

    return null;
  }

  /// Parse Vietcombank SMS
  /// Format: "TK ...1234 -500,000 VND 21/11/25 14:30. Tai STARBUCKS. SD: 5,234,000 VND"
  ParsedTransaction? _parseVietcombank(String sms) {
    try {
      // Extract amount with sign
      final amountRegex = RegExp(r'([-+]?)(\d{1,3}(?:[,\.]\d{3})*)\s*(?:VND|d)', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) return null;

      final isExpense = amountMatch.group(1) == '-';
      final amountStr = amountMatch.group(2)!.replaceAll(RegExp(r'[,\.]'), '');
      final amount = double.parse(amountStr);

      // Extract merchant/description
      final merchantRegex = RegExp(r'[Tt]ai\s+(.+?)\s*\.', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(sms);
      final merchant = merchantMatch?.group(1)?.trim() ?? 'Vietcombank Transaction';

      // Extract date and time
      final dateRegex = RegExp(r'(\d{2})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2})');
      final dateMatch = dateRegex.firstMatch(sms);
      DateTime date = DateTime.now();
      
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = 2000 + int.parse(dateMatch.group(3)!);
        final hour = int.parse(dateMatch.group(4)!);
        final minute = int.parse(dateMatch.group(5)!);
        date = DateTime(year, month, day, hour, minute);
      }

      return ParsedTransaction(
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        description: merchant,
        date: date,
        bank: 'Vietcombank',
        rawSms: sms,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse Techcombank SMS
  /// Format: "TCB: GD -500,000d Tai: STARBUCKS* Luc 14:30 21/11/25"
  ParsedTransaction? _parseTechcombank(String sms) {
    try {
      // Extract amount
      final amountRegex = RegExp(r'GD\s+([-+]?)(\d{1,3}(?:[,\.]\d{3})*)\s*[dđ]', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) return null;

      final isExpense = amountMatch.group(1) == '-';
      final amountStr = amountMatch.group(2)!.replaceAll(RegExp(r'[,\.]'), '');
      final amount = double.parse(amountStr);

      // Extract merchant
      final merchantRegex = RegExp(r'[Tt]ai:\s*(.+?)(?:\s+[Ll]uc|$)', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(sms);
      final merchant = merchantMatch?.group(1)?.trim().replaceAll('*', '') ?? 'Techcombank Transaction';

      // Extract time
      final timeRegex = RegExp(r'[Ll]uc\s+(\d{2}):(\d{2})\s+(\d{2})/(\d{2})/(\d{2})');
      final timeMatch = timeRegex.firstMatch(sms);
      DateTime date = DateTime.now();
      
      if (timeMatch != null) {
        final hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);
        final day = int.parse(timeMatch.group(3)!);
        final month = int.parse(timeMatch.group(4)!);
        final year = 2000 + int.parse(timeMatch.group(5)!);
        date = DateTime(year, month, day, hour, minute);
      }

      return ParsedTransaction(
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        description: merchant,
        date: date,
        bank: 'Techcombank',
        rawSms: sms,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse VPBank SMS
  /// Format: "VPBank: -500,000 VND Tu TK 12345678 Den STARBUCKS 21/11/2025 14:30"
  ParsedTransaction? _parseVPBank(String sms) {
    try {
      // Extract amount
      final amountRegex = RegExp(r'([-+]?)(\d{1,3}(?:[,\.]\d{3})*)\s*VND', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) return null;

      final isExpense = amountMatch.group(1) == '-' || sms.toLowerCase().contains('tu tk');
      final amountStr = amountMatch.group(2)!.replaceAll(RegExp(r'[,\.]'), '');
      final amount = double.parse(amountStr);

      // Extract merchant
      final merchantRegex = RegExp(r'[Dd]en\s+(.+?)(?:\s+\d{2}/\d{2}/|$)', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(sms);
      final merchant = merchantMatch?.group(1)?.trim() ?? 'VPBank Transaction';

      // Extract date
      final dateRegex = RegExp(r'(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2})');
      final dateMatch = dateRegex.firstMatch(sms);
      DateTime date = DateTime.now();
      
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = int.parse(dateMatch.group(3)!);
        final hour = int.parse(dateMatch.group(4)!);
        final minute = int.parse(dateMatch.group(5)!);
        date = DateTime(year, month, day, hour, minute);
      }

      return ParsedTransaction(
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        description: merchant,
        date: date,
        bank: 'VPBank',
        rawSms: sms,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse ACB SMS
  /// Format: "ACB: Tai khoan ****1234 tru 500,000 VND Tai STARBUCKS Ngay 21/11/25 14:30"
  ParsedTransaction? _parseACB(String sms) {
    try {
      // Extract amount
      final amountRegex = RegExp(r'(tru|cong)\s+(\d{1,3}(?:[,\.]\d{3})*)\s*VND', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) return null;

      final isExpense = amountMatch.group(1)!.toLowerCase() == 'tru';
      final amountStr = amountMatch.group(2)!.replaceAll(RegExp(r'[,\.]'), '');
      final amount = double.parse(amountStr);

      // Extract merchant
      final merchantRegex = RegExp(r'[Tt]ai\s+(.+?)(?:\s+[Nn]gay|$)', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(sms);
      final merchant = merchantMatch?.group(1)?.trim() ?? 'ACB Transaction';

      // Extract date
      final dateRegex = RegExp(r'[Nn]gay\s+(\d{2})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2})');
      final dateMatch = dateRegex.firstMatch(sms);
      DateTime date = DateTime.now();
      
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = 2000 + int.parse(dateMatch.group(3)!);
        final hour = int.parse(dateMatch.group(4)!);
        final minute = int.parse(dateMatch.group(5)!);
        date = DateTime(year, month, day, hour, minute);
      }

      return ParsedTransaction(
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        description: merchant,
        date: date,
        bank: 'ACB',
        rawSms: sms,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse BIDV SMS
  /// Format: "BIDV: TK ****1234 -500,000 VND tai STARBUCKS. SD: 5,234,000 VND"
  ParsedTransaction? _parseBIDV(String sms) {
    try {
      // Extract amount
      final amountRegex = RegExp(r'([-+]?)(\d{1,3}(?:[,\.]\d{3})*)\s*VND', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) return null;

      final isExpense = amountMatch.group(1) == '-';
      final amountStr = amountMatch.group(2)!.replaceAll(RegExp(r'[,\.]'), '');
      final amount = double.parse(amountStr);

      // Extract merchant
      final merchantRegex = RegExp(r'[Tt]ai\s+(.+?)\.', caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(sms);
      final merchant = merchantMatch?.group(1)?.trim() ?? 'BIDV Transaction';

      return ParsedTransaction(
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        description: merchant,
        date: DateTime.now(),
        bank: 'BIDV',
        rawSms: sms,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Supported bank types
enum BankType {
  vietcombank,
  techcombank,
  vpbank,
  acb,
  bidv,
}
