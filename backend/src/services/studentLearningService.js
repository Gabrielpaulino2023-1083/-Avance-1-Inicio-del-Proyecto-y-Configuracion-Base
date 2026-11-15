const model = require('../models/studentLearningModel');
const { run } = require('../errors/helpers');
const { toModuleResponse, toTopicResponse } = require('../dtos/content.dto');
const { toActivityResponse, toQuestionnaireResponse, toAttemptResultResponse } = require('../dtos/studentAttempt.dto');
const AppError = require('../errors/AppError');
const { runEngine } = require('./engineClient');
const { toEngineInteraction, toRecommendationResult } = require('../dtos/studentRecommendation.dto');
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
const listActivities = (actor, inscripcionId, temaId) =>
  run(async () => (await model.listActivities(actor, inscripcionId, temaId)).map(toActivityResponse));

const getQuestionnaire = (actor, intentoId) =>
  run(async () => toQuestionnaireResponse(await model.getQuestionnaire(actor, intentoId)));

const startAttempt = (actor, inscripcionId, actividadId) =>
  run(async () => toQuestionnaireResponse(await model.startAttempt(actor, inscripcionId, actividadId)));

const saveSelection = (actor, respuestaId, opciones) =>
  run(async () => {
    await model.saveSelection(actor, respuestaId, opciones);
    return { respuestaId, opcionesSeleccionadas: opciones };
  });

const submitAttempt = (actor, intentoId) =>
  run(async () => toAttemptResultResponse(await model.submitAttempt(actor, intentoId)));

const getRecommendation = async (actor, inscripcionId, temaId) => {
  // La base valida que la inscripción sea del estudiante autenticado.
  const rows = await run(() => model.listEngineInteractions(actor, inscripcionId, temaId));
  if (rows.length === 0) {
    throw new AppError(404, 'Aún no tienes intentos calificados en este tema');
  }
  const interactions = rows.map(toEngineInteraction);
  const engine = await runEngine({ student_id: actor, topic: rows[0].tema, interactions });
  return toRecommendationResult(engine, interactions, inscripcionId, temaId);
};

module.exports = {
  listEnrollments, listModules, listTopics,
  listResults, listRecentActivity, listProgress, listMinutes,
  getQuestionnaire, listActivities, startAttempt, saveSelection,
  submitAttempt, getRecommendation

};