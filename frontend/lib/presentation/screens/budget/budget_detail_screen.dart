import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import 'dart:math' as math;

/// Budget Detail Screen - Shows detailed budget information with circular chart
class BudgetDetailScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailScreen({
    Key? key,
    required this.budgetId,
  }) : super(key: key);

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetDetails();
  }

  Future<void> _loadBudgetDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Fetch budget details
      await budgetProvider.fetchBudgetById(widget.budgetId);
      
      final budget = budgetProvider.selectedBudget;
      if (budget != null) {
        // Fetch transactions within budget period
        await transactionProvider.fetchTransactions(
          startDate: budget.startDate,
          endDate: budget.endDate,
          type: 'expense',
          refresh: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
              await budgetProvider.refreshBudget(widget.budgetId);
              await _loadBudgetDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget refreshed')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final budget = Provider.of<BudgetProvider>(context, listen: false).selectedBudget;
              if (budget != null) {
                Navigator.pushNamed(
                  context,
                  '/budgets/edit',
                  arguments: budget,
                ).then((_) => _loadBudgetDetails());
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<BudgetProvider>(
              builder: (context, budgetProvider, child) {
                final budget = budgetProvider.selectedBudget;
                
                if (budget == null) {
                  return const Center(
                    child: Text('Budget not found'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadBudgetDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Budget Header
                          _buildBudgetHeader(budget),
                          const SizedBox(height: 24),
                          
                          // Circular Progress Chart
                          _buildCircularProgress(budget),
                          const SizedBox(height: 24),
                          
                          // Statistics Card
                          _buildStatisticsCard(budget),
                          const SizedBox(height: 24),
                          
                          // Category Breakdown (if multiple categories)
                          if (budget.categories.length > 1) ...[
                            _buildCategoryBreakdown(budget),
                            const SizedBox(height: 24),
                          ],
                          
                          // Transactions List
                          _buildTransactionsList(budget),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBudgetHeader(BudgetModel budget) {
    final status = budget.getStatus();
    final statusColor = status == 'ok'
        ? Colors.green
        : status == 'warning'
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(budget.periodLabel),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              budget.categoryNames,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(budget.startDate)} - ${DateFormat('MMM dd, yyyy').format(budget.endDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(BudgetModel budget) {
    final percentage = budget.getPercentageUsed();
    final status = budget.getStatus();
    final progressColor = status == 'ok'
        ? Colors.green
        : status == 'warning'
            ? Colors.orange
            : Colors.red;

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 16,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0.0,
                        end: math.min(percentage / 100, 1.0),
                      ),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 16,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        );
                      },
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == 'ok'
                            ? 'On Track'
                            : status == 'warning'
                                ? 'Warning'
                                : 'Exceeded',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Spent / Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(budget.spent),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(budget.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(budget.getRemaining()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: budget.getRemaining() >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BudgetModel budget) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );

    final totalDays = budget.totalDays;
    final daysRemaining = budget.daysRemaining;
    final daysPassed = totalDays - daysRemaining;
    final avgDailySpending = daysPassed > 0 ? budget.spent / daysPassed : 0.0;
    final dailyBudget = totalDays > 0 ? budget.amount / totalDays : 0.0;
    final projectedTotal = avgDailySpending * totalDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Budget Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            _buildStatRow(
              'Total Period',
              '$totalDays days',
              Icons.calendar_month,
            ),
            _buildStatRow(
              'Days Passed',
              '$daysPassed days',
              Icons.event_available,
            ),
            _buildStatRow(
              'Days Remaining',
              '$daysRemaining days',
              Icons.event_note,
            ),
            const Divider(height: 24),
            
            _buildStatRow(
              'Daily Budget',
              currencyFormat.format(dailyBudget),
              Icons.today,
            ),
            _buildStatRow(
              'Avg Daily Spending',
              currencyFormat.format(avgDailySpending),
              Icons.trending_up,
              valueColor: avgDailySpending > dailyBudget ? Colors.red : Colors.green,
            ),
            if (daysRemaining > 0)
              _buildStatRow(
                'Projected Total',
                currencyFormat.format(projectedTotal),
                Icons.analytics,
                valueColor: projectedTotal > budget.amount ? Colors.orange : Colors.green,
              ),
            
            if (budget.alertEnabled) ...[
              const Divider(height: 24),
              _buildStatRow(
                'Alert Threshold',
                '${budget.alertThreshold}%',
                Icons.notification_important,
                valueColor: budget.shouldAlert() ? Colors.red : Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(BudgetModel budget) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final transactions = transactionProvider.transactions
            .where((t) => budget.categories.contains(t.categoryId))
            .toList();

        // Calculate spending per category
        final Map<String, double> categorySpending = {};
        for (var transaction in transactions) {
          categorySpending[transaction.categoryId] =
              (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
        }

        final categoryProvider = Provider.of<CategoryProvider>(context);
        final categories = categoryProvider.categories
            .where((c) => budget.categories.contains(c.id))
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                ...categories.map((category) {
                  final spent = categorySpending[category.id] ?? 0;
                  final percentage = budget.spent > 0 ? (spent / budget.spent * 100) : 0.0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse((category.color ?? '#3F51B5').replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              '${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0).format(spent)} (${percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(int.parse((category.color ?? '#3F51B5').replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(BudgetModel budget) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Get budget category IDs
        final budgetCategoryIds = budget.categories.map((c) => c.id).toList();
        
        // Filter transactions for this budget
        var transactions = transactionProvider.transactions.where((t) {
          // Check if transaction is within budget period
          if (t.date.isBefore(budget.startDate) || t.date.isAfter(budget.endDate)) {
            return false;
          }
          
          // Check if transaction category matches budget categories
          if (budgetCategoryIds.isNotEmpty && !budgetCategoryIds.contains(t.categoryId)) {
            return false;
          }
          
          // Only expense transactions
          return t.type == 'expense';
        }).toList();

        // Sort by date descending
        transactions.sort((a, b) => b.date.compareTo(a.date));

        final currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'VND',
          decimalDigits: 0,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${transactions.length} items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                if (transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final categoryProvider = Provider.of<CategoryProvider>(context);
                      final category = categoryProvider.categories
                          .firstWhere(
                            (c) => c.id == transaction.categoryId,
                            orElse: () => categoryProvider.categories.first,
                          );

                      // Map icon name to IconData
                      IconData getIconData(String? iconName) {
                        const iconMap = {
                          'restaurant': Icons.restaurant,
                          'shopping_bag': Icons.shopping_bag,
                          'local_gas_station': Icons.local_gas_station,
                          'medical_services': Icons.medical_services,
                          'school': Icons.school,
                          'home': Icons.home,
                          'directions_car': Icons.directions_car,
                          'sports_esports': Icons.sports_esports,
                          'credit_card': Icons.credit_card,
                          'attach_money': Icons.attach_money,
                          'card_giftcard': Icons.card_giftcard,
                          'savings': Icons.savings,
                        };
                        return iconMap[iconName] ?? Icons.category;
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(int.parse((category.color ?? '#3F51B5').replaceFirst('#', '0xFF'))).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            getIconData(category.icon),
                            color: Color(int.parse((category.color ?? '#3F51B5').replaceFirst('#', '0xFF'))),
                          ),
                        ),
                        title: Text(
                          transaction.description ?? category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(transaction.date),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          currencyFormat.format(transaction.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
