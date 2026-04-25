const mongoose = require('mongoose');

const recurringTransactionSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: [true, 'User ID is required'],
      index: true,
    },
    // Transaction template fields
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
    paymentMethod: {
      type: String,
      enum: ['cash', 'bank_transfer', 'credit_card', 'debit_card', 'e_wallet', 'other'],
      default: 'cash',
    },
    notes: {
      type: String,
      maxlength: [1000, 'Notes cannot exceed 1000 characters'],
    },

    // Scheduling fields
    frequency: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly'],
      required: [true, 'Frequency is required'],
    },
    dayOfWeek: {
      type: Number, // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      min: 0,
      max: 6,
    },
    dayOfMonth: {
      type: Number, // 1-31
      min: 1,
      max: 31,
    },
    monthOfYear: {
      type: Number, // 1-12
      min: 1,
      max: 12,
    },

    // Execution tracking
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date, // null = no end date (runs forever)
      default: null,
    },
    nextExecutionDate: {
      type: Date,
      required: [true, 'Next execution date is required'],
    },
    lastExecutedAt: {
      type: Date,
      default: null,
    },
    executionCount: {
      type: Number,
      default: 0,
    },

    // Status
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
recurringTransactionSchema.index({ userId: 1, isActive: 1 });
recurringTransactionSchema.index({ nextExecutionDate: 1, isActive: 1 });

// Validate scheduling fields based on frequency
recurringTransactionSchema.pre('save', function (next) {
  if (this.frequency === 'weekly' && (this.dayOfWeek === undefined || this.dayOfWeek === null)) {
    return next(new Error('dayOfWeek is required for weekly frequency'));
  }
  if (this.frequency === 'monthly' && !this.dayOfMonth) {
    return next(new Error('dayOfMonth is required for monthly frequency'));
  }
  if (this.frequency === 'yearly' && (!this.dayOfMonth || !this.monthOfYear)) {
    return next(new Error('dayOfMonth and monthOfYear are required for yearly frequency'));
  }
  next();
});

/**
 * Calculate the next execution date after a given date
 * @param {Date} afterDate - Calculate next date after this date
 * @returns {Date} Next execution date
 */
recurringTransactionSchema.methods.calculateNextDate = function (afterDate = new Date()) {
  const current = new Date(afterDate);
  let next;

  switch (this.frequency) {
    case 'daily':
      next = new Date(current);
      next.setDate(next.getDate() + 1);
      break;

    case 'weekly':
      next = new Date(current);
      // Find next occurrence of the target day of week
      const targetDay = this.dayOfWeek;
      const currentDay = next.getDay();
      let daysUntilTarget = targetDay - currentDay;
      if (daysUntilTarget <= 0) daysUntilTarget += 7;
      next.setDate(next.getDate() + daysUntilTarget);
      break;

    case 'monthly':
      next = new Date(current);
      next.setMonth(next.getMonth() + 1);
      // Handle months with fewer days (e.g., dayOfMonth=31 in February)
      const targetDayOfMonth = Math.min(this.dayOfMonth, new Date(next.getFullYear(), next.getMonth() + 1, 0).getDate());
      next.setDate(targetDayOfMonth);
      break;

    case 'yearly':
      next = new Date(current);
      next.setFullYear(next.getFullYear() + 1);
      next.setMonth(this.monthOfYear - 1); // monthOfYear is 1-indexed
      const maxDay = new Date(next.getFullYear(), next.getMonth() + 1, 0).getDate();
      next.setDate(Math.min(this.dayOfMonth, maxDay));
      break;

    default:
      next = new Date(current);
      next.setMonth(next.getMonth() + 1);
  }

  return next;
};

/**
 * Get all due recurring transactions (ready to execute)
 * Static method used by the scheduler
 */
recurringTransactionSchema.statics.getDueTransactions = function () {
  const now = new Date();
  return this.find({
    isActive: true,
    nextExecutionDate: { $lte: now },
    $or: [
      { endDate: null },          // No end date
      { endDate: { $gte: now } }, // End date hasn't passed
    ],
  }).populate('category', 'name icon color type');
};

/**
 * Get upcoming transactions for a user (next 7 days)
 */
recurringTransactionSchema.statics.getUpcoming = function (userId, days = 7) {
  const now = new Date();
  const future = new Date();
  future.setDate(future.getDate() + days);

  return this.find({
    userId,
    isActive: true,
    nextExecutionDate: { $gte: now, $lte: future },
    $or: [
      { endDate: null },
      { endDate: { $gte: now } },
    ],
  })
    .populate('category', 'name icon color type')
    .sort({ nextExecutionDate: 1 });
};

// Enable virtuals
recurringTransactionSchema.set('toJSON', { virtuals: true });
recurringTransactionSchema.set('toObject', { virtuals: true });

const RecurringTransaction = mongoose.model('RecurringTransaction', recurringTransactionSchema);

module.exports = RecurringTransaction;
