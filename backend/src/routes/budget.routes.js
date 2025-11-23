const express = require('express');
const {
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
} = require('../controllers/budgetController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// All budget routes require authentication
router.use(authenticate);

// Budget CRUD operations
router.post('/', createBudget);
router.get('/', getBudgets);
router.get('/active', getActiveBudgets);
router.get('/status', getBudgetStatus);
router.get('/:id', getBudgetById);
router.put('/:id', updateBudget);
router.delete('/:id', deleteBudget);
router.delete('/:id/permanent', deleteBudgetPermanently);

// Budget refresh operations
router.post('/:id/refresh', refreshBudget);
router.post('/refresh-all', refreshAllBudgets);

module.exports = router;
