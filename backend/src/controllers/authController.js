/**
 * Authentication Controller
 * Handles user registration, login, logout, token refresh, and profile management
 * Uses PostgreSQL for user data and MongoDB for categories
 */

const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { getPgPool } = require('../config/database');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const logger = require('../utils/logger');
const { Category, Transaction, Budget, Notification } = require('../models');

/**
 * Register a new user
 * @route POST /api/auth/register
 * @access Public
 * @param {string} email - User email (required)
 * @param {string} password - User password (required, min 6 chars)
 * @param {string} fullName - User full name (required)
 * @param {string} phone - User phone number (optional)
 * @returns {object} User data, access token, and refresh token
 */
const register = asyncHandler(async (req, res) => {
  const { email, password, fullName, phone } = req.body;

  // Validate required fields
  if (!email || !password || !fullName) {
    throw new AppError('Email, password, and full name are required', 400);
  }

  // Validate password length
  if (password.length < 6) {
    throw new AppError('Password must be at least 6 characters', 400);
  }

  const pool = getPgPool();

  // Check if email already exists
  const existingUser = await pool.query(
    'SELECT id FROM users WHERE email = $1',
    [email.toLowerCase()]
  );

  if (existingUser.rows.length > 0) {
    throw new AppError('Email already registered', 400);
  }

  // Hash password using bcrypt
  const hashedPassword = await bcrypt.hash(password, 10);

  // Generate unique UUID for user
  const userId = uuidv4();

  // Insert new user into PostgreSQL
  const result = await pool.query(
    `INSERT INTO users (id, email, password_hash, full_name, phone, is_active, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
     RETURNING id, email, full_name, phone, is_active, created_at`,
    [userId, email.toLowerCase(), hashedPassword, fullName, phone || null, true]
  );

  const user = result.rows[0];

  // Create 13 default categories in MongoDB for the new user
  try {
    await Category.createDefaultCategories(userId);
    logger.info(`Default categories created for user ${userId}`);
  } catch (error) {
    logger.error('Error creating default categories:', error);
  }

  // Generate JWT tokens
  const accessToken = generateAccessToken(userId);
  const refreshToken = generateRefreshToken(userId);

  // Calculate refresh token expiration (7 days from now)
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  // Store refresh token in PostgreSQL
  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token, expires_at, created_at)
     VALUES ($1, $2, $3, NOW())`,
    [userId, refreshToken, expiresAt]
  );

  // Return user data and tokens
  res.status(201).json({
    status: 'success',
    message: 'Registration successful',
    data: {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        phone: user.phone,
      },
      accessToken,
      refreshToken,
    },
  });
});

/**
 * Login user
 * @route POST /api/auth/login
 * @access Public
 * @param {string} email - User email (required)
 * @param {string} password - User password (required)
 * @returns {object} User data, access token, and refresh token
 */
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  // Validate required fields
  if (!email || !password) {
    throw new AppError('Email and password are required', 400);
  }

  const pool = getPgPool();

  // Find user by email
  const result = await pool.query(
    'SELECT id, email, password_hash, full_name, phone, is_active, role, is_banned, ban_reason FROM users WHERE email = $1',
    [email.toLowerCase()]
  );

  if (result.rows.length === 0) {
    throw new AppError('Invalid email or password', 401);
  }

  const user = result.rows[0];

  // Check if account is active
  if (!user.is_active) {
    throw new AppError('Account is deactivated. Please contact support.', 403);
  }

  // Check if account is banned
  if (user.is_banned) {
    throw new AppError(`Account suspended. Reason: ${user.ban_reason || 'Violation of terms'}`, 403);
  }

  // Verify password using bcrypt
  const isPasswordValid = await bcrypt.compare(password, user.password_hash);

  if (!isPasswordValid) {
    throw new AppError('Invalid email or password', 401);
  }

  // Update last login timestamp
  await pool.query(
    'UPDATE users SET last_login_at = NOW() WHERE id = $1',
    [user.id]
  );

  // Generate new JWT tokens
  const accessToken = generateAccessToken(user.id);
  const refreshToken = generateRefreshToken(user.id);

  // Calculate refresh token expiration (7 days from now)
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  // Store refresh token in database
  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token, expires_at, created_at)
     VALUES ($1, $2, $3, NOW())`,
    [user.id, refreshToken, expiresAt]
  );

  // Return user data and tokens
  res.status(200).json({
    status: 'success',
    message: 'Login successful',
    data: {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        phone: user.phone,
        role: user.role,
      },
      accessToken,
      refreshToken,
    },
  });
});

/**
 * Refresh access token using refresh token
 * @route POST /api/auth/refresh
 * @access Public
 * @param {string} refreshToken - Valid refresh token (required)
 * @returns {object} New access token
 * @description When access token expires (15 min), client can use refresh token
 *              to get a new access token without re-login (refresh token valid for 7 days)
 */
const refreshAccessToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  // Validate refresh token presence
  if (!refreshToken) {
    throw new AppError('Refresh token is required', 400);
  }

  // Verify refresh token JWT signature and expiration
  const decoded = verifyRefreshToken(refreshToken);

  const pool = getPgPool();

  // Check if refresh token exists in database and is valid
  const tokenResult = await pool.query(
    'SELECT * FROM refresh_tokens WHERE token = $1 AND user_id = $2 AND is_revoked = false AND expires_at > NOW()',
    [refreshToken, decoded.userId]
  );

  if (tokenResult.rows.length === 0) {
    throw new AppError('Invalid or expired refresh token', 401);
  }

  // Verify user still exists and is active
  const userResult = await pool.query(
    'SELECT id, email, full_name, is_active FROM users WHERE id = $1',
    [decoded.userId]
  );

  if (userResult.rows.length === 0 || !userResult.rows[0].is_active) {
    throw new AppError('User not found or inactive', 401);
  }

  // Generate new access token (refresh token remains the same)
  const newAccessToken = generateAccessToken(decoded.userId);

  res.status(200).json({
    status: 'success',
    message: 'Access token refreshed',
    data: {
      accessToken: newAccessToken,
    },
  });
});

