const model = require('../models/studentLearningModel');
const { run } = require('../errors/helpers');
const { toModuleResponse, toTopicResponse } = require('../dtos/content.dto');
const {toResultResponse, toRecentActivityResponse, toProgressResponse, toMinutesResponse
} = require('../dtos/studentDashboard.dto');

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
const listResults = (actor, inscripcionId) =>
  run(async () => (await model.listResults(actor, inscripcionId)).map(toResultResponse));

const listRecentActivity = (actor, inscripcionId, limite) =>
  run(async () => (await model.listRecentActivity(actor, inscripcionId, limite)).map(toRecentActivityResponse));

const listProgress = (actor, inscripcionId) =>
  run(async () => (await model.listProgress(actor, inscripcionId)).map(toProgressResponse));

const listMinutes = (actor, inscripcionId, desde, hasta) =>
  run(async () => (await model.listMinutes(actor, inscripcionId, desde, hasta)).map(toMinutesResponse));

module.exports = {
  listEnrollments, listModules, listTopics,
  listResults, listRecentActivity, listProgress, listMinutes
};