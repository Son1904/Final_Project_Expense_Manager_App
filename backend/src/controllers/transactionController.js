/**
 * Transaction Controller
 * Handles CRUD operations for transactions and analytics
 * Uses MongoDB for transaction data storage
 */

const { Transaction, Category } = require('../models');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const logger = require('../utils/logger');
const { createNotification } = require('./notificationController');
const { checkBudgetAlert } = require('./budgetController');
const { isNotificationEnabled } = require('./settingsController');

/**
 * Create a new transaction
 * @route POST /api/transactions
 * @access Private
 * @param {number} amount - Transaction amount (required)
 * @param {string} type - 'income' or 'expense' (required)
 * @param {string} category - Category ID (required, must belong to user)
 * @param {string} description - Transaction description (optional)
 * @param {date} date - Transaction date (optional, defaults to now)
 * @param {string} paymentMethod - Payment method (optional, defaults to 'cash')
 * @param {string} bankAccountId - Bank account ID (optional)
 * @param {array} tags - Array of tags (optional)
 * @param {object} location - Location data (optional)
 * @param {string} notes - Additional notes (optional)
 * @returns {object} Created transaction with populated category
 */
const createTransaction = asyncHandler(async (req, res) => {
  const {
    amount,
    type,
    category,
    description,
    date,
    paymentMethod,
    bankAccountId,
    tags,
    location,
    notes,
  } = req.body;

  // Validate required fields
  if (!amount || !type || !category) {
    throw new AppError('Amount, type, and category are required', 400);
  }

  // Validate transaction type
  if (type !== 'income' && type !== 'expense') {
    throw new AppError('Type must be either income or expense', 400);
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
    throw new AppError(`Category type (${categoryDoc.type}) does not match transaction type (${type})`, 400);
  }

  // Create transaction in MongoDB
  const transaction = await Transaction.create({
    userId: req.user.id,
    amount,
    type,
    category,
    description,
    date: date || new Date(),
    paymentMethod: paymentMethod || 'cash',
    bankAccountId,
    tags,
    location,
    notes,
  });

  // Populate category details before returning
  const populatedTransaction = await Transaction.findById(transaction._id)
    .populate('category', 'name icon color type');

  // Check for large transaction notification (>= $1,000 USD)
  if (amount >= 1000) {
    try {
      // Check if user has this notification enabled
      const isEnabled = await isNotificationEnabled(req.user.id.toString(), 'LARGE_TRANSACTION');
      
      if (isEnabled) {
        await createNotification(req.user.id.toString(), {
          type: 'LARGE_TRANSACTION',
          title: 'Large transaction detected',
          message: `${type === 'expense' ? 'Expense' : 'Income'} of ${formatCurrency(amount)} on ${categoryDoc.name}`,
          priority: 'MEDIUM',
          referenceType: 'TRANSACTION',
          referenceId: transaction._id.toString(),
          metadata: {
            amount,
            type,
            categoryName: categoryDoc.name,
            description
          }
        });
        console.log('Large transaction notification created');
      } else {
        console.log('Large transaction notification skipped (disabled by user)');
      }
    } catch (error) {
      console.error('Error creating large transaction notification:', error);
    }
  }

  // Update related budgets and check alerts
  if (type === 'expense') {
    await updateBudgetsAfterTransaction(req.user.id.toString(), category);
  }

  res.status(201).json({
    status: 'success',
    message: 'Transaction created successfully',
    data: {
      transaction: populatedTransaction,
    },
  });
});

/**
 * Get all transactions for authenticated user
 * @route GET /api/transactions
 * @access Private
 * @query {string} search - Search by description or notes
 * @query {string} type - Filter by 'income' or 'expense'
 * @query {string} category - Filter by category ID
 * @query {date} startDate - Filter by start date
 * @query {date} endDate - Filter by end date
 * @query {string} paymentMethod - Filter by payment method
 * @query {number} page - Page number (default: 1)
 * @query {number} limit - Items per page (default: 20)
 * @query {string} sortBy - Sort field (default: 'date')
 * @query {string} sortOrder - 'asc' or 'desc' (default: 'desc')
 * @returns {object} Paginated transactions with category details
 */
