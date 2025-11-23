import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final BudgetModel? budget; // null for add, not null for edit

  const AddEditBudgetScreen({
    super.key,
    this.budget,
  });

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  List<String> _selectedCategoryIds = [];
  double _alertThreshold = 80.0;
  bool _alertEnabled = true;
  bool _repeatAutomatically = false;

  bool get isEditMode => widget.budget != null;

  final List<Map<String, String>> _periods = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
    {'value': 'custom', 'label': 'Custom'},
  ];

  final Map<String, IconData> _periodIcons = {
    'daily': Icons.today,
    'weekly': Icons.date_range,
    'monthly': Icons.calendar_month,
    'yearly': Icons.calendar_today,
    'custom': Icons.edit_calendar,
  };

  @override
  void initState() {
    super.initState();

    // Listen to amount changes for preview
    _amountController.addListener(() {
      setState(() {});
    });

    // Load categories when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });

    // Initialize with budget data if editing
    if (isEditMode) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.amount.toStringAsFixed(0);
      _selectedPeriod = widget.budget!.period;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _selectedCategoryIds =
          widget.budget!.categories.map((cat) => cat.id).toList();
      _alertThreshold = widget.budget!.alertThreshold;
      _alertEnabled = widget.budget!.alertEnabled;
      _repeatAutomatically = widget.budget!.repeatAutomatically;
    } else {
      // Set default end date based on period
      _updateEndDateForPeriod(_selectedPeriod);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateEndDateForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'daily':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'custom':
        // Keep current dates
        break;
    }
    setState(() {});
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
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

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _showCategorySelector() async {
    final categoryProvider = context.read<CategoryProvider>();
    final expenseCategories =
        categoryProvider.categories.where((cat) => cat.type == 'expense').toList();

    if (expenseCategories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expense categories available'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _CategorySelectorDialog(
        categories: expenseCategories,
        selectedIds: _selectedCategoryIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCategoryIds = selected;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount greater than 0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final budgetProvider = context.read<BudgetProvider>();

    bool success;
    if (isEditMode) {
      success = await budgetProvider.updateBudget(
        widget.budget!.id,
        UpdateBudgetRequest(
          name: _nameController.text.trim(),
          amount: amount,
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
          categoryIds: _selectedCategoryIds,
          alertThreshold: _alertThreshold,
          alertEnabled: _alertEnabled,
          repeatAutomatically: _repeatAutomatically,
        ),
      );
    } else {
      success = await budgetProvider.createBudget(
        CreateBudgetRequest(
          name: _nameController.text.trim(),
          amount: amount,
          period: _selectedPeriod,
          startDate: _startDate,
          endDate: _endDate,
          categoryIds: _selectedCategoryIds,
          alertThreshold: _alertThreshold,
          alertEnabled: _alertEnabled,
          repeatAutomatically: _repeatAutomatically,
        ),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Budget updated successfully'
                : 'Budget created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            budgetProvider.errorMessage ??
                (isEditMode ? 'Failed to update budget' : 'Failed to create budget'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final budgetProvider = context.read<BudgetProvider>();
      final success = await budgetProvider.deleteBudget(widget.budget!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              budgetProvider.errorMessage ?? 'Failed to delete budget',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Budget' : 'Create Budget'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Budget Name',
                prefixIcon: Icons.label_outline,
                validator: Validators.required,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'e.g., "Monthly Groceries", "Entertainment Budget"',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              CustomTextField(
                controller: _amountController,
                label: 'Budget Amount',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.required,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              
              // Amount Preview
              if (_amountController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Budget: ${Formatters.currency(double.tryParse(_amountController.text) ?? 0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Quick Amount Presets
              _buildQuickAmountPresets(),
              const SizedBox(height: 24),

              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Date Range
              _buildDateRangePicker(),
              const SizedBox(height: 24),

              // Categories Selector
              _buildCategorySelector(categoryProvider),
              const SizedBox(height: 24),

              // Alert Settings
              _buildAlertSettings(),
              const SizedBox(height: 24),

              // Repeat Automatically
              _buildRepeatToggle(),
              const SizedBox(height: 24),

              // Budget Summary Preview
              if (_amountController.text.isNotEmpty && _nameController.text.isNotEmpty)
                _buildBudgetSummary(),
              
              if (_amountController.text.isNotEmpty && _nameController.text.isNotEmpty)
                const SizedBox(height: 24),

              // Save Button
              CustomButton(
                text: isEditMode ? 'Update Budget' : 'Create Budget',
                onPressed: _handleSave,
                icon: isEditMode ? Icons.check : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountPresets() {
    final presets = [
      {'label': '1M', 'value': 1000000},
      {'label': '2M', 'value': 2000000},
      {'label': '5M', 'value': 5000000},
      {'label': '10M', 'value': 10000000},
      {'label': '20M', 'value': 20000000},
      {'label': '50M', 'value': 50000000},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        return OutlinedButton(
          onPressed: () {
            setState(() {
              _amountController.text = preset['value'].toString();
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: Text(
            preset['label'] as String,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _periods.map((period) {
            final isSelected = _selectedPeriod == period['value'];
            final icon = _periodIcons[period['value']!];
            
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(period['label']!),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period['value']!;
                    if (_selectedPeriod != 'custom') {
                      _updateEndDateForPeriod(_selectedPeriod);
                    }
                  });
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
        if (_selectedPeriod != 'custom') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getPeriodDescription(_selectedPeriod),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getPeriodDescription(String period) {
    final days = _endDate.difference(_startDate).inDays;
    switch (period) {
      case 'daily':
        return 'Budget resets every day (24 hours)';
      case 'weekly':
        return 'Budget resets every week (7 days)';
      case 'monthly':
        return 'Budget resets every month ($days days this month)';
      case 'yearly':
        return 'Budget resets every year (365 days)';
      default:
        return '';
    }
  }

  Widget _buildDateRangePicker() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectedPeriod == 'custom' ? _selectStartDate : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: _selectedPeriod == 'custom'
                            ? Colors.white
                            : AppColors.gray100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(_startDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectedPeriod == 'custom' ? _selectEndDate : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: _selectedPeriod == 'custom'
                            ? Colors.white
                            : AppColors.gray100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(_endDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedPeriod != 'custom')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select "Custom" period to change dates',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(CategoryProvider categoryProvider) {
    final selectedCategories = categoryProvider.categories
        .where((cat) => _selectedCategoryIds.contains(cat.id))
        .toList();

    return Card(
      child: InkWell(
        onTap: _showCategorySelector,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selectedCategories.isEmpty
                    ? 'All Categories'
                    : '${selectedCategories.length} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (selectedCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedCategories.map((cat) {
                    return Chip(
                      label: Text(
                        cat.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: Icon(
                        Icons.category,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedCategoryIds.remove(cat.id);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _alertEnabled,
                  onChanged: (value) {
                    setState(() {
                      _alertEnabled = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            if (_alertEnabled) ...[
              const SizedBox(height: 16),
              Text(
                'Alert Threshold: ${_alertThreshold.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Slider(
                value: _alertThreshold,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${_alertThreshold.toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _alertThreshold = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              Text(
                'You will be alerted when spending reaches ${_alertThreshold.toInt()}% of budget',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final days = _endDate.difference(_startDate).inDays;
    final dailyLimit = days > 0 ? (amount / days).toDouble() : 0.0;

    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Budget Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Name', _nameController.text),
            _buildSummaryRow('Total Budget', Formatters.currency(amount)),
            _buildSummaryRow('Period', _periods.firstWhere((p) => p['value'] == _selectedPeriod)['label']!),
            _buildSummaryRow('Duration', '$days days'),
            _buildSummaryRow('Daily Limit', Formatters.currency(dailyLimit)),
            _buildSummaryRow('Categories', _selectedCategoryIds.isEmpty ? 'All Categories' : '${_selectedCategoryIds.length} selected'),
            if (_alertEnabled)
              _buildSummaryRow('Alert at', '${_alertThreshold.toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repeat Automatically',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create next period budget automatically',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _repeatAutomatically,
              onChanged: (value) {
                setState(() {
                  _repeatAutomatically = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// Category Selector Dialog
class _CategorySelectorDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<String> selectedIds;

  const _CategorySelectorDialog({
    required this.categories,
    required this.selectedIds,
  });

  @override
  State<_CategorySelectorDialog> createState() =>
      _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<_CategorySelectorDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final isSelected = _selectedIds.contains(category.id);

            return CheckboxListTile(
              title: Text(category.name),
              subtitle: Text(category.type),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(category.id);
                  } else {
                    _selectedIds.remove(category.id);
                  }
                });
              },
              activeColor: AppColors.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
