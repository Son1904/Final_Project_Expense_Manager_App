/**
 * Budget Controller
 * Handles CRUD operations for user budgets
 * Manages budget creation, tracking spending, alerts, and recurring budgets
 * Uses MongoDB for budget data storage
 */

const { Budget, Transaction } = require('../models');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const { createNotification } = require('./notificationController');
const { isNotificationEnabled } = require('./settingsController');

/**
 * Create a new budget
 * @route POST /api/budgets
 * @access Private
 * @body {string} name - Budget name (required)
 * @body {number} amount - Budget limit amount (required)
 * @body {string} period - 'daily', 'weekly', 'monthly', 'yearly', 'custom' (required)
 * @body {Date} startDate - Budget start date (required)
 * @body {Date} endDate - Budget end date (required)
 * @body {Array<string>} categories - Array of category IDs (optional)
 * @body {number} alertThreshold - Alert threshold percentage 0-100 (optional, default: 80)
 * @body {boolean} alertEnabled - Enable/disable alerts (optional, default: true)
 * @body {boolean} repeatAutomatically - Auto-create next period budget (optional, default: false)
 * @returns {object} Created budget with calculated fields
 */
const createBudget = asyncHandler(async (req, res) => {
  const {
    name,
    amount,
    period,
    startDate,
    endDate,
    categories,
    alertThreshold,
    alertEnabled,
    repeatAutomatically,
  } = req.body;

  // Validate required fields
  if (!name || !amount || !period || !startDate || !endDate) {
    throw new AppError('Name, amount, period, startDate, and endDate are required', 400);
  }

  // Validate amount
  if (amount <= 0) {
    throw new AppError('Budget amount must be greater than 0', 400);
  }

  // Validate dates
  const start = new Date(startDate);
  const end = new Date(endDate);
  if (end <= start) {
    throw new AppError('End date must be after start date', 400);
  }

  // Validate period
  const validPeriods = ['daily', 'weekly', 'monthly', 'yearly', 'custom'];
  if (!validPeriods.includes(period)) {
    throw new AppError('Invalid period. Must be one of: daily, weekly, monthly, yearly, custom', 400);
  }

  // Create budget
  const budget = await Budget.create({
    userId: req.user.id,
    name: name.trim(),
    amount,
    period,
    startDate: start,
    endDate: end,
    categories: categories || [],
    alertThreshold: alertThreshold || 80,
    alertEnabled: alertEnabled !== undefined ? alertEnabled : true,
    repeatAutomatically: repeatAutomatically || false,
  });

  // Calculate initial spent amount
  await budget.updateSpent();

  // Populate categories
  await budget.populate('categories', 'name icon color');

  // Check if budget needs alert after creation
  await checkBudgetAlert(budget);

  res.status(201).json({
    status: 'success',
    message: 'Budget created successfully',
    data: {
      budget,
    },
  });
});

/**
 * Get all budgets for authenticated user
 * @route GET /api/budgets
 * @access Private
 * @query {string} period - Filter by period (optional)
 * @query {boolean} active - Filter by active status (optional)
 * @query {string} category - Filter by category ID (optional)
 * @returns {object} Array of budgets with calculated fields
 */
const getBudgets = asyncHandler(async (req, res) => {
  const { period, active, category } = req.query;

  // Build query - default to active budgets only
  const query = { 
    userId: req.user.id,
    isActive: true, // Only show active budgets by default
  };

  if (period) {
    query.period = period;
  }

  // Allow explicit filter for inactive budgets
  if (active !== undefined) {
    query.isActive = active === 'true';
  }

  if (category) {
    query.categories = category;
  }

  // Get budgets
  const budgets = await Budget.find(query)
    .populate('categories', 'name icon color')
    .sort({ startDate: -1 });

  res.status(200).json({
    status: 'success',
    data: {
      budgets,
    },
  });
});

/**
 * Get active budgets for authenticated user
 * @route GET /api/budgets/active
 * @access Private
 * @returns {object} Array of currently active budgets
 */
const getActiveBudgets = asyncHandler(async (req, res) => {
  const budgets = await Budget.getActiveBudgets(req.user.id);

  res.status(200).json({
    status: 'success',
    data: {
      budgets,
    },
  });
});

/**
 * Get budget status summary
 * @route GET /api/budgets/status
 * @access Private
 * @returns {object} Summary of all active budgets with status (ok/warning/exceeded)
 */
