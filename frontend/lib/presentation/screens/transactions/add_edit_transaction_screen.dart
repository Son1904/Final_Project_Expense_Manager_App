import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/transaction_model.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null for add, not null for edit
  final String? initialType; // 'income' or 'expense'

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategoryId;
  String? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();

  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    // Load categories when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });

    // Initialize with transaction data if editing
    if (isEditMode) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedPaymentMethod = widget.transaction!.paymentMethod;
      _selectedType = widget.transaction!.type;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedDate = widget.transaction!.date;
    } else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final transactionProvider = context.read<TransactionProvider>();
    final amount = double.parse(_amountController.text);

    bool success;
    if (isEditMode) {
      success = await transactionProvider.updateTransaction(
        id: widget.transaction!.id,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
      );
    } else {
      success = await transactionProvider.createTransaction(
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Transaction updated successfully'
                : 'Transaction added successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactionProvider.errorMessage ??
                (isEditMode
                    ? 'Failed to update transaction'
                    : 'Failed to add transaction'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(),
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
              // Type Selector
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Amount Field
              CustomTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.amount,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Date Selector
              _buildDateSelector(),
              const SizedBox(height: 16),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Payment Method Field
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),

              // Save Button
              Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  return CustomButton(
                    text: isEditMode ? 'Update Transaction' : 'Add Transaction',
                    onPressed: provider.isLoading ? null : _handleSave,
                    isLoading: provider.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    const paymentMethods = [
      {'value': 'Cash', 'label': 'Cash', 'icon': Icons.money},
      {'value': 'Bank', 'label': 'Bank', 'icon': Icons.account_balance},
      {'value': 'Credit Card', 'label': 'Credit Card', 'icon': Icons.credit_card},
      {'value': 'E-Wallet', 'label': 'E-Wallet', 'icon': Icons.wallet},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...paymentMethods.map((method) => RadioListTile<String>(
            value: method['value'] as String,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            title: Row(
              children: [
                Icon(method['icon'] as IconData, size: 20),
                const SizedBox(width: 8),
                Text(method['label'] as String),
              ],
            ),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              type: 'income',
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.success,
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              type: 'expense',
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategoryId = null; // Reset category when type changes
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final categories = _selectedType == 'income'
            ? categoryProvider.incomeCategories
            : categoryProvider.expenseCategories;

        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No categories available',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((category) {
                final isSelected = _selectedCategoryId == category.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final transactionProvider = context.read<TransactionProvider>();
      final success =
          await transactionProvider.deleteTransaction(widget.transaction!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transactionProvider.errorMessage ??
                  'Failed to delete transaction',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
