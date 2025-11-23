/**
 * Transaction Controller
 * Handles CRUD operations for transactions and analytics
 * Uses MongoDB for transaction data storage
 */

const { Transaction, Category } = require('../models');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const logger = require('../utils/logger');

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
      query.date.$gte = new Date(startDate);
    }
    if (endDate) {
      query.date.$lte = new Date(endDate);
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

module.exports = {
  createTransaction,
  getTransactions,
  getTransactionById,
  updateTransaction,
  deleteTransaction,
  getTransactionSummary,
  getSpendingByCategory,
};
