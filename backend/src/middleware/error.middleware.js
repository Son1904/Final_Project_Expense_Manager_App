/**
 * Error Handling Middleware
 * Centralized error handling for the application
 * Handles MongoDB errors, JWT errors, and custom application errors
 */

const logger = require('../utils/logger');

/**
 * Custom error class for application errors
 * @class AppError
 * @extends Error
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code
 * @description Used to create operational errors that are safe to send to clients
 */
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true; // Marks error as safe to send to client

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Async handler wrapper to catch errors in async functions
 * @function asyncHandler
 * @param {Function} fn - Async controller function
 * @returns {Function} Express middleware function
 * @description Wraps async controller functions to catch errors and pass to error middleware
 * @example
 * const getUser = asyncHandler(async (req, res) => {
 *   const user = await User.findById(req.params.id);
 *   res.json(user);
 * });
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Handle MongoDB CastError (invalid ObjectId)
 * @param {Error} err - MongoDB CastError
 * @returns {AppError} Formatted error for client
 */
const handleCastErrorDB = (err) => {
  const message = `Invalid ${err.path}: ${err.value}`;
  return new AppError(message, 400);
};

/**
 * Handle MongoDB duplicate key error (E11000)
 * @param {Error} err - MongoDB duplicate key error
 * @returns {AppError} Formatted error for client
 */
const handleDuplicateFieldsDB = (err) => {
  const value = err.message.match(/(["'])(\\?.)*?\1/)[0];
  const message = `Duplicate field value: ${value}. Please use another value`;
  return new AppError(message, 400);
};

/**
 * Handle MongoDB validation error
 * @param {Error} err - MongoDB validation error
 * @returns {AppError} Formatted error for client
 */
const handleValidationErrorDB = (err) => {
  const errors = Object.values(err.errors).map(el => el.message);
  const message = `Invalid input data. ${errors.join('. ')}`;
  return new AppError(message, 400);
};

/**
 * Handle JWT invalid signature error
 * @returns {AppError} Formatted error for client
 */
const handleJWTError = () => {
  return new AppError('Invalid token. Please log in again', 401);
};

/**
 * Handle JWT expired error
 * @returns {AppError} Formatted error for client
 */
const handleJWTExpiredError = () => {
  return new AppError('Your token has expired. Please log in again', 401);
};

/**
 * Send error response in development mode
 * @param {Error} err - Error object
 * @param {Response} res - Express response object
 * @description Sends detailed error with stack trace for debugging
 */
const sendErrorDev = (err, res) => {
  res.status(err.statusCode).json({
    status: err.status,
    error: err,
    message: err.message,
    stack: err.stack
  });
};

/**
 * Send error response in production mode
 * @param {Error} err - Error object
 * @param {Response} res - Express response object
 * @description Sends minimal error info to client, hides implementation details
 */
const sendErrorProd = (err, res) => {
  // Operational, trusted error: send message to client
  if (err.isOperational) {
    res.status(err.statusCode).json({
      status: err.status,
      message: err.message
    });
  } 
  // Programming or unknown error: don't leak error details
  else {
    logger.error('ERROR:', err);
    res.status(500).json({
      status: 'error',
      message: 'Something went wrong'
    });
  }
};

/**
 * Global error handling middleware
 */
const errorMiddleware = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(err, res);
  } else if (process.env.NODE_ENV === 'production') {
    let error = { ...err };
    error.message = err.message;

    // Handle specific error types
    if (err.name === 'CastError') error = handleCastErrorDB(err);
    if (err.code === 11000) error = handleDuplicateFieldsDB(err);
    if (err.name === 'ValidationError') error = handleValidationErrorDB(err);
    if (err.name === 'JsonWebTokenError') error = handleJWTError();
    if (err.name === 'TokenExpiredError') error = handleJWTExpiredError();

    sendErrorProd(error, res);
  }
};

module.exports = errorMiddleware;
module.exports.AppError = AppError;
module.exports.asyncHandler = asyncHandler;
