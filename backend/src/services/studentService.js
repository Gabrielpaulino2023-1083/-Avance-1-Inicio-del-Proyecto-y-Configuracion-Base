const AppError = require('../errors/AppError');
const { ROLES } = require('../config/roles');
const userModel = require('../models/userModel');
const studentModel = require('../models/studentModel');
const { toStudentSummaryResponse, toProgressResponse } = require('../dtos/student.dto');

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

const getSummary = async (id) => {
  const user = await getStudentOrFail(id);
  const courses = await studentModel.findActiveCourses(id);
  return toStudentSummaryResponse({ user, courses, metrics: SIMULATED_METRICS });
};

const getProgress = async (id) => {
  await getStudentOrFail(id);
  return toProgressResponse(SIMULATED_PROGRESS);
};

module.exports = { getSummary, getProgress };