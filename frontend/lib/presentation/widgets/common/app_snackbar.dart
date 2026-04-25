import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Custom snackbar helper for consistent feedback across the app
class AppSnackbar {
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.danger,
    );
  }

  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: AppColors.warning,
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.primary,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
