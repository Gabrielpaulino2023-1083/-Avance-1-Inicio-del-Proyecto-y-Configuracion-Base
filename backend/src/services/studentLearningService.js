const model = require('../models/studentLearningModel');
const { run } = require('../errors/helpers');
const { toModuleResponse, toTopicResponse } = require('../dtos/content.dto');

const toEnrollmentResponse = (r) => ({
  inscripcionId: r.inscripcion_id,
  cursoId: r.curso_id,
  codigo: r.codigo,
  curso: r.curso,
  edicionId: r.edicion_id,
  seccionId: r.seccion_id,
  seccion: r.seccion
});

const listEnrollments = (actor) =>
  run(async () => (await model.listEnrollments(actor)).map(toEnrollmentResponse));

const listModules = (actor, cursoId) =>
  run(async () => (await model.listPublishedModules(actor, cursoId)).map(toModuleResponse));

const listTopics = (actor, moduloId) =>
  run(async () => (await model.listPublishedTopics(actor, moduloId)).map(toTopicResponse));

module.exports = { listEnrollments, listModules, listTopics };