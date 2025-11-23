import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().fetchBudgets(refresh: true);
    });
  }

  Future<void> _refreshBudgets() async {
    await context.read<BudgetProvider>().fetchBudgets(refresh: true);
  }

  Future<void> _showClearAllConfirmDialog() async {
    final budgetProvider = context.read<BudgetProvider>();
    final budgetCount = budgetProvider.budgets.length;

    if (budgetCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No budgets to clear')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Clear All Budgets?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all $budgetCount budget${budgetCount > 1 ? 's' : ''}?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 16),
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

    if (confirmed == true && mounted) {
      await _clearAllBudgets();
    }
  }

  Future<void> _clearAllBudgets() async {
    final budgetProvider = context.read<BudgetProvider>();
    final budgets = List.from(budgetProvider.budgets);
    
    if (budgets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No budgets to delete')),
        );
      }
      return;
    }
    
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Deleting ${budgets.length} budget${budgets.length > 1 ? 's' : ''}...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    int successCount = 0;
    int failCount = 0;

    for (var budget in budgets) {
      try {
        final success = await budgetProvider.deleteBudget(budget.id);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
      
      // Small delay to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $successCount budget${successCount > 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $successCount, Failed $failCount'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _refreshBudgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BudgetProvider>().refreshAllBudgets();
            },
            tooltip: 'Refresh All',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllConfirmDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear All Budgets'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.budgets.isEmpty) {
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
                    onPressed: _refreshBudgets,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first budget to track spending',
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
            onRefresh: _refreshBudgets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.budgets.length,
              itemBuilder: (context, index) {
                final budget = provider.budgets[index];
                final percentage = budget.getPercentageUsed();
                final status = budget.getStatus();

                Color statusColor;
                if (status == 'exceeded') {
                  statusColor = AppColors.danger;
                } else if (status == 'warning') {
                  statusColor = AppColors.warning;
                } else {
                  statusColor = AppColors.success;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/budgets/detail',
                        arguments: budget.id,
                      ).then((_) => _refreshBudgets());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  budget.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  budget.periodLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Categories
                          Text(
                            budget.categoryNames,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${Formatters.currency(budget.spent)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Limit: ${Formatters.currency(budget.amount)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (percentage / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: AppColors.gray200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${percentage.toStringAsFixed(1)}% used',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Remaining amount
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remaining',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                Formatters.currency(budget.getRemaining()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),

                          // Alert indicator
                          if (budget.shouldAlert()) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You\'ve reached ${budget.alertThreshold.toInt()}% of your budget',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
          Navigator.pushNamed(context, '/budgets/add').then((_) => _refreshBudgets());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }
}
