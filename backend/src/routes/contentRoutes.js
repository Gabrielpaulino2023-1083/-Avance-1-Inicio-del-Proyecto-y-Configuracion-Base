const express = require('express');
const c = require('../controllers/contentController');
const { verifyToken, requirePermission } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { contentBodyDto, contentStatusDto } = require('../dtos/content.dto.js');

const router = express.Router();
const read = requirePermission('content:read');
const write = requirePermission('content:write');

router.use(verifyToken);

// Módulos
router.get('/modulos', read, c.listModules);
router.post('/modulos', write, validate(contentBodyDto), c.createModule);
router.put('/modulos/:id', write, validate(contentBodyDto), c.updateModule);
router.patch('/modulos/:id/estado', write, validate(contentStatusDto), c.changeModuleStatus);
router.delete('/modulos/:id', write, c.deleteModule);

// Temas
router.get('/modulos/:id/temas', read, c.listTopics);
router.post('/modulos/:id/temas', write, validate(contentBodyDto), c.createTopic);
router.put('/temas/:id', write, validate(contentBodyDto), c.updateTopic);
router.patch('/temas/:id/estado', write, validate(contentStatusDto), c.changeTopicStatus);
router.delete('/temas/:id', write, c.deleteTopic);

module.exports = router;