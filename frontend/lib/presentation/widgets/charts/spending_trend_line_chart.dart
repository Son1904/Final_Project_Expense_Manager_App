import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';

class DailyData {
  final DateTime date;
  final double amount;
  final int transactionCount;

  DailyData({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

class SpendingTrendLineChart extends StatefulWidget {
  final int daysToShow;

  const SpendingTrendLineChart({
    Key? key,
    this.daysToShow = 30,
  }) : super(key: key);

  @override
  State<SpendingTrendLineChart> createState() => _SpendingTrendLineChartState();
}

class _SpendingTrendLineChartState extends State<SpendingTrendLineChart> {
  bool _isLoading = false;
  List<DailyData> _dailyData = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      final startDate = DateTime.now().subtract(Duration(days: widget.daysToShow - 1));
      await provider.fetchTransactions(
        startDate: startDate,
        endDate: DateTime.now(),
        refresh: true,
      );

      _dailyData = _groupTransactionsByDay(provider.transactions);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<DailyData> _groupTransactionsByDay(List<TransactionModel> transactions) {
    final Map<String, DailyData> grouped = {};
    final startDate = DateTime.now().subtract(Duration(days: widget.daysToShow - 1));
    
    // Initialize all days with zero
    for (int i = 0; i < widget.daysToShow; i++) {
      final date = startDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped[key] = DailyData(
        date: date,
        amount: 0,
        transactionCount: 0,
      );
    }

    // Aggregate expenses
    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final key = DateFormat('yyyy-MM-dd').format(transaction.date);
        if (grouped.containsKey(key)) {
          grouped[key] = DailyData(
            date: grouped[key]!.date,
            amount: grouped[key]!.amount + transaction.amount,
            transactionCount: grouped[key]!.transactionCount + 1,
          );
        }
      }
    }

    final result = grouped.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrendData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dailyData.isEmpty || _dailyData.every((d) => d.amount == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expense data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see spending trends',
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

    final totalSpending = _dailyData.fold<double>(0, (sum, data) => sum + data.amount);
    final averageDaily = totalSpending / widget.daysToShow;
    final maxSpending = _dailyData.fold<double>(0, (max, data) => data.amount > max ? data.amount : max);
    final activeDays = _dailyData.where((d) => d.amount > 0).length;
    final highestDay = _dailyData.reduce((a, b) => a.amount > b.amount ? a : b);

    return Column(
      children: [
        // Line Chart
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSpending > 0 ? maxSpending / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: widget.daysToShow / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _dailyData.length) {
                          final date = _dailyData[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (_dailyData.length - 1).toDouble(),
                minY: 0,
                maxY: maxSpending * 1.2,
                lineBarsData: [
                  // Daily spending line
                  LineChartBarData(
                    spots: _dailyData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
                        .toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Average line
                  LineChartBarData(
                    spots: List.generate(
                      _dailyData.length,
                      (index) => FlSpot(index.toDouble(), averageDaily),
                    ),
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        if (barSpot.barIndex == 0) {
                          final data = _dailyData[barSpot.x.toInt()];
                          return LineTooltipItem(
                            '${DateFormat('MMM dd').format(data.date)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '\$${data.amount.toStringAsFixed(2)}\n',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: '${data.transactionCount} transaction(s)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Statistics Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      '\$${totalSpending.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Average/Day',
                      '\$${averageDaily.toStringAsFixed(2)}',
                      Icons.analytics,
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Highest Day',
                      '\$${highestDay.amount.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.red,
                    ),
                    _buildStatItem(
                      'Active Days',
                      '$activeDays/${widget.daysToShow}',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Daily Spending', Colors.orange, false),
              const SizedBox(width: 24),
              _buildLegendItem('Average', Colors.blue, true),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            border: isDashed ? Border.all(color: color, width: 2) : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
