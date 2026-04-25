import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/recurring_transaction_model.dart';
import '../../../data/models/category_model.dart';

class AddEditRecurringScreen extends StatefulWidget {
  final RecurringTransactionModel? recurring;

  const AddEditRecurringScreen({super.key, this.recurring});

  @override
  State<AddEditRecurringScreen> createState() => _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState extends State<AddEditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategoryId;
  String? _selectedPaymentMethod = 'cash';
  String _selectedFrequency = 'monthly';
  int _selectedDayOfWeek = 1; // 1 = Monday
  int _selectedDayOfMonth = 1;
  int _selectedMonthOfYear = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;

  bool get isEditMode => widget.recurring != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });

    if (isEditMode) {
      final r = widget.recurring!;
      _amountController.text = r.amount.toString();
      _descriptionController.text = r.description ?? '';
      _notesController.text = r.notes ?? '';
      _selectedType = r.type;
      _selectedCategoryId = r.categoryId;
      _selectedPaymentMethod = r.paymentMethod ?? 'cash';
      _selectedFrequency = r.frequency;
      if (r.dayOfWeek != null) _selectedDayOfWeek = r.dayOfWeek!;
      if (r.dayOfMonth != null) _selectedDayOfMonth = r.dayOfMonth!;
      if (r.monthOfYear != null) _selectedMonthOfYear = r.monthOfYear!;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _hasEndDate = r.endDate != null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final initial = _endDate ?? _startDate.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      AppSnackbar.showWarning(context, 'Please select a category');
      return;
    }

    final data = {
      'amount': double.parse(_amountController.text),
      'type': _selectedType,
      'category': _selectedCategoryId,
      'description': _descriptionController.text.trim(),
      'paymentMethod': _selectedPaymentMethod,
      'notes': _notesController.text.trim(),
      'frequency': _selectedFrequency,
      'startDate': _startDate.toIso8601String(),
      'endDate': _hasEndDate && _endDate != null ? _endDate!.toIso8601String() : null,
    };

    if (_selectedFrequency == 'weekly') {
      data['dayOfWeek'] = _selectedDayOfWeek;
    } else if (_selectedFrequency == 'monthly') {
      data['dayOfMonth'] = _selectedDayOfMonth;
    } else if (_selectedFrequency == 'yearly') {
      data['dayOfMonth'] = _selectedDayOfMonth;
      data['monthOfYear'] = _selectedMonthOfYear;
    }

    final provider = context.read<RecurringProvider>();
    final success = isEditMode
        ? await provider.update(widget.recurring!.id, data)
        : await provider.create(data);

    if (mounted && success) {
      AppSnackbar.showSuccess(
        context,
        isEditMode ? 'Updated successfully' : 'Created successfully',
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Recurring' : 'Add Recurring'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: Validators.amount,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 16),

              _buildCategorySelector(),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              _buildDropdowns(),
              const SizedBox(height: 16),

              _buildSchedulingOptions(),
              const SizedBox(height: 24),

              Consumer<RecurringProvider>(
                builder: (context, provider, child) {
                  return CustomButton(
                    text: isEditMode ? 'Update' : 'Create',
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

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            type: 'income',
            label: 'Income',
            icon: Icons.arrow_downward,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeOption(
            type: 'expense',
            label: 'Expense',
            icon: Icons.arrow_upward,
            color: AppColors.danger,
          ),
        ),
      ],
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
          _selectedCategoryId = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final categories = _selectedType == 'income'
            ? provider.incomeCategories
            : provider.expenseCategories;

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val),
          validator: (val) => val == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedFrequency,
            decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
            ],
            onChanged: (val) => setState(() => _selectedFrequency = val!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
              DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
            ],
            onChanged: (val) => setState(() => _selectedPaymentMethod = val),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scheduling Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          
          if (_selectedFrequency == 'weekly')
            DropdownButtonFormField<int>(
              value: _selectedDayOfWeek,
              decoration: const InputDecoration(labelText: 'Day of week', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Sunday')),
                DropdownMenuItem(value: 1, child: Text('Monday')),
                DropdownMenuItem(value: 2, child: Text('Tuesday')),
                DropdownMenuItem(value: 3, child: Text('Wednesday')),
                DropdownMenuItem(value: 4, child: Text('Thursday')),
                DropdownMenuItem(value: 5, child: Text('Friday')),
                DropdownMenuItem(value: 6, child: Text('Saturday')),
              ],
              onChanged: (val) => setState(() => _selectedDayOfWeek = val!),
            ),
            
          if (_selectedFrequency == 'monthly' || _selectedFrequency == 'yearly')
            DropdownButtonFormField<int>(
              value: _selectedDayOfMonth,
              decoration: const InputDecoration(labelText: 'Day of month', border: OutlineInputBorder()),
              items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
              onChanged: (val) => setState(() => _selectedDayOfMonth = val!),
            ),
            
          if (_selectedFrequency == 'yearly') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedMonthOfYear,
              decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('January')),
                DropdownMenuItem(value: 2, child: Text('February')),
                DropdownMenuItem(value: 3, child: Text('March')),
                DropdownMenuItem(value: 4, child: Text('April')),
                DropdownMenuItem(value: 5, child: Text('May')),
                DropdownMenuItem(value: 6, child: Text('June')),
                DropdownMenuItem(value: 7, child: Text('July')),
                DropdownMenuItem(value: 8, child: Text('August')),
                DropdownMenuItem(value: 9, child: Text('September')),
                DropdownMenuItem(value: 10, child: Text('October')),
                DropdownMenuItem(value: 11, child: Text('November')),
                DropdownMenuItem(value: 12, child: Text('December')),
              ],
              onChanged: (val) => setState(() => _selectedMonthOfYear = val!),
            ),
          ],
          
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range),
            title: const Text('Start Date'),
            subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
            onTap: _selectStartDate,
            trailing: const Icon(Icons.edit, size: 16),
          ),
          
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has End Date'),
            value: _hasEndDate,
            onChanged: (val) => setState(() => _hasEndDate = val),
          ),
          
          if (_hasEndDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: const Text('End Date'),
              subtitle: Text(_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Not set'),
              onTap: _selectEndDate,
              trailing: const Icon(Icons.edit, size: 16),
            ),
        ],
      ),
    );
  }
}
