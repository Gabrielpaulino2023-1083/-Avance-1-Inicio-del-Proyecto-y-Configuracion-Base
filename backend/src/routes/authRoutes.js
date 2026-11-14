const express = require('express');
const { register, login, me } = require('../controllers/authController');
const { verifyToken } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { authLimiter } = require('../middlewares/rateLimiters');
const { registerDto, loginDto } = require('../dtos/auth.dto');

const router = express.Router();

router.post('/register', authLimiter, validate(registerDto), register);
router.post('/login', authLimiter, validate(loginDto), login);
router.get('/me', verifyToken, me);

module.exports = router;