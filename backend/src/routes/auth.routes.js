const express = require('express');
const {
  register,
  login,
  refreshAccessToken,
  logout,
  getProfile,
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refreshAccessToken);
router.post('/logout', logout);
router.get('/profile', authenticate, getProfile);

module.exports = router;
