const express = require('express');
const c = require('../controllers/studentLearningController');
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { selectionBodyDto } = require('../dtos/studentAttempt.dto');
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
router.get('/mis-inscripciones/:inscripcionId/temas/:temaId/actividades', student, c.listActivities);
router.post('/mis-inscripciones/:inscripcionId/actividades/:actividadId/intentos', student, c.startAttempt);
router.get('/mis-intentos/:intentoId/cuestionario', student, c.getQuestionnaire);
router.put('/mis-respuestas/:respuestaId/opciones', student, validate(selectionBodyDto), c.saveSelection);
router.post('/mis-intentos/:intentoId/entrega', student, c.submitAttempt);
module.exports = router;