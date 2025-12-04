import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/spending_by_category.dart';

class SpendingPieChart extends StatefulWidget {
  const SpendingPieChart({super.key});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;
  List<SpendingByCategory> _spendingData = [];

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.fetchSpendingByCategory();
      
      setState(() {
        _spendingData = provider.spendingByCategory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String hexColor) {
    try {
      // Remove # if present and add opacity
      String color = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$color', radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback color
    }
  }

  double _calculateTotal() {
    return _spendingData.fold(0, (sum, item) => sum + item.total);
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
              onPressed: _loadSpendingData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_spendingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your spending breakdown',
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

    final total = _calculateTotal();

    return Column(
      children: [
        // Chart 
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _spendingData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final isTouched = index == _touchedIndex;
                final fontSize = isTouched ? 14.0 : 12.0;
                final radius = isTouched ? 80.0 : 70.0;
                final percentage = (data.total / total) * 100;

                return PieChartSectionData(
                  color: _parseColor(data.categoryColor),
                  value: data.total,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Legend - Scrollable 
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _spendingData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final percentage = (data.total / total) * 100;
                final isTouched = index == _touchedIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isTouched ? Colors.grey[200] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isTouched ? Colors.grey[400]! : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseColor(data.categoryColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.categoryName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${data.total.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: isTouched ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Total
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Spending: \$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
