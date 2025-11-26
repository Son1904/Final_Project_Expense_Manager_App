const { getPgPool } = require('../config/database');
const { AppError } = require('../middleware/error.middleware');
const { Transaction, Budget, Notification, Category } = require('../models');

/**
 * Admin Controller - Minimal
 * Handles admin-only operations: system stats and user management
 */

/**
 * Get system overview statistics
 * @route GET /api/admin/stats/overview
 * @access Admin
 */
exports.getSystemOverview = async (req, res, next) => {
    try {
        const pool = getPgPool();

        // Get user statistics (PostgreSQL)
        const userStats = await pool.query(`
SELECT
COUNT(*) as total_users,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_users,
    COUNT(CASE WHEN created_at >= date_trunc('month', CURRENT_DATE) THEN 1 END) as new_users_this_month
            FROM users
            WHERE role != 'admin'
    `);

        // Get transaction count (MongoDB)
        const totalTransactions = await Transaction.countDocuments();

        // Get budget count (MongoDB)
        const totalBudgets = await Budget.countDocuments();

        res.status(200).json({
            status: 'success',
            data: {
                overview: {
                    total_users: parseInt(userStats.rows[0].total_users),
                    active_users: parseInt(userStats.rows[0].active_users),
                    new_users_this_month: parseInt(userStats.rows[0].new_users_this_month),
                    total_transactions: totalTransactions,
                    total_budgets: totalBudgets,
                },
            },
        });
    } catch (error) {
        console.error('Error in getSystemOverview:', error);
        next(error);
    }
};

/**
 * Get all users with pagination
 * @route GET /api/admin/users
 * @access Admin
 */
exports.getAllUsers = async (req, res, next) => {
    try {
        const { page = 1, limit = 20, search = '' } = req.query;
        const offset = (page - 1) * limit;
        const pool = getPgPool();

        let query = `
SELECT
id, email, full_name, phone, role, is_active,
    is_banned, ban_reason,
    created_at, last_login_at
            FROM users
        `;
        let queryParams = [];
        let paramIndex = 1;

        // Add search filter if provided
        if (search) {
            query += ` WHERE(email ILIKE $${paramIndex} OR full_name ILIKE $${paramIndex})`;
            queryParams.push(`% ${search}% `);
            paramIndex++;
        }

        query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1} `;
        queryParams.push(limit, offset);

        const result = await pool.query(query, queryParams);

        // Get total count
        let countQuery = 'SELECT COUNT(*) FROM users';
        let countParams = [];
        if (search) {
            countQuery += ' WHERE (email ILIKE $1 OR full_name ILIKE $1)';
            countParams.push(`% ${search}% `);
        }
        const countResult = await pool.query(countQuery, countParams);

        res.status(200).json({
            status: 'success',
            data: {
                users: result.rows,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total: parseInt(countResult.rows[0].count),
                },
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Toggle user ban status
 * @route PATCH /api/admin/users/:id/ban
 * @access Admin
 */
exports.toggleBanUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const pool = getPgPool();

        // Check if user exists and get current status
        const userResult = await pool.query('SELECT role, is_banned FROM users WHERE id = $1', [id]);

        if (userResult.rows.length === 0) {
            throw new AppError('User not found', 404);
        }

        const user = userResult.rows[0];

        // Prevent banning other admins
        if (user.role === 'admin') {
            throw new AppError('Cannot ban an admin user', 403);
        }

        const newBanStatus = !user.is_banned;
        const banReason = newBanStatus ? (reason || 'Violation of terms') : null;

        await pool.query(
            'UPDATE users SET is_banned = $1, ban_reason = $2 WHERE id = $3',
            [newBanStatus, banReason, id]
        );

        res.status(200).json({
            status: 'success',
            message: newBanStatus ? 'User banned successfully' : 'User unbanned successfully',
            data: {
                is_banned: newBanStatus,
                ban_reason: banReason
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete user
 * @route DELETE /api/admin/users/:id
 * @access Admin
 */
exports.deleteUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        const pool = getPgPool();

        // Check user role before deleting
        const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [id]);

        if (userResult.rows.length === 0) {
            throw new AppError('User not found', 404);
        }

        if (userResult.rows[0].role === 'admin') {
            throw new AppError('Cannot delete an admin user', 403);
        }

        // 1. Delete related data in MongoDB first (to avoid orphaned data)
        await Promise.all([
            Transaction.deleteMany({ userId: id }),
            Budget.deleteMany({ userId: id }),
            Notification.deleteMany({ userId: id }),
            Category.deleteMany({ userId: id, isDefault: false })
        ]);

        // 2. Delete user from PostgreSQL
        await pool.query('DELETE FROM users WHERE id = $1', [id]);

        res.status(200).json({
            status: 'success',
            message: 'User deleted successfully'
        });
    } catch (error) {
        next(error);
    }
};
