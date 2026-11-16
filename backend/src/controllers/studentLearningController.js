const service = require('../services/studentLearningService');
const { parseId, ok } = require('../errors/helpers');
const AppError = require('../errors/AppError');

const parseDate = (value, label) => {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new AppError(400, `${label} debe tener formato AAAA-MM-DD`);
  }
  return value;
};

const actor = (req) => req.user.id;

const listEnrollments = async (req, res) =>
  ok(res, await service.listEnrollments(actor(req)));

const listModules = async (req, res) =>
  ok(res, await service.listModules(actor(req), parseId(req.params.cursoId, 'curso')));

const listTopics = async (req, res) =>
  ok(res, await service.listTopics(actor(req), parseId(req.params.moduloId, 'módulo')));
const inscripcion = (req) => parseId(req.params.inscripcionId, 'inscripción');

const listResults = async (req, res) =>
  ok(res, await service.listResults(actor(req), inscripcion(req)));

const listProgress = async (req, res) =>
  ok(res, await service.listProgress(actor(req), inscripcion(req)));

const listRecentActivity = async (req, res) => {
  const limite = req.query.limite === undefined ? 10 : Number(req.query.limite);
  if (!Number.isInteger(limite) || limite < 1 || limite > 100) {
    throw new AppError(400, 'El límite debe estar entre 1 y 100');
  }
  ok(res, await service.listRecentActivity(actor(req), inscripcion(req), limite));
};

const listMinutes = async (req, res) => {
  const desde = parseDate(req.query.desde, 'desde');
  const hasta = parseDate(req.query.hasta, 'hasta');
  ok(res, await service.listMinutes(actor(req), inscripcion(req), desde, hasta));
};

const listActivities = async (req, res) =>
  ok(res, await service.listActivities(actor(req), inscripcion(req), parseId(req.params.temaId, 'tema')));

const getQuestionnaire = async (req, res) =>
  ok(res, await service.getQuestionnaire(actor(req), parseId(req.params.intentoId, 'intento')));

const startAttempt = async (req, res) =>
  ok(res, await service.startAttempt(actor(req), inscripcion(req), parseId(req.params.actividadId, 'actividad')), 201);

const saveSelection = async (req, res) =>
  ok(res, await service.saveSelection(
    actor(req), parseId(req.params.respuestaId, 'respuesta'), req.body.opciones));

const submitAttempt = async (req, res) =>
  ok(res, await service.submitAttempt(actor(req), parseId(req.params.intentoId, 'intento')));

const getRecommendation = async (req, res) =>
  ok(res, await service.getRecommendation(
    actor(req), inscripcion(req), parseId(req.params.temaId, 'tema')));

module.exports = {
  listEnrollments, listModules, listTopics,
  listResults, listProgress, listRecentActivity, listMinutes,
  listActivities, getQuestionnaire, startAttempt, saveSelection,
  submitAttempt, getRecommendation
};