import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';

/// Helper class for CSV operations
class CsvHelper {
  /// Download CSV file (works on web and mobile)
  static Future<String?> downloadCsv(String csvContent, String filename) async {
    if (kIsWeb) {
      // Web implementation
      _downloadCsvWeb(csvContent, filename);
      return null;
    } else {
      // Mobile implementation (Android/iOS)
      return await _downloadCsvMobile(csvContent, filename);
    }
  }

  /// Web-specific download implementation
  static void _downloadCsvWeb(String csvContent, String filename) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    html.document.body?.append(anchor);
    anchor.click();
    
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Mobile-specific download implementation
  static Future<String> _downloadCsvMobile(String csvContent, String filename) async {
    // For Android 10+ (API 29+), no permission needed for app-specific directory
    // For older Android versions, request permission
    if (Platform.isAndroid) {
      // Get Downloads directory
      Directory? directory;
      
      // Try public Downloads folder first (works on Android 10+ without permission)
      directory = Directory('/storage/emulated/0/Download');
      
      if (!await directory.exists()) {
        // Fallback to app-specific external storage (always accessible)
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file and write content
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      return filePath;
    } else if (Platform.isIOS) {
      // iOS: use Documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(csvContent);
      return filePath;
    }

    throw Exception('Unsupported platform');
  }
}
