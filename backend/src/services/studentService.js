const AppError = require('../errors/AppError');
const { ROLES } = require('../config/roles');
const userModel = require('../models/userModel');
const studentModel = require('../models/studentModel');
const { toStudentSummaryResponse, toProgressResponse } = require('../dtos/student.dto');
const { runEngine } = require('./engineClient');
const { toRecommendationResponse } = require('../dtos/recommendation.dto');

// TODO: reemplazar con datos reales cuando existan las tablas
// temas, interacciones, recomendaciones, contenidos y evaluaciones.
const SIMULATED_METRICS = Object.freeze({
  porcentajeCompletado: 72,
  modulosFinalizados: 18,
  modulosPendientes: 7,
  actividadesPendientes: 8,
  notaPromedio: 86,
  horasEstudio: 32
});

// TODO: reemplazar con datos reales y con la recomendación del motor adaptativo.
const SIMULATED_PROGRESS = Object.freeze({
  variaciones: {
    porcentajeSemanal: 5,
    cursosMes: 1,
    actividadesSemana: -2,
    notaPuntos: 3,
    horasSemana: 6
  },
  recomendacion: {
    tema: 'SQL JOIN',
    accion: 'reinforce_topic',
    dificultad: 'reduced',
    prioridad: 'alta',
    descripcion:
      'Se recomienda reforzar el tema SQL JOIN con explicaciones y ejercicios guiados.',
    motivo: { puntuacionPromedio: 53.3, erroresAcumulados: 9, intentosPromedio: 3.0 }
  }
});

// Verifica que el id exista, esté activo y sea un estudiante
const getStudentOrFail = async (id) => {
  const user = await userModel.findById(id);
  if (!user || !user.activo || user.rol !== ROLES.ESTUDIANTE) {
    throw new AppError(404, 'Estudiante no encontrado');
  }
  return user;
};

const REAL_FIELDS = [
  'id', 'nombre', 'apellido', 'email', 'rol', 'cursosActivos', 'cursos',
  'actividadesPendientes', 'notaPromedio', 'horasEstudio'
];

const getSummary = async (id) => {
  const user = await getStudentOrFail(id);
  const [courses, real] = await Promise.all([
    studentModel.findActiveCourses(id),
    studentModel.findRealMetrics(id)
  ]);

  // Lo simulado se reemplaza campo por campo con lo real
  const metrics = { ...SIMULATED_METRICS, ...real };
  const summary = toStudentSummaryResponse({ user, courses, metrics });

  return { summary, datosReales: REAL_FIELDS };
};

const getProgress = async (id) => {
  await getStudentOrFail(id);
  return toProgressResponse(SIMULATED_PROGRESS);
};

// TODO: reemplazar por interacciones reales (intentos, respuestas) de la base de datos.
const getRecommendation = async (id, topic) => {
  await getStudentOrFail(id);
  const result = await runEngine({ student_id: id, topic, interactions: [] });
  return toRecommendationResponse(result);
};

module.exports = { getSummary, getProgress, getRecommendation };