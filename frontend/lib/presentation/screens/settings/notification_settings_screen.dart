import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  String? _error;
  
  // Notification preferences
  Map<String, bool> _preferences = {
    'BUDGET_EXCEEDED': true,
    'BUDGET_WARNING': true,
    'BUDGET_ON_TRACK': true,
    'LARGE_TRANSACTION': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get('/api/settings/notifications');

      if (response.data['success'] == true) {
        setState(() {
          _preferences = Map<String, bool>.from(response.data['data']);
          _isLoading = false;
        });
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load preferences');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreference(String type, bool value) async {
    // Optimistic update
    setState(() {
      _preferences[type] = value;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.put(
        '/api/settings/notifications',
        data: {'preferences': _preferences},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _preferences[type] = !value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      children: [
        // Info Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Control which notifications you want to receive. Changes take effect immediately.',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Budget Alerts Section
        _buildSectionHeader('Budget Alerts'),
        _buildNotificationTile(
          type: 'BUDGET_EXCEEDED',
          title: 'Budget Exceeded',
          subtitle: 'When you spend 100% or more of your budget',
          icon: Icons.warning_amber,
          iconColor: Colors.red,
        ),
        _buildNotificationTile(
          type: 'BUDGET_WARNING',
          title: 'Budget Warning',
          subtitle: 'When you reach your budget alert threshold (default 80%)',
          icon: Icons.notifications_active,
          iconColor: Colors.orange,
        ),
        _buildNotificationTile(
          type: 'BUDGET_ON_TRACK',
          title: 'Budget On Track',
          subtitle: 'Motivational message when spending is under 50%',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        ),

        const Divider(height: 32),

        // Transaction Alerts Section
        _buildSectionHeader('Transaction Alerts'),
        _buildNotificationTile(
          type: 'LARGE_TRANSACTION',
          title: 'Large Transactions',
          subtitle: 'Notify when a transaction is \$1,000 or more',
          icon: Icons.attach_money,
          iconColor: AppColors.primary,
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

  Widget _buildNotificationTile({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isEnabled = _preferences[type] ?? true;

    return SwitchListTile(
      value: isEnabled,
      onChanged: (value) => _updatePreference(type, value),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      activeColor: AppColors.primary,
    );
  }
}
