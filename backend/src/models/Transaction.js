const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: [true, 'User ID is required'],
      index: true,
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0, 'Amount must be positive'],
    },
    type: {
      type: String,
      enum: ['income', 'expense'],
      required: [true, 'Transaction type is required'],
    },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    date: {
      type: Date,
      required: [true, 'Transaction date is required'],
      default: Date.now,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'bank_transfer', 'credit_card', 'debit_card', 'e_wallet', 'other'],
      default: 'cash',
    },
    tags: [
      {
        type: String,
        trim: true,
      },
    ],
    attachments: [
      {
        url: String,
        filename: String,
        mimeType: String,
        size: Number,
      },
    ],
    location: {
      latitude: Number,
      longitude: Number,
      address: String,
    },
    isRecurring: {
      type: Boolean,
      default: false,
    },
    recurringConfig: {
      frequency: {
        type: String,
        enum: ['daily', 'weekly', 'monthly', 'yearly'],
      },
      endDate: Date,
      nextDate: Date,
    },
    notes: {
      type: String,
      maxlength: [1000, 'Notes cannot exceed 1000 characters'],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ userId: 1, category: 1 });

// Virtual for formatted amount
transactionSchema.virtual('formattedAmount').get(function () {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(this.amount);
});

// Pre-save middleware to validate recurring config
transactionSchema.pre('save', function (next) {
  if (this.isRecurring && !this.recurringConfig?.frequency) {
    return next(new Error('Recurring frequency is required for recurring transactions'));
  }
  next();
});

// Instance method to duplicate transaction
transactionSchema.methods.duplicate = function () {
  const duplicated = this.toObject();
  delete duplicated._id;
  delete duplicated.createdAt;
  delete duplicated.updatedAt;
  duplicated.date = new Date();
  return new this.constructor(duplicated);
};

// Static method to get transactions by date range
transactionSchema.statics.getByDateRange = function (userId, startDate, endDate, options = {}) {
  const query = {
    userId,
    date: {
      $gte: new Date(startDate),
      $lte: new Date(endDate),
    },
  };

  if (options.type) {
    query.type = options.type;
  }

  if (options.category) {
    query.category = options.category;
  }

  return this.find(query)
    .populate('category', 'name icon color type')
    .sort({ date: -1 })
    .lean();
};

// Static method to get summary by period
transactionSchema.statics.getSummary = async function (userId, startDate, endDate) {
  const result = await this.aggregate([
    {
      $match: {
        userId,
        date: {
          $gte: new Date(startDate),
          $lte: new Date(endDate),
        },
      },
    },
    {
      $group: {
        _id: '$type',
        total: { $sum: '$amount' },
        count: { $sum: 1 },
      },
    },
  ]);

  const summary = {
    income: 0,
    expense: 0,
    balance: 0,
    transactionCount: 0,
  };

  result.forEach((item) => {
    summary[item._id] = item.total;
    summary.transactionCount += item.count;
  });

  summary.balance = summary.income - summary.expense;

  return summary;
};

// Static method to get spending by category
transactionSchema.statics.getSpendingByCategory = async function (userId, startDate, endDate) {
  return await this.aggregate([
    {
      $match: {
        userId,
        type: 'expense',
        date: {
          $gte: new Date(startDate),
          $lte: new Date(endDate),
        },
      },
    },
    {
      $group: {
        _id: '$category',
        total: { $sum: '$amount' },
        count: { $sum: 1 },
      },
    },
    {
      $lookup: {
        from: 'categories',
        localField: '_id',
        foreignField: '_id',
        as: 'category',
      },
    },
    {
      $unwind: '$category',
    },
    {
      $project: {
        _id: 1,
        total: 1,
        count: 1,
        categoryName: '$category.name',
        categoryIcon: '$category.icon',
        categoryColor: '$category.color',
      },
    },
    {
      $sort: { total: -1 },
    },
  ]);
};

const Transaction = mongoose.model('Transaction', transactionSchema);

module.exports = Transaction;
