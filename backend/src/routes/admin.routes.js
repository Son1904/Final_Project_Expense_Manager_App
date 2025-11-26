const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/admin.middleware');
const adminController = require('../controllers/adminController');

// All admin routes require authentication AND admin role
router.use(authenticate);
router.use(requireAdmin);

// System statistics
router.get('/stats/overview', adminController.getSystemOverview);

// User management
router.get('/users', adminController.getAllUsers);
router.patch('/users/:id/ban', adminController.toggleBanUser);
router.delete('/users/:id', adminController.deleteUser);

module.exports = router;
