/**
 * Category Controller
 * Handles CRUD operations for transaction categories
 * Categories can be default (system-created) or custom (user-created)
 * Uses MongoDB for category data storage
 */

const { Category } = require('../models');
const { AppError, asyncHandler } = require('../middleware/error.middleware');

/**
 * Create a new category
 * @route POST /api/categories
 * @access Private
 * @param {string} name - Category name (required)
 * @param {string} type - 'income' or 'expense' (required)
 * @param {string} icon - Icon name (optional, default: 'default')
 * @param {string} color - Hex color code (optional, default: '#3498db')
 * @returns {object} Created category
 */
const createCategory = asyncHandler(async (req, res) => {
  const { name, type, icon, color } = req.body;

  // Validate required fields
  if (!name || !type) {
    throw new AppError('Name and type are required', 400);
  }

  // Validate category type
  if (type !== 'income' && type !== 'expense') {
    throw new AppError('Type must be either income or expense', 400);
  }

  // Check for duplicate category name for this user and type
  const existingCategory = await Category.findOne({
    userId: req.user.id,
    name: name.trim(),
    type,
  });

  if (existingCategory) {
    throw new AppError('Category with this name and type already exists', 400);
  }

  // Create new custom category (isDefault: false)
  const category = await Category.create({
    userId: req.user.id,
    name: name.trim(),
    type,
    icon: icon || 'default',
    color: color || '#3498db',
  });

  res.status(201).json({
    status: 'success',
    message: 'Category created successfully',
    data: {
      category,
    },
  });
});

/**
 * Get all categories for authenticated user
 * @route GET /api/categories
 * @access Private
 * @query {string} type - Filter by 'income' or 'expense' (optional)
 * @returns {object} Array of categories (includes default + custom)
 * @description Uses static method from Category model
 */
const getCategories = asyncHandler(async (req, res) => {
  const { type } = req.query;

  // Call static method to get user's categories (default + custom)
  const categories = await Category.getByUser(req.user.id, type || null);

  res.status(200).json({
    status: 'success',
    data: {
      categories,
    },
  });
});

/**
 * Get single category by ID
 * @route GET /api/categories/:id
 * @access Private
 * @param {string} id - Category ID (MongoDB ObjectId)
 * @returns {object} Category details
 */
const getCategoryById = asyncHandler(async (req, res) => {
  // Find category that belongs to authenticated user
  const category = await Category.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: {
      category,
    },
  });
});

/**
 * Update category
 * @route PUT /api/categories/:id
 * @access Private
 * @param {string} id - Category ID (MongoDB ObjectId)
 * @param {string} name - New category name (optional)
 * @param {string} icon - New icon (optional)
 * @param {string} color - New color (optional)
 * @param {boolean} isActive - Active status (optional)
 * @returns {object} Updated category
 * @description Default categories cannot be edited
 */
const updateCategory = asyncHandler(async (req, res) => {
  // Find category that belongs to authenticated user
  const category = await Category.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  // Prevent editing default categories (system-created)
  if (category.isDefault) {
    throw new AppError('Cannot edit default categories', 403);
  }

  const { name, icon, color, isActive } = req.body;

  // If updating name, check for duplicates
  if (name && name.trim() !== category.name) {
    const existingCategory = await Category.findOne({
      userId: req.user.id,
      name: name.trim(),
      type: category.type,
      _id: { $ne: category._id },
    });

    if (existingCategory) {
      throw new AppError('Category with this name and type already exists', 400);
    }
    category.name = name.trim();
  }

  // Update fields if provided
  if (icon) category.icon = icon;
  if (color) category.color = color;
  if (isActive !== undefined) category.isActive = isActive;

  // Save updated category
  await category.save();

  res.status(200).json({
    status: 'success',
    message: 'Category updated successfully',
    data: {
      category,
    },
  });
});

/**
 * Delete category
 * @route DELETE /api/categories/:id
 * @access Private
 * @param {string} id - Category ID (MongoDB ObjectId)
 * @returns {object} Success message
 * @description Default categories and categories with transactions cannot be deleted
 */
const deleteCategory = asyncHandler(async (req, res) => {
  // Find category that belongs to authenticated user
  const category = await Category.findOne({
    _id: req.params.id,
    userId: req.user.id,
  });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  // Prevent deleting default categories (system-created)
  if (category.isDefault) {
    throw new AppError('Cannot delete default categories', 403);
  }

  // Check if category has any transactions (uses instance method)
  const canDelete = await category.canDelete();
  if (!canDelete) {
    throw new AppError('Cannot delete category with existing transactions', 400);
  }

  // Delete the category
  await category.deleteOne();

  res.status(200).json({
    status: 'success',
    message: 'Category deleted successfully',
  });
});

module.exports = {
  createCategory,
  getCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
};
