import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_bottom_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/csv_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSectionHeader('Profile'),
          _buildProfileTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: user?.email ?? 'Not available',
            trailing: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
          ),
          _buildProfileTile(
            icon: Icons.person,
            title: 'Full Name',
            subtitle: user?.fullName ?? 'Not set',
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _showEditNameDialog(context),
          ),
          _buildProfileTile(
            icon: Icons.calendar_today,
            title: 'Member Since',
            subtitle: _formatDate(user?.createdAt),
            trailing: const SizedBox.shrink(),
          ),

          const Divider(height: 32),

          // Security Section
          _buildSectionHeader('Security'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () => Navigator.pushNamed(context, '/settings/change-password'),
          ),

          const Divider(height: 32),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildListTile(
            icon: Icons.notifications,
            title: 'Notification Settings',
            onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
          ),

          const Divider(height: 32),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildListTile(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Download your transactions as CSV',
            onTap: () => _exportData(context),
          ),
          _buildListTile(
            icon: Icons.delete_sweep,
            title: 'Clear All Data',
            subtitle: 'Delete all transactions and budgets',
            iconColor: Colors.orange,
            onTap: () => _showClearDataDialog(context),
          ),
          _buildListTile(
            icon: Icons.person_remove,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            iconColor: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader('About'),
          _buildProfileTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0',
            trailing: const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditNameDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentName = authProvider.user?.fullName ?? '';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Full Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                AppSnackbar.showWarning(context, 'Name cannot be empty');
                return;
              }

              Navigator.pop(context);
              
              try {
                final apiService = context.read<ApiService>();
                final response = await apiService.put(
                  '/api/auth/profile',
                  data: {'fullName': newName},
                );

                if (response.data['success'] == true) {
                  // Update local user data
                  await authProvider.getProfile();
                  
                  if (context.mounted) {
                    AppSnackbar.showSuccess(context, 'Name updated successfully');
                  }
                } else {
                  throw Exception(response.data['message'] ?? 'Failed to update');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.showError(
                    context,
                    e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    // Show date range picker
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange == null) return;

    if (!context.mounted) return;

    // Show loading
    AppSnackbar.showInfo(context, 'Exporting transactions...');

    try {
      final apiService = context.read<ApiService>();
      
      // Build query params
      final startDate = dateRange.start.toIso8601String();
      final endDate = dateRange.end.toIso8601String();
      
      final response = await apiService.get(
        '/api/transactions/export?startDate=$startDate&endDate=$endDate'
      );

      // Hide loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Download CSV file
      if (response.data is String) {
        final csv = response.data as String;
        final transactionCount = csv.split('\n').length - 1;
        
        // Generate filename with date range
        final filename = 'transactions_${dateRange.start.toIso8601String().split('T')[0]}_to_${dateRange.end.toIso8601String().split('T')[0]}.csv';
        
        // Download file
        final filePath = await CsvHelper.downloadCsv(csv, filename);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          AppSnackbar.showSuccess(
            context,
            filePath != null 
              ? 'Saved $transactionCount transactions to:\n$filePath'
              : 'Downloaded $transactionCount transactions',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        AppSnackbar.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context) async {
    final confirmed = await AppBottomSheet.showDangerConfirmation(
      context,
      title: 'Clear All Data?',
      message: 'This will delete all your transactions and budgets. This action cannot be undone.\n\nYour account will remain active.',
      confirmText: 'Clear Data',
    );

    if (confirmed == true && context.mounted) {
      try {
        final apiService = context.read<ApiService>();
        final response = await apiService.delete('/api/auth/clear-data');

        if (response.data['success'] == true) {
          // Refresh all providers to update UI immediately
          if (context.mounted) {
            final transactionProvider = context.read<TransactionProvider>();
            final budgetProvider = context.read<BudgetProvider>();
            final notificationProvider = context.read<NotificationProvider>();
            
            // Refresh data
            await Future.wait([
              transactionProvider.fetchTransactions(),
              transactionProvider.fetchSummary(),
              budgetProvider.fetchBudgets(),
              notificationProvider.loadNotifications(),
              notificationProvider.loadUnreadCount(),
            ]);
            
            AppSnackbar.showSuccess(context, 'All data cleared successfully');
          }
        } else {
          throw Exception(response.data['message'] ?? 'Failed to clear data');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await AppBottomSheet.showDangerConfirmation(
      context,
      title: 'Delete Account?',
      message: 'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you absolutely sure?',
      confirmText: 'Delete Account',
    );

    if (confirmed == true && context.mounted) {
      try {
        final apiService = context.read<ApiService>();
        final response = await apiService.delete('/api/auth/account');

        if (response.data['success'] == true) {
          if (context.mounted) {
            // Logout and clear auth state
            await context.read<AuthProvider>().logout();
          }
        } else {
          throw Exception(response.data['message'] ?? 'Failed to delete account');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
      icon: Icons.logout,
      iconColor: Colors.red,
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
