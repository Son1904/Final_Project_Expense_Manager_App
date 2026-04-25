import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Custom Bottom Sheet helper for consistent modal bottom sheets
class AppBottomSheet {
  /// Show a confirmation bottom sheet with title, message, and action buttons
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConfirmationSheet(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor ?? AppColors.primary,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  /// Show a danger confirmation (for delete, clear, etc.)
  static Future<bool?> showDangerConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) {
    return showConfirmation(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: AppColors.danger,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
    );
  }

  /// Show a selection bottom sheet with list of options
  static Future<T?> showSelection<T>(
    BuildContext context, {
    required String title,
    required List<SelectionOption<T>> options,
    T? selectedValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
      ),
    );
  }

  /// Show a custom content bottom sheet
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CustomSheet<T>(
        title: title,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }
}

/// Option model for selection sheet
class SelectionOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const SelectionOption({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

/// Base container for bottom sheets
class _SheetContainer extends StatelessWidget {
  final Widget child;
  final double? maxHeight;

  const _SheetContainer({
    required this.child,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Confirmation sheet widget
class _ConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData? icon;
  final Color? iconColor;

  const _ConfirmationSheet({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.confirmColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Selection sheet widget
class _SelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectionOption<T>> options;
  final T? selectedValue;

  const _SelectionSheet({
    required this.title,
    required this.options,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.value == selectedValue;
                
                return ListTile(
                  leading: option.icon != null
                      ? Icon(
                          option.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (option.iconColor ?? Colors.grey[600]),
                        )
                      : null,
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, option.value),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Custom content sheet widget
class _CustomSheet<T> extends StatelessWidget {
  final String title;
  final Widget child;
  final double? maxHeight;

  const _CustomSheet({
    required this.title,
    required this.child,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      maxHeight: maxHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(child: child),
        ],
      ),
    );
  }
}
