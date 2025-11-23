const express = require('express');
const {
  createTransaction,
  getTransactions,
  getTransactionById,
  updateTransaction,
  deleteTransaction,
  getTransactionSummary,
  getSpendingByCategory,
} = require('../controllers/transactionController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.post('/', createTransaction);
router.get('/', getTransactions);
router.get('/summary', getTransactionSummary);
router.get('/spending-by-category', getSpendingByCategory);
router.get('/:id', getTransactionById);
router.put('/:id', updateTransaction);
router.delete('/:id', deleteTransaction);

module.exports = router;
