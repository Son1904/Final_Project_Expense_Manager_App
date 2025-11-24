import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(context),
            tooltip: 'Mark all as read',
          ),
          // Clear all button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearAll(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${notificationProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notificationProvider.loadNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see budget alerts and updates here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final groupedNotifications =
              notificationProvider.groupedNotifications;

          return RefreshIndicator(
            onRefresh: () => notificationProvider.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // TODAY
                if (groupedNotifications['TODAY']!.isNotEmpty) ...[
                  _buildGroupHeader('TODAY'),
                  ...groupedNotifications['TODAY']!
                      .map((n) => _buildNotificationCard(context, n)),
                  const SizedBox(height: 16),
                ],
                // YESTERDAY
                if (groupedNotifications['YESTERDAY']!.isNotEmpty) ...[
                  _buildGroupHeader('YESTERDAY'),
                  ...groupedNotifications['YESTERDAY']!
                      .map((n) => _buildNotificationCard(context, n)),
                  const SizedBox(height: 16),
                ],
                // EARLIER
                if (groupedNotifications['EARLIER']!.isNotEmpty) ...[
                  _buildGroupHeader('EARLIER'),
                  ...groupedNotifications['EARLIER']!
                      .map((n) => _buildNotificationCard(context, n)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await notificationProvider.deleteNotification(notification.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete notification'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead ? Colors.grey[200]! : Colors.blue[100]!,
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!notification.isRead) {
              notificationProvider.markAsRead(notification.id);
            }
            _handleNotificationTap(context, notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Emoji
                Text(
                  notification.getIcon(),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: notification.isRead
                                    ? Colors.grey[700]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.getTimeAgo(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Navigate based on referenceType
    switch (notification.referenceType) {
      case 'BUDGET':
        if (notification.referenceId != null) {
          // Load budget and navigate to detail screen
          final budgetProvider =
              Provider.of<BudgetProvider>(context, listen: false);
          budgetProvider.fetchBudgets().then((_) {
            final budget = budgetProvider.budgets.firstWhere(
              (b) => b.id == notification.referenceId,
              orElse: () => budgetProvider.budgets.first,
            );
            Navigator.pushNamed(
              context,
              '/budgets/detail',
              arguments: budget,
            );
          });
        }
        break;
      case 'TRANSACTION':
        if (notification.referenceId != null) {
          // Load transaction and navigate to edit screen
          final transactionProvider =
              Provider.of<TransactionProvider>(context, listen: false);
          transactionProvider.fetchTransactions().then((_) {
            final transaction = transactionProvider.transactions.firstWhere(
              (t) => t.id == notification.referenceId,
              orElse: () => transactionProvider.transactions.first,
            );
            Navigator.pushNamed(
              context,
              '/transactions/edit',
              arguments: transaction,
            );
          });
        }
        break;
      case 'CATEGORY':
        // Navigate to categories screen
        Navigator.pushNamed(context, '/categories');
        break;
      default:
        // No specific action
        break;
    }
  }

  void _markAllAsRead(BuildContext context) async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    try {
      await notificationProvider.markAllAsRead();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark all as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will permanently delete all notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      try {
        await notificationProvider.clearAll();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to clear notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
