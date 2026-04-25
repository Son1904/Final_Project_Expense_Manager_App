/**
 * Recurring Transaction Controller
 * Handles CRUD operations for recurring transaction templates
 * Uses MongoDB for storage
 */

const { Category } = require('../models');
const RecurringTransaction = require('../models/RecurringTransaction');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const logger = require('../utils/logger');
const { processRecurringTransactions } = require('../scheduler/recurringScheduler');

/**
 * Create a new recurring transaction
 * @route POST /api/recurring-transactions
 * @access Private
 */
const createRecurring = asyncHandler(async (req, res) => {
  const {
    amount,
    type,
    category,
    description,
    paymentMethod,
    notes,
    frequency,
    dayOfWeek,
    dayOfMonth,
    monthOfYear,
    startDate,
    endDate,
  } = req.body;

  // Validate required fields
  if (!amount || !type || !category || !frequency || !startDate) {
    throw new AppError('Amount, type, category, frequency, and startDate are required', 400);
  }

  // Validate type
  if (type !== 'income' && type !== 'expense') {
    throw new AppError('Type must be either income or expense', 400);
  }

  // Validate frequency
  const validFrequencies = ['daily', 'weekly', 'monthly', 'yearly'];
  if (!validFrequencies.includes(frequency)) {
    throw new AppError('Frequency must be one of: daily, weekly, monthly, yearly', 400);
  }

  // Validate frequency-specific fields
  if (frequency === 'weekly' && (dayOfWeek === undefined || dayOfWeek === null)) {
    throw new AppError('dayOfWeek is required for weekly frequency (0=Sun, 6=Sat)', 400);
  }
  if (frequency === 'monthly' && !dayOfMonth) {
    throw new AppError('dayOfMonth is required for monthly frequency (1-31)', 400);
  }
  if (frequency === 'yearly' && (!dayOfMonth || !monthOfYear)) {
    throw new AppError('dayOfMonth and monthOfYear are required for yearly frequency', 400);
  }

  // Verify category exists and belongs to user
  const categoryDoc = await Category.findOne({
    _id: category,
    userId: req.user.id,
  });

  if (!categoryDoc) {
    throw new AppError('Category not found or does not belong to you', 404);
  }

  // Validate category type matches transaction type
  if (categoryDoc.type !== type) {
    throw new AppError(
      `Category type (${categoryDoc.type}) does not match transaction type (${type})`,
      400
    );
  }

  // Calculate first execution date
  const start = new Date(startDate);
  let nextExecutionDate = new Date(start);

  // We don't push past dates to the future here.
  // If the user selects a past date, the cron scheduler will pick it up
  // on its next cycle and execute it immediately, then schedule the next occurrence.

  // Create recurring transaction
  const recurring = await RecurringTransaction.create({
    userId: req.user.id,
    amount,
    type,
    category,
    description,
    paymentMethod: paymentMethod || 'cash',
    notes,
    frequency,
    dayOfWeek,
    dayOfMonth,
    monthOfYear,
    startDate: start,
    endDate: endDate ? new Date(endDate) : null,
    nextExecutionDate,
  });

  // Populate category
  await recurring.populate('category', 'name icon color type');

  // Real-time processing: If the user sets a date that is already due, 
  // trigger the scheduler instantly in the background so they don't have to wait.
  if (recurring.nextExecutionDate <= new Date()) {
    setTimeout(() => {
      processRecurringTransactions().catch(e => logger.error('Real-time scheduler error:', e));
    }, 1000);
  }

  res.status(201).json({
    status: 'success',
    message: 'Recurring transaction created successfully',
    data: { recurring },
  });
});

/**
 * Get all recurring transactions for user
 * @route GET /api/recurring-transactions
 * @access Private
 */
const getRecurringTransactions = asyncHandler(async (req, res) => {
  const { frequency, type, active } = req.query;

  const query = { userId: req.user.id };

  if (frequency) query.frequency = frequency;
  if (type) query.type = type;
  if (active !== undefined) query.isActive = active === 'true';

  const transactions = await RecurringTransaction.find(query)
    .populate('category', 'name icon color type')
    .sort({ nextExecutionDate: 1 });

  res.status(200).json({
    status: 'success',
    data: { recurring: transactions },
  });
});

/**
 * Get upcoming recurring transactions (next 7 days)
 * @route GET /api/recurring-transactions/upcoming
 * @access Private
 */
