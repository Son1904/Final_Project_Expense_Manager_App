const express = require('express');
const {
  register,
  login,
  refreshAccessToken,
  logout,
  getProfile,
  changePassword,
  updateProfile,
  clearUserData,
  deleteAccount,
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refreshAccessToken);
router.post('/logout', logout);
router.get('/profile', authenticate, getProfile);
router.put('/profile', authenticate, updateProfile);
router.put('/change-password', authenticate, changePassword);
router.delete('/clear-data', authenticate, clearUserData);
router.delete('/account', authenticate, deleteAccount);

module.exports = router;
