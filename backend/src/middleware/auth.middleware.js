/**
 * Authentication Middleware
 * Verifies JWT access tokens and attaches user to request object
 * Protects routes that require authentication
 */

const { verifyAccessToken } = require('../utils/jwt');
const { AppError, asyncHandler } = require('./error.middleware');
const { getPgPool } = require('../config/database');

/**
 * Authenticate middleware - Requires valid access token
 * @middleware
 * @description Extracts JWT from Authorization header (Bearer token),
 *              verifies the token, fetches user from database,
 *              and attaches user to req.user for use in controllers
 * @throws {AppError} 401 if token missing, invalid, or user not found
 * @throws {AppError} 403 if user account is deactivated
 */
const authenticate = asyncHandler(async (req, res, next) => {
  let token;

  // Extract token from Authorization header (format: "Bearer <token>")
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Check if token exists
  if (!token) {
    throw new AppError('Authentication required. Please log in.', 401);
  }

  // Verify JWT token and get payload (throws error if invalid/expired)
  const decoded = verifyAccessToken(token);

  // Fetch user from database
  const pool = getPgPool();
  const result = await pool.query(
    'SELECT id, email, full_name, is_active, role, is_banned, ban_reason FROM users WHERE id = $1',
    [decoded.userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('User not found or has been deleted', 401);
  }

  const user = result.rows[0];

  // Check if account is banned
  if (user.is_banned) {
    throw new AppError(`Account suspended. Reason: ${user.ban_reason || 'Violation of terms'}`, 403);
  }

  // Check if account is active
  if (!user.is_active) {
    throw new AppError('Account is deactivated. Please contact support.', 403);
  }

  // Attach user to request object for use in controllers
  req.user = user;
  next();
});

/**
 * Optional authentication middleware
 * @middleware
 * @description Attempts to authenticate user from Authorization header,
 *              but continues execution even if token is missing or invalid.
 *              Useful for routes that work with or without authentication.
 *              If token is valid, user is attached to req.user, otherwise req.user is undefined
 * @example Used for public routes that show different content for logged-in users
 */
const optionalAuth = asyncHandler(async (req, res, next) => {
  let token;

  // Extract token from Authorization header if present
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // If token exists, try to authenticate
  if (token) {
    try {
      const decoded = verifyAccessToken(token);
      const pool = getPgPool();
      const result = await pool.query(
        'SELECT id, email, full_name, is_active, role FROM users WHERE id = $1 AND is_active = true',
        [decoded.userId]
      );

      // If user found and active, attach to request
      if (result.rows.length > 0) {
        req.user = result.rows[0];
      }
    } catch (error) {
      // Token invalid or expired, continue without user (no error thrown)
    }
  }

  // Continue to next middleware regardless of authentication status
  next();
});

module.exports = {
  authenticate,
  optionalAuth,
};
