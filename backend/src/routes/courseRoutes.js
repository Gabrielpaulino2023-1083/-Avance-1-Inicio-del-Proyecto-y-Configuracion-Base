const express = require('express');
const controller = require('../controllers/courseController');
const { verifyToken, requirePermission } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { courseBodyDto, courseStatusDto } = require('../dtos/course.dto');

const router = express.Router();

router.use(verifyToken, requirePermission('courses:manage'));

router.post('/', validate(courseBodyDto), controller.create);
router.get('/', controller.list);
router.get('/:id', controller.getById);
router.put('/:id', validate(courseBodyDto), controller.update);
router.patch('/:id/estado', validate(courseStatusDto), controller.changeStatus);

module.exports = router;