/**
 * Logout user
 * @route POST /api/auth/logout
 * @access Private (requires Authorization header)
 * @param {string} refreshToken - Refresh token to revoke (optional in body)
 * @description Revokes the refresh token to prevent future use
 */
const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  // If refresh token provided, revoke it in database
  if (refreshToken) {
    const pool = getPgPool();
    await pool.query(
      'UPDATE refresh_tokens SET is_revoked = true, revoked_at = NOW() WHERE token = $1',
      [refreshToken]
    );
  }

  res.status(200).json({
    status: 'success',
    message: 'Logout successful',
  });
});

/**
 * Get user profile
 * @route GET /api/auth/profile
 * @access Private (requires Authorization header with valid access token)
 * @returns {object} User profile data
 * @description Returns detailed user information for the authenticated user
 */
const getProfile = asyncHandler(async (req, res) => {
  const pool = getPgPool();

  // req.user is set by authenticate middleware
  const result = await pool.query(
    'SELECT id, email, full_name, phone, avatar_url, email_verified, phone_verified, created_at FROM users WHERE id = $1',
    [req.user.id]
  );

  if (result.rows.length === 0) {
    throw new AppError('User not found', 404);
  }

  const user = result.rows[0];

  res.status(200).json({
    status: 'success',
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      emailVerified: user.email_verified,
      phoneVerified: user.phone_verified,
      createdAt: user.created_at,
    },
  });
});

/**
 * Change user password
 * @route PUT /api/auth/change-password
 * @access Private
 * @param {string} currentPassword - Current password (required)
 * @param {string} newPassword - New password (required, min 6 chars)
 * @returns {object} Success message
 */
const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user.id;

  console.log('Change password request:', { userId, hasCurrentPwd: !!currentPassword, hasNewPwd: !!newPassword });

  // Validate required fields
  if (!currentPassword || !newPassword) {
    throw new AppError('Current password and new password are required', 400);
  }

  // Validate new password length
  if (newPassword.length < 6) {
    throw new AppError('New password must be at least 6 characters', 400);
  }

  // Check if new password is same as current
  if (currentPassword === newPassword) {
    throw new AppError('New password must be different from current password', 400);
  }

  try {
    const pool = getPgPool();

    // Get user's current password hash
    const result = await pool.query(
      'SELECT password_hash FROM users WHERE id = $1',
      [userId]
    );

    console.log('User query result:', { found: result.rows.length > 0 });

    if (result.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    const user = result.rows[0];

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
    console.log('Password validation:', { isValid: isPasswordValid });

    if (!isPasswordValid) {
      throw new AppError('Current password is incorrect', 401);
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password in database
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [hashedPassword, userId]
    );

    logger.info(`User ${userId} changed password`);

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    throw error;
  }
});

/**
 * Update user profile (full name)
 * @route PUT /api/auth/profile
 * @access Private
 * @param {string} fullName - New full name (required)
 * @returns {object} Updated user data
 */
const updateProfile = asyncHandler(async (req, res) => {
  const { fullName } = req.body;
  const userId = req.user.id;

  if (!fullName || fullName.trim().length === 0) {
    throw new AppError('Full name is required', 400);
  }

  const pool = getPgPool();

  // Update full name
  const result = await pool.query(
    'UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2 RETURNING id, email, full_name, phone, created_at',
    [fullName.trim(), userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('User not found', 404);
  }

  const user = result.rows[0];

  logger.info(`User ${userId} updated profile`);

  res.json({
    success: true,
    message: 'Profile updated successfully',
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      phone: user.phone,
      createdAt: user.created_at,
    },
  });
});

/**
 * Clear all user data (transactions, budgets, notifications)
 * @route DELETE /api/auth/clear-data
 * @access Private
 * @returns {object} Success message
 */
const clearUserData = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  // Clear MongoDB data
  await Promise.all([
    Transaction.deleteMany({ userId: userId.toString() }),
    Budget.deleteMany({ userId: userId.toString() }),
    Notification.deleteMany({ userId: userId.toString() }),
    Category.deleteMany({ userId: userId.toString(), isDefault: false }), // Keep default categories
  ]);

  logger.info(`User ${userId} cleared all data`);

  res.json({
    success: true,
    message: 'All data cleared successfully',
  });
});

/**
 * Delete user account permanently
 * @route DELETE /api/auth/account
 * @access Private
 * @returns {object} Success message
 */
const deleteAccount = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  // Delete MongoDB data first
  await Promise.all([
    Transaction.deleteMany({ userId: userId.toString() }),
    Budget.deleteMany({ userId: userId.toString() }),
    Notification.deleteMany({ userId: userId.toString() }),
    Category.deleteMany({ userId: userId.toString() }),
  ]);

  // Delete from PostgreSQL (cascades to refresh_tokens and user_notification_preferences)
  const pool = getPgPool();
  await pool.query('DELETE FROM users WHERE id = $1', [userId]);

  logger.info(`User ${userId} deleted account`);

  res.json({
    success: true,
    message: 'Account deleted successfully',
  });
});

module.exports = {
  register,
  login,
  refreshAccessToken,
  logout,
  getProfile,
  changePassword,
  updateProfile,
  clearUserData,
  deleteAccount,
};
