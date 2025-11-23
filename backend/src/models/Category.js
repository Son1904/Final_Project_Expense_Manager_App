const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: [true, 'User ID is required'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Category name is required'],
      trim: true,
      maxlength: [50, 'Category name cannot exceed 50 characters'],
    },
    type: {
      type: String,
      enum: ['income', 'expense'],
      required: [true, 'Category type is required'],
    },
    icon: {
      type: String,
      default: 'default',
    },
    color: {
      type: String,
      default: '#3498db',
      validate: {
        validator: function (v) {
          return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(v);
        },
        message: 'Invalid color format. Use hex color format (e.g., #3498db)',
      },
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for user and category name uniqueness
categorySchema.index({ userId: 1, name: 1 }, { unique: true });

// Virtual for transaction count
categorySchema.virtual('transactionCount', {
  ref: 'Transaction',
  localField: '_id',
  foreignField: 'category',
  count: true,
});

// Instance method to check if category can be deleted
categorySchema.methods.canDelete = async function () {
  const Transaction = mongoose.model('Transaction');
  const count = await Transaction.countDocuments({ category: this._id });
  return count === 0;
};

// Static method to get categories by user
categorySchema.statics.getByUser = function (userId, type = null) {
  const query = { userId, isActive: true };
  if (type) {
    query.type = type;
  }
  return this.find(query).sort({ name: 1 });
};

// Static method to create default categories for new user
categorySchema.statics.createDefaultCategories = async function (userId) {
  const defaultCategories = [
    // Expense categories
    { name: 'Food & Dining', type: 'expense', icon: 'restaurant', color: '#e74c3c' },
    { name: 'Transportation', type: 'expense', icon: 'car', color: '#3498db' },
    { name: 'Shopping', type: 'expense', icon: 'shopping-cart', color: '#9b59b6' },
    { name: 'Entertainment', type: 'expense', icon: 'movie', color: '#f39c12' },
    { name: 'Bills & Utilities', type: 'expense', icon: 'file-text', color: '#e67e22' },
    { name: 'Healthcare', type: 'expense', icon: 'heart', color: '#1abc9c' },
    { name: 'Education', type: 'expense', icon: 'book', color: '#34495e' },
    { name: 'Other Expense', type: 'expense', icon: 'more-horizontal', color: '#95a5a6' },
    // Income categories
    { name: 'Salary', type: 'income', icon: 'dollar-sign', color: '#27ae60' },
    { name: 'Freelance', type: 'income', icon: 'briefcase', color: '#16a085' },
    { name: 'Investment', type: 'income', icon: 'trending-up', color: '#2ecc71' },
    { name: 'Gift', type: 'income', icon: 'gift', color: '#f1c40f' },
    { name: 'Other Income', type: 'income', icon: 'plus-circle', color: '#1abc9c' },
  ];

  const categories = defaultCategories.map((cat) => ({
    ...cat,
    userId,
    isDefault: true,
  }));

  return await this.insertMany(categories);
};

const Category = mongoose.model('Category', categorySchema);

module.exports = Category;
