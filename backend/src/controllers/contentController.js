const AppError = require('../errors/AppError');
const service = require('../services/contentService');

const parseId = (value, label) => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0 || id > 2147483647) {
    throw new AppError(400, `Id de ${label} inválido`);
  }
  return id;
};

const ok = (res, data, status = 200) => res.status(status).json({ success: true, data });
const actor = (req) => req.user.id;

// Módulos
const listModules = async (req, res) => {
  const cursoId = req.query.cursoId ? parseId(req.query.cursoId, 'curso') : undefined;
  ok(res, await service.listModules(actor(req), cursoId));
};
const createModule = async (req, res) => ok(res, await service.createModule(actor(req), req.body), 201);
const updateModule = async (req, res) =>
  ok(res, await service.updateModule(actor(req), parseId(req.params.id, 'módulo'), req.body));
const changeModuleStatus = async (req, res) =>
  ok(res, await service.changeModuleStatus(actor(req), parseId(req.params.id, 'módulo'), req.body.estado));
const deleteModule = async (req, res) =>
  ok(res, await service.deleteModule(actor(req), parseId(req.params.id, 'módulo')));

// Temas
const listTopics = async (req, res) =>
  ok(res, await service.listTopics(actor(req), parseId(req.params.id, 'módulo')));
const createTopic = async (req, res) =>
  ok(res, await service.createTopic(actor(req), parseId(req.params.id, 'módulo'), req.body), 201);
const updateTopic = async (req, res) =>
  ok(res, await service.updateTopic(actor(req), parseId(req.params.id, 'tema'), req.body));
const changeTopicStatus = async (req, res) =>
  ok(res, await service.changeTopicStatus(actor(req), parseId(req.params.id, 'tema'), req.body.estado));
const deleteTopic = async (req, res) =>
  ok(res, await service.deleteTopic(actor(req), parseId(req.params.id, 'tema')));

module.exports = {
  listModules, createModule, updateModule, changeModuleStatus, deleteModule,
  listTopics, createTopic, updateTopic, changeTopicStatus, deleteTopic
};