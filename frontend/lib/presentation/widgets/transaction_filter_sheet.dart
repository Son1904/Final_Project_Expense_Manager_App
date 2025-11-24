import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';

class TransactionFilterSheet extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;
  final List<CategoryModel> categories;

  const TransactionFilterSheet({
    super.key,
    this.currentFilters,
    required this.categories,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedDateRange;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    
    // Load current filters
    if (widget.currentFilters != null) {
      _selectedType = widget.currentFilters!['type'];
      _selectedCategory = widget.currentFilters!['category'];
      _selectedDateRange = widget.currentFilters!['dateRange'];
      _customStartDate = widget.currentFilters!['startDate'];
      _customEndDate = widget.currentFilters!['endDate'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Filter
                  _buildSectionLabel('Type'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChoiceChip('All', _selectedType == null, () {
                        setState(() => _selectedType = null);
                      }),
                      _buildChoiceChip('Income', _selectedType == 'income', () {
                        setState(() => _selectedType = 'income');
                      }),
                      _buildChoiceChip('Expense', _selectedType == 'expense', () {
                        setState(() => _selectedType = 'expense');
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Category Filter
                  _buildSectionLabel('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...widget.categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Text(cat.icon ?? '📁', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Date Range Filter
                  _buildSectionLabel('Date Range'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip('All Time', _selectedDateRange == null, () {
                        setState(() {
                          _selectedDateRange = null;
                          _customStartDate = null;
                          _customEndDate = null;
                        });
                      }),
                      _buildChoiceChip('Today', _selectedDateRange == 'today', () {
                        setState(() => _selectedDateRange = 'today');
                      }),
                      _buildChoiceChip('This Week', _selectedDateRange == 'week', () {
                        setState(() => _selectedDateRange = 'week');
                      }),
                      _buildChoiceChip('This Month', _selectedDateRange == 'month', () {
                        setState(() => _selectedDateRange = 'month');
                      }),
                      _buildChoiceChip('Last Month', _selectedDateRange == 'lastMonth', () {
                        setState(() => _selectedDateRange = 'lastMonth');
                      }),
                      _buildChoiceChip('This Year', _selectedDateRange == 'year', () {
                        setState(() => _selectedDateRange = 'year');
                      }),
                      _buildChoiceChip('Custom', _selectedDateRange == 'custom', () {
                        _selectCustomDateRange();
                      }),
                    ],
                  ),

                  if (_selectedDateRange == 'custom' && _customStartDate != null && _customEndDate != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}',
                            style: const TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: now, end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _selectedDateRange = null;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedType != null) {
      filters['type'] = _selectedType;
    }

    if (_selectedCategory != null) {
      filters['category'] = _selectedCategory;
    }

    if (_selectedDateRange != null) {
      filters['dateRange'] = _selectedDateRange;

      // Calculate actual dates based on range
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (_selectedDateRange) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'lastMonth':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          startDate = lastMonth;
          endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'custom':
          if (_customStartDate != null && _customEndDate != null) {
            // Convert to start of day (00:00:00) and end of day (23:59:59.999) in local time
            startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day, 0, 0, 0, 0);
            endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59, 999);
          }
          break;
      }

      if (startDate != null) filters['startDate'] = startDate;
      if (endDate != null) filters['endDate'] = endDate;
    }

    Navigator.pop(context, filters);
  }
}