const getUpcoming = asyncHandler(async (req, res) => {
  const { days = 7 } = req.query;

  const upcoming = await RecurringTransaction.getUpcoming(
    req.user.id,
    parseInt(days)
  );

  res.status(200).json({
    status: 'success',
    data: { upcoming },
  });
});

/**
 * Get single recurring transaction by ID
 * @route GET /api/recurring-transactions/:id
 * @access Private
 */
const getRecurringById = asyncHandler(async (req, res) => {
  const recurring = await RecurringTransaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  }).populate('category', 'name icon color type');

  if (!recurring) {
    throw new AppError('Recurring transaction not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: { recurring },
  });
});

/**
 * Update recurring transaction
 * @route PUT /api/recurring-transactions/:id
 * @access Private
 */
const updateRecurring = asyncHandler(async (req, res) => {
  const recurring = await RecurringTransaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!recurring) {
    throw new AppError('Recurring transaction not found', 404);
  }

  const {
    amount,
    type,
    category,
    description,
    paymentMethod,
    notes,
    frequency,
    dayOfWeek,
    dayOfMonth,
    monthOfYear,
    startDate,
    endDate,
  } = req.body;

  // If updating category, verify ownership and type match
  if (category) {
    const categoryDoc = await Category.findOne({
      _id: category,
      userId: req.user.id,
    });
    if (!categoryDoc) {
      throw new AppError('Category not found or does not belong to you', 404);
    }
    const txType = type || recurring.type;
    if (categoryDoc.type !== txType) {
      throw new AppError(
        `Category type (${categoryDoc.type}) does not match transaction type (${txType})`,
        400
      );
    }
    recurring.category = category;
  }

  // Update fields
  if (amount !== undefined) recurring.amount = amount;
  if (type) recurring.type = type;
  if (description !== undefined) recurring.description = description;
  if (paymentMethod) recurring.paymentMethod = paymentMethod;
  if (notes !== undefined) recurring.notes = notes;
  if (frequency) recurring.frequency = frequency;
  if (dayOfWeek !== undefined) recurring.dayOfWeek = dayOfWeek;
  if (dayOfMonth !== undefined) recurring.dayOfMonth = dayOfMonth;
  if (monthOfYear !== undefined) recurring.monthOfYear = monthOfYear;
  if (startDate) recurring.startDate = new Date(startDate);
  if (endDate !== undefined) recurring.endDate = endDate ? new Date(endDate) : null;

  // If the user changed the schedule, recalculate next execution date 
  // based on the start date (or last executed) instead of just "now" 
  // so it doesn't skip if they intentionally set a past date
  if (frequency || dayOfWeek !== undefined || dayOfMonth !== undefined || monthOfYear !== undefined) {
    if (recurring.lastExecutedAt) {
      recurring.nextExecutionDate = recurring.calculateNextDate(recurring.lastExecutedAt);
    } else {
      const start = new Date(recurring.startDate);
      recurring.nextExecutionDate = start;
    }
  }

  await recurring.save();
  await recurring.populate('category', 'name icon color type');

  res.status(200).json({
    status: 'success',
    message: 'Recurring transaction updated successfully',
    data: { recurring },
  });
});

/**
 * Toggle pause/resume recurring transaction
 * @route PATCH /api/recurring-transactions/:id/toggle
 * @access Private
 */
const toggleRecurring = asyncHandler(async (req, res) => {
  const recurring = await RecurringTransaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!recurring) {
    throw new AppError('Recurring transaction not found', 404);
  }

  recurring.isActive = !recurring.isActive;

  // If reactivating, recalculate next execution date
  if (recurring.isActive) {
    recurring.nextExecutionDate = recurring.calculateNextDate(new Date());
  }

  await recurring.save();
  await recurring.populate('category', 'name icon color type');

  res.status(200).json({
    status: 'success',
    message: recurring.isActive
      ? 'Recurring transaction resumed'
      : 'Recurring transaction paused',
    data: { recurring },
  });
});

/**
 * Delete recurring transaction
 * @route DELETE /api/recurring-transactions/:id
 * @access Private
 */
const deleteRecurring = asyncHandler(async (req, res) => {
  const recurring = await RecurringTransaction.findOneAndDelete({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!recurring) {
    throw new AppError('Recurring transaction not found', 404);
  }

  res.status(200).json({
    status: 'success',
    message: 'Recurring transaction deleted successfully',
  });
});

module.exports = {
  createRecurring,
  getRecurringTransactions,
  getUpcoming,
  getRecurringById,
  updateRecurring,
  toggleRecurring,
  deleteRecurring,
};
