const express = require('express');
const c = require('../controllers/studentLearningController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');
const { ROLES } = require('../config/roles');

const router = express.Router();
const student = [verifyToken, requireRole(ROLES.ESTUDIANTE)];

router.get('/mis-cursos', student, c.listEnrollments);
router.get('/mis-cursos/:cursoId/modulos', student, c.listModules);
router.get('/mis-modulos/:moduloId/temas', student, c.listTopics);
router.get('/mis-inscripciones/:inscripcionId/resultados', student, c.listResults);
router.get('/mis-inscripciones/:inscripcionId/progreso', student, c.listProgress);
router.get('/mis-inscripciones/:inscripcionId/actividad-reciente', student, c.listRecentActivity);
router.get('/mis-inscripciones/:inscripcionId/minutos', student, c.listMinutes);
module.exports = router;