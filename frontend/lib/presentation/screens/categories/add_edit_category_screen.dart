import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  final String? initialType;

  const AddEditCategoryScreen({
    super.key,
    this.category,
    this.initialType,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'expense';

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
    } else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();

    bool success;
    if (isEditMode) {
      success = await categoryProvider.updateCategory(
        id: widget.category!.id,
        name: _nameController.text.trim(),
      );
    } else {
      success = await categoryProvider.createCategory(
        name: _nameController.text.trim(),
        type: _selectedType,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Category updated successfully'
                : 'Category created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoryProvider.errorMessage ??
                (isEditMode
                    ? 'Failed to update category'
                    : 'Failed to create category'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
          'Are you sure you want to delete this category? Transactions using this category will need to be reassigned.',
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
      final categoryProvider = context.read<CategoryProvider>();
      final success = await categoryProvider.deleteCategory(widget.category!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              categoryProvider.errorMessage ?? 'Failed to delete category',
            ),
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
        title: Text(isEditMode ? 'Edit Category' : 'Add Category'),
        actions: [
          if (isEditMode && !widget.category!.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
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
              // Type Selector (only for new category)
              if (!isEditMode) ...[
                _buildTypeSelector(),
                const SizedBox(height: 24),
              ],

              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Category Name',
                prefixIcon: Icons.category,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  return CustomButton(
                    text: isEditMode ? 'Update Category' : 'Create Category',
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
}
