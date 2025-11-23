import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';

class MonthlyData {
  final DateTime month;
  double income;
  double expense;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class MonthlyBarChart extends StatefulWidget {
  final int monthsToShow;

  const MonthlyBarChart({
    super.key,
    this.monthsToShow = 6,
  });

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MonthlyData> _monthlyData = [];
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Fetch all transactions from last N months
      final startDate = DateTime.now().subtract(Duration(days: widget.monthsToShow * 31));
      await provider.fetchTransactions(
        startDate: startDate,
        endDate: DateTime.now(),
        refresh: true,
      );

      // Group transactions by month
      _monthlyData = _groupTransactionsByMonth(provider.transactions);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MonthlyData> _groupTransactionsByMonth(List<TransactionModel> transactions) {
    final Map<String, MonthlyData> monthMap = {};

    // Initialize last N months with zero values
    for (int i = widget.monthsToShow - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 31));
      final key = DateFormat('yyyy-MM').format(date);
      monthMap[key] = MonthlyData(
        month: date,
        income: 0,
        expense: 0,
      );
    }

    // Aggregate transactions
    for (var transaction in transactions) {
      final key = DateFormat('yyyy-MM').format(transaction.date);
      if (monthMap.containsKey(key)) {
        if (transaction.type == 'income') {
          monthMap[key]!.income += transaction.amount;
        } else {
          monthMap[key]!.expense += transaction.amount;
        }
      }
    }

    // Convert to sorted list
    final list = monthMap.values.toList();
    list.sort((a, b) => a.month.compareTo(b.month));
    return list;
  }

  double _getMaxY() {
    if (_monthlyData.isEmpty) return 1000;
    
    double max = 0;
    for (var data in _monthlyData) {
      if (data.income > max) max = data.income;
      if (data.expense > max) max = data.expense;
    }
    
    return max * 1.2; // Add 20% padding
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_monthlyData.isEmpty || _monthlyData.every((d) => d.income == 0 && d.expense == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transaction data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add transactions to see monthly comparison',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxY = _getMaxY();

    return Column(
      children: [
        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = _monthlyData[groupIndex];
                      final monthName = DateFormat('MMM yyyy').format(data.month);
                      final isIncome = rodIndex == 0;
                      final value = isIncome ? data.income : data.expense;
                      final label = isIncome ? 'Income' : 'Expense';
                      
                      return BarTooltipItem(
                        '$monthName\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '$label: ${value.toStringAsFixed(0)} VND',
                            style: TextStyle(
                              color: isIncome ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _monthlyData.length) {
                          final data = _monthlyData[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM\nyyyy').format(data.month),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY) return const Text('');
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                barGroups: _monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final isTouched = index == _touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      // Income bar
                      BarChartRodData(
                        toY: data.income,
                        color: Colors.green,
                        width: isTouched ? 18 : 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      // Expense bar
                      BarChartRodData(
                        toY: data.expense,
                        color: Colors.red,
                        width: isTouched ? 18 : 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Income'),
            const SizedBox(width: 24),
            _buildLegendItem(Colors.red, 'Expense'),
          ],
        ),

        const SizedBox(height: 16),

        // Summary
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var data in _monthlyData) {
      totalIncome += data.income;
      totalExpense += data.expense;
    }
    
    final netSavings = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: netSavings >= 0 
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.red[50]!, Colors.red[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: netSavings >= 0 ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Income',
                totalIncome,
                Colors.green,
                Icons.arrow_upward,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildSummaryItem(
                'Total Expense',
                totalExpense,
                Colors.red,
                Icons.arrow_downward,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                netSavings >= 0 ? Icons.trending_up : Icons.trending_down,
                color: netSavings >= 0 ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Net ${netSavings >= 0 ? "Savings" : "Loss"}: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${netSavings.abs().toStringAsFixed(0)} VND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: netSavings >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} VND',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