const getBudgetStatus = asyncHandler(async (req, res) => {
  const budgets = await Budget.getActiveBudgets(req.user.id);

  // Update spent for all budgets
  await Promise.all(budgets.map((budget) => budget.updateSpent()));

  // Categorize by status
  const status = {
    ok: [],
    warning: [],
    exceeded: [],
  };

  budgets.forEach((budget) => {
    const budgetObj = budget.toJSON();
    status[budgetObj.status].push(budgetObj);
  });

  res.status(200).json({
    status: 'success',
    data: {
      summary: {
        total: budgets.length,
        ok: status.ok.length,
        warning: status.warning.length,
        exceeded: status.exceeded.length,
      },
      budgets: status,
    },
  });
});

/**
 * Get single budget by ID
 * @route GET /api/budgets/:id
 * @access Private
 * @param {string} id - Budget ID
 * @returns {object} Budget details with calculated fields
 */
const getBudgetById = asyncHandler(async (req, res) => {
  const budget = await Budget.findOne({
    _id: req.params.id,
    userId: req.user.id,
  }).populate('categories', 'name icon color');

  if (!budget) {
    throw new AppError('Budget not found', 404);
  }

  // Update spent amount
  await budget.updateSpent();

  res.status(200).json({
    status: 'success',
    data: {
      budget,
    },
  });
});

/**
 * Update budget
 * @route PUT /api/budgets/:id
 * @access Private
 * @param {string} id - Budget ID
 * @body {string} name - Budget name (optional)
 * @body {number} amount - Budget amount (optional)
 * @body {string} period - Budget period (optional)
 * @body {Date} startDate - Start date (optional)
 * @body {Date} endDate - End date (optional)
 * @body {Array<string>} categories - Category IDs (optional)
 * @body {number} alertThreshold - Alert threshold (optional)
 * @body {boolean} alertEnabled - Alert enabled (optional)
 * @body {boolean} repeatAutomatically - Repeat automatically (optional)
 * @body {boolean} isActive - Active status (optional)
 * @returns {object} Updated budget
 */
const updateBudget = asyncHandler(async (req, res) => {
  const budget = await Budget.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!budget) {
    throw new AppError('Budget not found', 404);
  }

  const {
    name,
    amount,
    period,
    startDate,
    endDate,
    categories,
    alertThreshold,
    alertEnabled,
    repeatAutomatically,
    isActive,
  } = req.body;

  // Update fields if provided
  if (name !== undefined) budget.name = name.trim();
  if (amount !== undefined) {
    if (amount <= 0) {
      throw new AppError('Budget amount must be greater than 0', 400);
    }
    budget.amount = amount;
  }
  if (period !== undefined) {
    const validPeriods = ['daily', 'weekly', 'monthly', 'yearly', 'custom'];
    if (!validPeriods.includes(period)) {
      throw new AppError('Invalid period', 400);
    }
    budget.period = period;
  }
  if (startDate !== undefined) budget.startDate = new Date(startDate);
  if (endDate !== undefined) budget.endDate = new Date(endDate);
  if (categories !== undefined) budget.categories = categories;
  if (alertThreshold !== undefined) {
    if (alertThreshold < 0 || alertThreshold > 100) {
      throw new AppError('Alert threshold must be between 0 and 100', 400);
    }
    budget.alertThreshold = alertThreshold;
  }
  if (alertEnabled !== undefined) budget.alertEnabled = alertEnabled;
  if (repeatAutomatically !== undefined) budget.repeatAutomatically = repeatAutomatically;
  if (isActive !== undefined) budget.isActive = isActive;

  // Validate dates if both are present
  if (budget.endDate <= budget.startDate) {
    throw new AppError('End date must be after start date', 400);
  }

  await budget.save();

  // Update spent amount
  await budget.updateSpent();

  // Populate categories
  await budget.populate('categories', 'name icon color');

  res.status(200).json({
    status: 'success',
    message: 'Budget updated successfully',
    data: {
      budget,
    },
  });
});

/**
 * Delete budget
 * @route DELETE /api/budgets/:id
 * @access Private
 * @param {string} id - Budget ID
 * @returns {object} Success message
 */
