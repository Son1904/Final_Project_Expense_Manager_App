import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import 'add_edit_transaction_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/csv_helper.dart';
import 'dart:async';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedType;
  String? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    
    await Future.wait([
      transactionProvider.fetchTransactions(refresh: true),
      categoryProvider.fetchCategories(),
    ]);
  }

  Future<void> _applyFilters() async {
    final search = _searchController.text.trim();
    context.read<TransactionProvider>().applyFilters(
      search: search.isEmpty ? null : search,
      type: _selectedType,
      categoryId: _selectedCategoryId,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
    });
    context.read<TransactionProvider>().clearFilters();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Set to start of day (00:00:00) and end of day (23:59:59.999)
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0, 0);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
      });
      await _applyFilters();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  void _showClearAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear All Transactions?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllTransactions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllTransactions() async {
    final transactionProvider = context.read<TransactionProvider>();
    final transactions = List.from(transactionProvider.transactions);
    
    if (transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to delete')),
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
              Text('Deleting ${transactions.length} transaction${transactions.length > 1 ? 's' : ''}...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    int successCount = 0;
    int failCount = 0;

    for (var transaction in transactions) {
      try {
        final success = await transactionProvider.deleteTransaction(transaction.id);
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
            content: Text('Successfully deleted $successCount transaction${successCount > 1 ? 's' : ''}'),
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

      await _loadData();
    }
  }

  Future<void> _exportData() async {
    // Show date range picker
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange == null) return;

    if (!mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Exporting transactions...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final apiService = context.read<ApiService>();
      
      // Build query params with current filters
      final transactionProvider = context.read<TransactionProvider>();
      final params = <String, String>{
        'startDate': dateRange.start.toIso8601String(),
        'endDate': dateRange.end.toIso8601String(),
      };

      if (transactionProvider.filterType != null) {
        params['type'] = transactionProvider.filterType!;
      }
      if (transactionProvider.filterCategoryId != null) {
        params['category'] = transactionProvider.filterCategoryId!;
      }
      if (transactionProvider.searchQuery != null && transactionProvider.searchQuery!.isNotEmpty) {
        params['search'] = transactionProvider.searchQuery!;
      }
      
      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      
      final response = await apiService.get('/api/transactions/export?$queryString');

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Download CSV file
      if (response.data is String) {
        final csv = response.data as String;
        final transactionCount = csv.split('\n').length - 1;
        
        // Generate filename with date range and filters
        final filename = 'transactions_${dateRange.start.toIso8601String().split('T')[0]}_to_${dateRange.end.toIso8601String().split('T')[0]}.csv';
        
        // Download file
        final filePath = await CsvHelper.downloadCsv(csv, filename);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                filePath != null 
                  ? 'Saved $transactionCount transactions to:\n$filePath'
                  : 'Downloaded $transactionCount transactions'
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              } else if (value == 'clear_all') {
                _showClearAllConfirmDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Transactions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Active Filters
          if (_hasActiveFilters()) _buildActiveFilters(),

          // Transaction List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
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
                          style: TextStyle(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasActiveFilters()
                              ? 'Try adjusting your filters'
                              : 'Start adding your transactions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = provider.transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedType != null ||
        _selectedCategoryId != null ||
        _startDate != null ||
        _endDate != null;
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_searchController.text.isNotEmpty)
                  _buildFilterChip(
                    label: 'Search: "${_searchController.text}"',
                    onRemove: () {
                      _searchController.clear();
                    },
                  ),
                if (_selectedType != null)
                  _buildFilterChip(
                    label: _selectedType == 'income' ? 'Income' : 'Expense',
                    onRemove: () {
                      setState(() => _selectedType = null);
                      _applyFilters();
                    },
                  ),
                if (_selectedCategoryId != null)
                  Consumer<CategoryProvider>(
                    builder: (context, provider, child) {
                      final category = provider.getCategoryById(_selectedCategoryId!);
                      return _buildFilterChip(
                        label: category?.name ?? 'Category',
                        onRemove: () {
                          setState(() => _selectedCategoryId = null);
                          _applyFilters();
                        },
                      );
                    },
                  ),
                if (_startDate != null && _endDate != null)
                  _buildFilterChip(
                    label:
                        '${Formatters.date(_startDate!)} - ${Formatters.date(_endDate!)}',
                    onRemove: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.isIncome;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditTransactionScreen(
              transaction: transaction,
            ),
          ),
        );
        if (result == true && mounted) {
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.success : AppColors.danger)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIncome ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? 'Transaction',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          transaction.categoryName ?? 'Uncategorized',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          Formatters.date(transaction.date),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                Formatters.currency(transaction.amount),
                style: TextStyle(
                  color: isIncome ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Filter Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedType = null;
                          _selectedCategoryId = null;
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Filter
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterOption(
                            label: 'All',
                            isSelected: _selectedType == null,
                            onTap: () => setModalState(() => _selectedType = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterOption(
                            label: 'Income',
                            isSelected: _selectedType == 'income',
                            color: AppColors.success,
                            onTap: () =>
                                setModalState(() => _selectedType = 'income'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterOption(
                            label: 'Expense',
                            isSelected: _selectedType == 'expense',
                            color: AppColors.danger,
                            onTap: () =>
                                setModalState(() => _selectedType = 'expense'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category Filter
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<CategoryProvider>(
                      builder: (context, provider, child) {
                        final categories = _selectedType == 'income'
                            ? provider.incomeCategories
                            : _selectedType == 'expense'
                                ? provider.expenseCategories
                                : provider.categories;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterOption(
                              label: 'All',
                              isSelected: _selectedCategoryId == null,
                              onTap: () =>
                                  setModalState(() => _selectedCategoryId = null),
                            ),
                            ...categories.map((category) {
                              return _buildFilterOption(
                                label: category.name,
                                isSelected: _selectedCategoryId == category.id,
                                onTap: () => setModalState(
                                    () => _selectedCategoryId = category.id),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date Range
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await _selectDateRange();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${Formatters.date(_startDate!)} - ${Formatters.date(_endDate!)}'
                                  : 'Select date range',
                              style: TextStyle(
                                color: _startDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Update parent state
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.textSecondary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
