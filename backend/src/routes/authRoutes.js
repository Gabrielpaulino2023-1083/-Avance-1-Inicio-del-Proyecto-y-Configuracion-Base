const express = require('express');
const { register, login, me } = require('../controllers/authController');
const { verifyToken } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { registerDto, loginDto } = require('../dtos/auth.dto');

const router = express.Router();

router.post('/register', validate(registerDto), register);
router.post('/login', validate(loginDto), login);
router.get('/me', verifyToken, me);

module.exports = router;