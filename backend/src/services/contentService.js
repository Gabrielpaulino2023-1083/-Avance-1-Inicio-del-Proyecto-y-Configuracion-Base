const AppError = require('../errors/AppError');
const model = require('../models/contentModel');
const { toModuleResponse, toTopicResponse } = require('../dtos/content.dto.js');

const DEFAULT_CURSO_ID = 1; // el frontend actual trabaja con un solo curso

// Traduce los SQLSTATE de las funciones a errores HTTP.
const mapDbError = (err, entidad) => {
  switch (err.code) {
    case '42501': throw new AppError(403, 'No tienes permiso para administrar este contenido');
    case '22023': throw new AppError(400, 'Datos inválidos');
    case 'P0002': throw new AppError(404, err.message || 'El recurso no existe');
    case '23505': throw new AppError(409, `Ya existe un ${entidad} con ese orden`);
    case '55000': throw new AppError(409, err.message || 'La operación no es válida en el estado actual');
    case '23503': throw new AppError(404, 'El curso o módulo indicado no existe');
    default: throw err;
  }
};

const run = async (entidad, fn) => {
  try { return await fn(); } catch (err) { return mapDbError(err, entidad); }
};

// ---- Módulos ----
const listModules = (actor, cursoId) =>
  run('módulo', async () =>
    (await model.listModules(actor, cursoId || DEFAULT_CURSO_ID)).map(toModuleResponse));

const createModule = (actor, d) =>
  run('módulo', async () => toModuleResponse(
    await model.createModule(actor, d.cursoId || DEFAULT_CURSO_ID, { ...d, estado: d.estado || 'BORRADOR' })));

const updateModule = (actor, id, d) =>
  run('módulo', async () => {
    const estado = d.estado || (await model.getModule(actor, id)).estado;
    return toModuleResponse(await model.updateModule(actor, id, { ...d, estado }));
  });

const changeModuleStatus = (actor, id, estado) =>
  run('módulo', async () => toModuleResponse(await model.changeModuleStatus(actor, id, estado)));

const deleteModule = (actor, id) =>
  run('módulo', async () => { await model.deleteModule(actor, id); return { id }; });

// ---- Temas ----
const listTopics = (actor, moduloId) =>
  run('tema', async () => (await model.listTopics(actor, moduloId)).map(toTopicResponse));

const createTopic = (actor, moduloId, d) =>
  run('tema', async () => toTopicResponse(
    await model.createTopic(actor, moduloId, { ...d, estado: d.estado || 'BORRADOR' })));

const updateTopic = (actor, id, d) =>
  run('tema', async () => {
    const estado = d.estado || (await model.getTopic(actor, id)).estado;
    return toTopicResponse(await model.updateTopic(actor, id, { ...d, estado }));
  });

const changeTopicStatus = (actor, id, estado) =>
  run('tema', async () => toTopicResponse(await model.changeTopicStatus(actor, id, estado)));

const deleteTopic = (actor, id) =>
  run('tema', async () => { await model.deleteTopic(actor, id); return { id }; });

module.exports = {
  listModules, createModule, updateModule, changeModuleStatus, deleteModule,
  listTopics, createTopic, updateTopic, changeTopicStatus, deleteTopic
};