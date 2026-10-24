const express = require('express');
const { getSummary, getProgress } = require('../controllers/studentController');
const { verifyToken, requirePermission } = require('../middlewares/authMiddleware');
const { canAccessStudent } = require('../middlewares/studentAccess');

const router = express.Router();

router.use(verifyToken);

router.get('/:id', requirePermission('students:read'), canAccessStudent, getSummary);
router.get('/:id/progress', requirePermission('students:read'), canAccessStudent, getProgress);

module.exports = router;