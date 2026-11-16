const express = require('express');
const { getSummary, getProgress, getRecommendation } = require('../controllers/studentController');
const { verifyToken, requirePermission } = require('../middlewares/authMiddleware');
const { canAccessStudent } = require('../middlewares/studentAccess');
const validate = require('../middlewares/validate');
const { recommendationDto } = require('../dtos/recommendation.dto');

const router = express.Router();

router.use(verifyToken);

router.get('/:id', requirePermission('students:read'), canAccessStudent, getSummary);
router.get('/:id/progress', requirePermission('students:read'), canAccessStudent, getProgress);
router.post(
  '/:id/recommendation',
  requirePermission('students:read'),
  canAccessStudent,
  validate(recommendationDto),
  getRecommendation
);

module.exports = router;