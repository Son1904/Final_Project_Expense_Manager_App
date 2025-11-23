import 'package:permission_handler/permission_handler.dart';

/// Service for handling SMS permission requests and checks
/// 
/// This service manages all SMS-related permissions required for
/// reading banking SMS notifications on Android devices.
class SmsPermissionService {
  /// Check if SMS permission is currently granted
  Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request SMS permission from user
  /// 
  /// Returns true if permission granted, false otherwise
  Future<bool> requestSmsPermission() async {
    // Check if already granted
    if (await hasSmsPermission()) {
      return true;
    }

    // Request permission
    final status = await Permission.sms.request();
    
    return status.isGranted;
  }

  /// Check if permission was permanently denied
  /// 
  /// Returns true if user selected "Don't ask again" and denied permission
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.sms.status;
    return status.isPermanentlyDenied;
  }

  /// Check if we should show rationale to user
  /// 
  /// Returns true if we should explain why we need permission
  Future<bool> shouldShowRationale() async {
    final status = await Permission.sms.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }

  /// Open app settings so user can manually grant permission
  /// 
  /// Use this when permission is permanently denied
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get detailed permission status
  Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.sms.status;
  }

  /// Request SMS permission with detailed explanation
  /// 
  /// Returns result with status and message
  Future<PermissionResult> requestWithExplanation() async {
    // Already granted
    if (await hasSmsPermission()) {
      return PermissionResult(
        granted: true,
        message: 'SMS permission already granted',
      );
    }

    // Permanently denied - need manual settings
    if (await isPermanentlyDenied()) {
      return PermissionResult(
        granted: false,
        message: 'Permission permanently denied. Please enable in Settings.',
        needsManualAction: true,
      );
    }

    // Request permission
    final status = await Permission.sms.request();

    if (status.isGranted) {
      return PermissionResult(
        granted: true,
        message: 'SMS permission granted successfully',
      );
    } else if (status.isPermanentlyDenied) {
      return PermissionResult(
        granted: false,
        message: 'Permission denied. Please enable in Settings.',
        needsManualAction: true,
      );
    } else {
      return PermissionResult(
        granted: false,
        message: 'SMS permission denied',
      );
    }
  }
}

/// Result of permission request with detailed information
class PermissionResult {
  final bool granted;
  final String message;
  final bool needsManualAction;

  PermissionResult({
    required this.granted,
    required this.message,
    this.needsManualAction = false,
  });
}
