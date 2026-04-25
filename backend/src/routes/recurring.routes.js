const express = require('express');
const {
  createRecurring,
  getRecurringTransactions,
  getUpcoming,
  getRecurringById,
  updateRecurring,
  toggleRecurring,
  deleteRecurring,
} = require('../controllers/recurringController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// All recurring routes require authentication
router.use(authenticate);

// CRUD operations
router.post('/', createRecurring);
router.get('/', getRecurringTransactions);
router.get('/upcoming', getUpcoming);
router.get('/:id', getRecurringById);
router.put('/:id', updateRecurring);
router.patch('/:id/toggle', toggleRecurring);
router.delete('/:id', deleteRecurring);

module.exports = router;