const getTransactions = asyncHandler(async (req, res) => {
  const {
    search,
    type,
    category,
    startDate,
    endDate,
    paymentMethod,
    page = 1,
    limit = 20,
    sortBy = 'date',
    sortOrder = 'desc',
  } = req.query;

  // Build query filter
  const query = { userId: req.user.id };

  // Search by description or notes
  if (search) {
    query.$or = [
      { description: { $regex: search, $options: 'i' } },
      { notes: { $regex: search, $options: 'i' } },
    ];
  }

  // Filter by transaction type
  if (type) {
    query.type = type;
  }

  // Filter by category
  if (category) {
    query.category = category;
  }

  // Filter by date range
  if (startDate || endDate) {
    query.date = {};
    if (startDate) {
      // Parse the date and get start of day in UTC
      const start = new Date(startDate);
      // Create a new date using only year, month, day in UTC
      const utcStart = new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate(), 0, 0, 0, 0));
      query.date.$gte = utcStart;
    }
    if (endDate) {
      // Parse the date and get end of day in UTC
      const end = new Date(endDate);
      // Create a new date using only year, month, day in UTC, set to end of day
      const utcEnd = new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), end.getUTCDate(), 23, 59, 59, 999));
      query.date.$lte = utcEnd;
    }
  }

  // Filter by payment method
  if (paymentMethod) {
    query.paymentMethod = paymentMethod;
  }

  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

  // Execute query with pagination and get total count
  const [transactions, total] = await Promise.all([
    Transaction.find(query)
      .populate('category', 'name icon color type')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .lean(),
    Transaction.countDocuments(query),
  ]);

  res.status(200).json({
    status: 'success',
    data: {
      transactions,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    },
  });
});

/**
 * Get single transaction by ID
 * @route GET /api/transactions/:id
 * @access Private
 * @param {string} id - Transaction ID (MongoDB ObjectId)
 * @returns {object} Transaction with populated category
 */
const getTransactionById = asyncHandler(async (req, res) => {
  // Find transaction that belongs to authenticated user
  const transaction = await Transaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  }).populate('category', 'name icon color type');

  if (!transaction) {
    throw new AppError('Transaction not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: {
      transaction,
    },
  });
});

/**
 * Update transaction
 * @route PUT /api/transactions/:id
 * @access Private
 * @param {string} id - Transaction ID (MongoDB ObjectId)
 * @param {object} body - Fields to update (same as create)
 * @returns {object} Updated transaction with populated category
 */
const updateTransaction = asyncHandler(async (req, res) => {
  // Find transaction that belongs to authenticated user
  const transaction = await Transaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!transaction) {
    throw new AppError('Transaction not found', 404);
  }

  const {
    amount,
    type,
    category,
    description,
    date,
    paymentMethod,
    bankAccountId,
    tags,
    location,
    notes,
  } = req.body;

  // If updating category, verify it exists and type matches
  if (category) {
    const categoryDoc = await Category.findOne({
      _id: category,
      userId: req.user.id,
    });

    if (!categoryDoc) {
      throw new AppError('Category not found or does not belong to you', 404);
    }

    const transactionType = type || transaction.type;
    if (categoryDoc.type !== transactionType) {
      throw new AppError(`Category type (${categoryDoc.type}) does not match transaction type (${transactionType})`, 400);
    }
  }

  // Update fields if provided
  if (amount !== undefined) transaction.amount = amount;
  if (type) transaction.type = type;
  if (category) transaction.category = category;
  if (description !== undefined) transaction.description = description;
  if (date) transaction.date = date;
  if (paymentMethod) transaction.paymentMethod = paymentMethod;
  if (bankAccountId !== undefined) transaction.bankAccountId = bankAccountId;
  if (tags) transaction.tags = tags;
  if (location) transaction.location = location;
  if (notes !== undefined) transaction.notes = notes;

  // Save updated transaction
  await transaction.save();

  // Fetch updated transaction with populated category
  const updatedTransaction = await Transaction.findById(transaction._id)
    .populate('category', 'name icon color type');

  res.status(200).json({
    status: 'success',
    message: 'Transaction updated successfully',
    data: {
      transaction: updatedTransaction,
    },
  });
});

/**
 * Delete transaction
 * @route DELETE /api/transactions/:id
 * @access Private
 * @param {string} id - Transaction ID (MongoDB ObjectId)
 * @returns {object} Success message
 */
const deleteTransaction = asyncHandler(async (req, res) => {
  // Find transaction that belongs to authenticated user
  const transaction = await Transaction.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!transaction) {
    throw new AppError('Transaction not found', 404);
  }

  // Delete the transaction
  await transaction.deleteOne();

  res.status(200).json({
    status: 'success',
    message: 'Transaction deleted successfully',
  });
});

/**
 * Get transaction summary (income, expense, balance)
 * @route GET /api/transactions/summary
 * @access Private
 * @query {date} startDate - Start date for summary (required)
 * @query {date} endDate - End date for summary (required)
 * @returns {object} Summary with income, expense, balance, and transaction count
 * @description Uses MongoDB aggregation pipeline (defined in Transaction model)
 */