const deleteBudget = asyncHandler(async (req, res) => {
  const budget = await Budget.findOneAndDelete({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!budget) {
    throw new AppError('Budget not found', 404);
  }

  res.status(200).json({
    status: 'success',
    message: 'Budget deleted successfully',
    data: null,
  });
});

/**
 * Permanently delete budget
 * @route DELETE /api/budgets/:id/permanent
 * @access Private
 * @param {string} id - Budget ID
 * @returns {object} Success message
 */
const deleteBudgetPermanently = asyncHandler(async (req, res) => {
  const budget = await Budget.findOneAndDelete({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!budget) {
    throw new AppError('Budget not found', 404);
  }

  res.status(200).json({
    status: 'success',
    message: 'Budget permanently deleted',
    data: null,
  });
});

/**
 * Refresh spent amount for a budget
 * @route POST /api/budgets/:id/refresh
 * @access Private
 * @param {string} id - Budget ID
 * @returns {object} Updated budget with recalculated spent amount
 */
const refreshBudget = asyncHandler(async (req, res) => {
  const budget = await Budget.findOne({
    _id: req.params.id,
    userId: req.user.id,
  }).populate('categories', 'name icon color');

  if (!budget) {
    throw new AppError('Budget not found', 404);
  }

  await budget.updateSpent();

  res.status(200).json({
    status: 'success',
    message: 'Budget refreshed successfully',
    data: {
      budget,
    },
  });
});

/**
 * Refresh spent amounts for all active budgets
 * @route POST /api/budgets/refresh-all
 * @access Private
 * @returns {object} Count of refreshed budgets
 */
const refreshAllBudgets = asyncHandler(async (req, res) => {
  const budgets = await Budget.getActiveBudgets(req.user.id);

  await Promise.all(budgets.map((budget) => budget.updateSpent()));

  res.status(200).json({
    status: 'success',
    message: `Refreshed ${budgets.length} budgets`,
    data: {
      count: budgets.length,
    },
  });
});

/**
 * Helper function to check budget alert and create notification
 * @param {Object} budget - Budget object
 */
async function checkBudgetAlert(budget) {
  if (!budget.alertEnabled) return;

  const percentageUsed = (budget.spent / budget.amount) * 100;
  const userId = budget.userId.toString();

  console.log(`Checking alert for budget ${budget.name}: ${percentageUsed.toFixed(1)}% used`);

  try {
    // Budget exceeded (100%+)
    if (percentageUsed >= 100) {
      const overAmount = budget.spent - budget.amount;
      const isEnabled = await isNotificationEnabled(userId, 'BUDGET_EXCEEDED');
      if (isEnabled) {
        await createNotification(userId, {
          type: 'BUDGET_EXCEEDED',
          title: `${budget.name} budget exceeded`,
          message: `You've exceeded your ${budget.name} budget by ${formatCurrency(overAmount)}`,
          priority: 'HIGH',
          referenceType: 'BUDGET',
          referenceId: budget._id.toString(),
          metadata: {
            budgetName: budget.name,
            budgetAmount: budget.amount,
            spent: budget.spent,
            overAmount: overAmount,
            percentageUsed: percentageUsed.toFixed(1)
          }
        });
        console.log('Created BUDGET_EXCEEDED notification');
      } else {
        console.log('ℹBUDGET_EXCEEDED notification skipped (disabled by user)');
      }
    }
    // Budget warning (80%+)
    else if (percentageUsed >= budget.alertThreshold) {
      const isEnabled = await isNotificationEnabled(userId, 'BUDGET_WARNING');
      if (isEnabled) {
        await createNotification(userId, {
          type: 'BUDGET_WARNING',
          title: `${budget.name} budget warning`,
          message: `You've used ${percentageUsed.toFixed(0)}% of your ${budget.name} budget (${formatCurrency(budget.spent)}/${formatCurrency(budget.amount)})`,
          priority: 'MEDIUM',
          referenceType: 'BUDGET',
          referenceId: budget._id.toString(),
          metadata: {
            budgetName: budget.name,
            budgetAmount: budget.amount,
            spent: budget.spent,
            percentageUsed: percentageUsed.toFixed(1),
            alertThreshold: budget.alertThreshold
          }
        });
        console.log('Created BUDGET_WARNING notification');
      } else {
        console.log('ℹBUDGET_WARNING notification skipped (disabled by user)');
      }
    }
    // Budget on track (<50%)
    else if (percentageUsed < 50) {
      const isEnabled = await isNotificationEnabled(userId, 'BUDGET_ON_TRACK');
      if (isEnabled) {
        await createNotification(userId, {
          type: 'BUDGET_ON_TRACK',
          title: `${budget.name} budget on track`,
          message: `Great job! You've only used ${percentageUsed.toFixed(0)}% of your ${budget.name} budget`,
          priority: 'LOW',
          referenceType: 'BUDGET',
          referenceId: budget._id.toString(),
          metadata: {
            budgetName: budget.name,
            budgetAmount: budget.amount,
            spent: budget.spent,
            percentageUsed: percentageUsed.toFixed(1)
          }
        });
        console.log('Created BUDGET_ON_TRACK notification');
      } else {
        console.log('ℹBUDGET_ON_TRACK notification skipped (disabled by user)');
      }
    }
  } catch (error) {
    console.error('Error creating budget notification:', error);
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

module.exports = {
  createBudget,
  getBudgets,
  getActiveBudgets,
  getBudgetStatus,
  getBudgetById,
  updateBudget,
  deleteBudget,
  deleteBudgetPermanently,
  refreshBudget,
  refreshAllBudgets,
  checkBudgetAlert,
};
