class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }
    
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Full name validation
  static String? fullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    
    return null;
  }

  // Phone validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // International phone number format (flexible)
    final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number';
    }
    
    return null;
  }

  // Amount validation
  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    
    if (amount == null) {
      return 'Invalid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    
    return null;
  }

  // Category name validation
  static String? categoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category name is required';
    }
    
    if (value.length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    return null;
  }

  // Description validation (optional field)
  static String? description(String? value) {
    if (value != null && value.isNotEmpty && value.length > 500) {
      return 'Description must not exceed 500 characters';
    }
    
    return null;
  }
}