const getTransactionSummary = asyncHandler(async (req, res) => {
  const { startDate, endDate } = req.query;

  // Validate date range
  if (!startDate || !endDate) {
    throw new AppError('Start date and end date are required', 400);
  }

  // Call static method on Transaction model for aggregation
  const summary = await Transaction.getSummary(
    req.user.id,
    new Date(startDate),
    new Date(endDate)
  );

  res.status(200).json({
    status: 'success',
    data: {
      summary,
    },
  });
});

/**
 * Get spending breakdown by category
 * @route GET /api/transactions/spending-by-category
 * @access Private
 * @query {date} startDate - Start date for analysis (required)
 * @query {date} endDate - End date for analysis (required)
 * @returns {object} Array of categories with total spent and count
 * @description Uses MongoDB aggregation pipeline with $group and $lookup
 */
const getSpendingByCategory = asyncHandler(async (req, res) => {
  const { startDate, endDate } = req.query;

  // Validate date range
  if (!startDate || !endDate) {
    throw new AppError('Start date and end date are required', 400);
  }

  // Call static method on Transaction model for category breakdown
  const spending = await Transaction.getSpendingByCategory(
    req.user.id,
    new Date(startDate),
    new Date(endDate)
  );

  res.status(200).json({
    status: 'success',
    data: {
      spending,
    },
  });
});

/**
 * Helper function to update budgets after transaction
 * @param {string} userId
 * @param {string} categoryId
 */
async function updateBudgetsAfterTransaction(userId, categoryId) {
  try {
    const Budget = require('../models/Budget');
    
    console.log('Checking budgets for userId:', userId, 'categoryId:', categoryId);
    
    // Find all active budgets that include this category
    const budgets = await Budget.find({
      userId,
      isActive: true,
      categories: categoryId
    });

    console.log(`Found ${budgets.length} active budgets with this category`);

    // Update spent amount and check alerts for each budget
    for (const budget of budgets) {
      console.log(`Updating budget: ${budget.name}`);
      await budget.updateSpent();
      await checkBudgetAlert(budget);
    }
  } catch (error) {
    console.error('Error updating budgets after transaction:', error);
  }
}

/**
 * Helper function to format currency
 * @param {number} amount
 * @returns {string}
 */
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount);
}

/**
 * Export transactions to CSV
 * @route GET /api/transactions/export
 * @access Private
 * @query {string} type - Filter by type ('income' or 'expense')
 * @query {string} category - Filter by category ID
 * @query {date} startDate - Filter by start date
 * @query {date} endDate - Filter by end date
 * @query {string} search - Search in description and notes
 * @returns {text/csv} CSV file with transactions
 */
const exportTransactionsToCSV = asyncHandler(async (req, res) => {
  const { type, category, startDate, endDate, search } = req.query;
  const userId = req.user.id.toString();

  // Build query (same as getTransactions)
  const query = { userId };

  if (type) {
    query.type = type;
  }

  if (category) {
    query.category = category;
  }

  if (startDate || endDate) {
    query.date = {};
    if (startDate) {
      query.date.$gte = new Date(startDate);
    }
    if (endDate) {
      const endOfDay = new Date(endDate);
      endOfDay.setHours(23, 59, 59, 999);
      query.date.$lte = endOfDay;
    }
  }

  if (search) {
    query.$or = [
      { description: { $regex: search, $options: 'i' } },
      { notes: { $regex: search, $options: 'i' } },
    ];
  }

  // Fetch all transactions (no pagination for export)
  const transactions = await Transaction.find(query)
    .populate('category', 'name icon')
    .sort({ date: -1 });

  logger.info(`Exporting ${transactions.length} transactions for user ${userId}`);

  // Generate CSV content
  const csvHeader = 'Date,Type,Category,Description,Amount,Payment Method,Notes\n';
  
  const csvRows = transactions.map(t => {
    const date = t.date.toISOString().split('T')[0]; // YYYY-MM-DD
    const type = t.type.charAt(0).toUpperCase() + t.type.slice(1); // Capitalize
    const category = t.category ? t.category.name : 'Uncategorized';
    const description = (t.description || '').replace(/"/g, '""'); // Escape quotes
    const amount = t.amount.toFixed(2);
    const paymentMethod = t.paymentMethod || '';
    const notes = (t.notes || '').replace(/"/g, '""'); // Escape quotes
    
    return `"${date}","${type}","${category}","${description}","${amount}","${paymentMethod}","${notes}"`;
  }).join('\n');

  const csv = csvHeader + csvRows;

  // Set headers for CSV download
  const filename = `transactions_${new Date().toISOString().split('T')[0]}.csv`;
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  
  res.status(200).send(csv);
});

module.exports = {
  createTransaction,
  getTransactions,
  getTransactionById,
  updateTransaction,
  deleteTransaction,
  getTransactionSummary,
  getSpendingByCategory,
  exportTransactionsToCSV,
};
