/**
 * Admin Middleware
 * Simple role-based access control for admin-only routes
 */

const { AppError } = require('./error.middleware');

/**
 * Require admin role middleware
 * Must be used after auth.middleware (authenticate)
 */
const requireAdmin = (req, res, next) => {
    // Check if user is authenticated
    if (!req.user) {
        return next(new AppError('Authentication required', 401));
    }

    // Check if user has admin role
    if (req.user.role !== 'admin') {
        return next(new AppError('Admin access required', 403));
    }

    // User is admin, proceed
    next();
};

module.exports = {
    requireAdmin,
};
