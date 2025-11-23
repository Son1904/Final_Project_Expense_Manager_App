const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: [true, 'User ID is required'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Budget name is required'],
      trim: true,
      maxlength: [100, 'Budget name cannot exceed 100 characters'],
    },
    amount: {
      type: Number,
      required: [true, 'Budget amount is required'],
      min: [0, 'Budget amount must be positive'],
    },
    spent: {
      type: Number,
      default: 0,
      min: [0, 'Spent amount cannot be negative'],
    },
    period: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly', 'custom'],
      required: [true, 'Budget period is required'],
      default: 'monthly',
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    categories: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
      },
    ],
    alertThreshold: {
      type: Number,
      min: [0, 'Alert threshold must be between 0 and 100'],
      max: [100, 'Alert threshold must be between 0 and 100'],
      default: 80,
    },
    alertEnabled: {
      type: Boolean,
      default: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    repeatAutomatically: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
budgetSchema.index({ userId: 1, startDate: -1 });
budgetSchema.index({ userId: 1, isActive: 1 });

// Validate end date is after start date
budgetSchema.pre('save', function (next) {
  if (this.endDate <= this.startDate) {
    return next(new Error('End date must be after start date'));
  }
  next();
});

// Virtual for remaining amount
budgetSchema.virtual('remaining').get(function () {
  return Math.max(0, this.amount - this.spent);
});

// Virtual for percentage used
budgetSchema.virtual('percentageUsed').get(function () {
  return this.amount > 0 ? (this.spent / this.amount) * 100 : 0;
});

// Virtual for status
budgetSchema.virtual('status').get(function () {
  const percentage = this.percentageUsed;
  if (percentage >= 100) return 'exceeded';
  if (percentage >= this.alertThreshold) return 'warning';
  return 'ok';
});

// Virtual for is alert needed
budgetSchema.virtual('needsAlert').get(function () {
  return this.alertEnabled && this.percentageUsed >= this.alertThreshold;
});

// Enable virtuals in JSON
budgetSchema.set('toJSON', { virtuals: true });
budgetSchema.set('toObject', { virtuals: true });

// Instance method to update spent amount
budgetSchema.methods.updateSpent = async function () {
  const Transaction = mongoose.model('Transaction');

  const result = await Transaction.aggregate([
    {
      $match: {
        userId: this.userId,
        type: 'expense',
        date: {
          $gte: this.startDate,
          $lte: this.endDate,
        },
        category: { $in: this.categories },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$amount' },
      },
    },
  ]);

  this.spent = result.length > 0 ? result[0].total : 0;
  await this.save();
  return this.spent;
};

// Static method to get active budgets for user
budgetSchema.statics.getActiveBudgets = function (userId) {
  const now = new Date();
  return this.find({
    userId,
    isActive: true,
    startDate: { $lte: now },
    endDate: { $gte: now },
  })
    .populate('categories', 'name icon color')
    .sort({ createdAt: -1 });
};

// Static method to check and create recurring budgets
budgetSchema.statics.createRecurringBudgets = async function () {
  const now = new Date();
  const expiredBudgets = await this.find({
    isActive: true,
    repeatAutomatically: true,
    endDate: { $lt: now },
  });

  const newBudgets = [];

  for (const budget of expiredBudgets) {
    let newStartDate, newEndDate;

    switch (budget.period) {
      case 'daily':
        newStartDate = new Date(budget.startDate);
        newStartDate.setDate(newStartDate.getDate() + 1);
        newEndDate = new Date(budget.endDate);
        newEndDate.setDate(newEndDate.getDate() + 1);
        break;
      case 'weekly':
        newStartDate = new Date(budget.startDate);
        newStartDate.setDate(newStartDate.getDate() + 7);
        newEndDate = new Date(budget.endDate);
        newEndDate.setDate(newEndDate.getDate() + 7);
        break;
      case 'monthly':
        newStartDate = new Date(budget.startDate);
        newStartDate.setMonth(newStartDate.getMonth() + 1);
        newEndDate = new Date(budget.endDate);
        newEndDate.setMonth(newEndDate.getMonth() + 1);
        break;
      case 'yearly':
        newStartDate = new Date(budget.startDate);
        newStartDate.setFullYear(newStartDate.getFullYear() + 1);
        newEndDate = new Date(budget.endDate);
        newEndDate.setFullYear(newEndDate.getFullYear() + 1);
        break;
      default:
        continue;
    }

    const newBudget = new this({
      userId: budget.userId,
      name: budget.name,
      amount: budget.amount,
      period: budget.period,
      startDate: newStartDate,
      endDate: newEndDate,
      categories: budget.categories,
      alertThreshold: budget.alertThreshold,
      alertEnabled: budget.alertEnabled,
      repeatAutomatically: budget.repeatAutomatically,
    });

    newBudgets.push(newBudget);
  }

  if (newBudgets.length > 0) {
    await this.insertMany(newBudgets);
  }

  return newBudgets.length;
};

const Budget = mongoose.model('Budget', budgetSchema);

module.exports = Budget;
