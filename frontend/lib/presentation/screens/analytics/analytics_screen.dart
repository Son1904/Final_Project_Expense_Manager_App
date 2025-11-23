import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/charts/spending_pie_chart.dart';
import '../../widgets/charts/monthly_bar_chart.dart';
import '../../widgets/charts/spending_trend_line_chart.dart';
import '../../providers/transaction_provider.dart';

enum TimeRange { week, month, quarter, year }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TimeRange _selectedRange = TimeRange.month;

  int _getDaysForRange(TimeRange range) {
    switch (range) {
      case TimeRange.week:
        return 7;
      case TimeRange.month:
        return 30;
      case TimeRange.quarter:
        return 90;
      case TimeRange.year:
        return 365;
    }
  }

  int _getMonthsForRange(TimeRange range) {
    switch (range) {
      case TimeRange.week:
        return 1;
      case TimeRange.month:
        return 6;
      case TimeRange.quarter:
        return 3;
      case TimeRange.year:
        return 12;
    }
  }

  String _getRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.week:
        return 'Week';
      case TimeRange.month:
        return 'Month';
      case TimeRange.quarter:
        return 'Quarter';
      case TimeRange.year:
        return 'Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              '📊 Spending Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track where your money goes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Time Range Filter
            _buildTimeRangeFilter(),

            const SizedBox(height: 16),

            // Insights Card
            _buildInsightsCard(),

            const SizedBox(height: 24),

            // Pie Chart Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pie_chart, color: Colors.blue),
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
                    const SizedBox(height: 16),
                    const SizedBox(
                      height: 450,
                      child: SpendingPieChart(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bar Chart Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Monthly Comparison',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: MonthlyBarChart(monthsToShow: _getMonthsForRange(_selectedRange)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Line Chart Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Spending Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SpendingTrendLineChart(daysToShow: _getDaysForRange(_selectedRange)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              'Time Range:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TimeRange.values.map((range) {
                    final isSelected = _selectedRange == range;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_getRangeLabel(range)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRange = range;
                            });
                          }
                        },
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final income = provider.totalIncome;
        final expense = provider.totalExpense;
        final balance = provider.balance;
        final spending = provider.spendingByCategory;

        if (income == 0 && expense == 0) {
          return const SizedBox.shrink();
        }

        final hasIncome = income > 0;
        final savingsRate = hasIncome ? ((income - expense) / income * 100) : 0;
        final topCategory = spending.isNotEmpty ? spending.first.categoryName : 'N/A';
        final topCategoryAmount = spending.isNotEmpty ? spending.first.total : 0;
        final avgDailySpending = expense / _getDaysForRange(_selectedRange);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInsightChip(
                      icon: Icons.savings,
                      label: 'Savings Rate',
                      value: '${savingsRate.toStringAsFixed(1)}%',
                      color: savingsRate >= 20 ? Colors.green : (savingsRate >= 0 ? Colors.orange : Colors.red),
                    ),
                    _buildInsightChip(
                      icon: Icons.trending_up,
                      label: 'Top Category',
                      value: topCategory,
                      subtitle: '${topCategoryAmount.toStringAsFixed(0)} VND',
                      color: Colors.purple,
                    ),
                    _buildInsightChip(
                      icon: Icons.calendar_today,
                      label: 'Avg Daily',
                      value: '${avgDailySpending.toStringAsFixed(0)} VND',
                      color: Colors.blue,
                    ),
                    _buildInsightChip(
                      icon: Icons.account_balance_wallet,
                      label: 'Balance',
                      value: '${balance.toStringAsFixed(0)} VND',
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightChip({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
