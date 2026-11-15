const service = require('../services/studentLearningService');
const { parseId, ok } = require('../errors/helpers');

const actor = (req) => req.user.id;

const listEnrollments = async (req, res) =>
  ok(res, await service.listEnrollments(actor(req)));

const listModules = async (req, res) =>
  ok(res, await service.listModules(actor(req), parseId(req.params.cursoId, 'curso')));

const listTopics = async (req, res) =>
  ok(res, await service.listTopics(actor(req), parseId(req.params.moduloId, 'módulo')));

module.exports = { listEnrollments, listModules, listTopics };