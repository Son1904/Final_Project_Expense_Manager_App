import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import 'package:intl/intl.dart';

class RecurringListScreen extends StatefulWidget {
  const RecurringListScreen({super.key});

  @override
  State<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends State<RecurringListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringProvider>().fetchAll(refresh: true);
    });
  }

  Future<void> _refreshData() async {
    // Delay slightly to give the backend's real-time scheduler time to finish backfilling
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    
    await Future.wait([
      context.read<RecurringProvider>().fetchAll(refresh: true),
      context.read<TransactionProvider>().refreshAll(),
    ]);
  }

  void _showDeleteConfirmation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction?'),
        content: const Text(
          'Are you sure you want to delete this recurring transaction? Future transactions will not be created, but past transactions will be kept.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<RecurringProvider>().delete(id);
      if (mounted && success) {
        AppSnackbar.showSuccess(context, 'Deleted successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recurring transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automate your salary, rent, and subscriptions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/recurring/edit',
                        arguments: item,
                      ).then((_) => _refreshData());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon placeholder based on type
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: item.isIncome 
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.danger.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: item.isIncome ? AppColors.success : AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.categoryName ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.description != null && item.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      item.frequencyLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(item.amount),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: item.isIncome ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Switch(
                                    value: item.isActive,
                                    onChanged: (value) async {
                                       await context.read<RecurringProvider>().toggle(item.id);
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next: ${DateFormat('MMM dd, yyyy').format(item.nextExecutionDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showDeleteConfirmation(item.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/recurring/add').then((_) => _refreshData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New'),
      ),
    );
  }
}
