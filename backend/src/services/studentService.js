const AppError = require('../errors/AppError');
const { ROLES } = require('../config/roles');
const userModel = require('../models/userModel');
const studentModel = require('../models/studentModel');
const learningModel = require('../models/studentLearningModel');
const learningService = require('./studentLearningService');
const { toStudentSummaryResponse, toProgressResponse } = require('../dtos/student.dto');
const { runEngineSafe } = require('./engineSafe');
const { toRecommendationResponse } = require('../dtos/recommendation.dto');

const TIME_ZONE = 'America/Santo_Domingo';

// Verifica que el id exista, esté activo y sea un estudiante
const getStudentOrFail = async (id) => {
  const user = await userModel.findById(id);
  if (!user || !user.activo || user.rol !== ROLES.ESTUDIANTE) {
    throw new AppError(404, 'Estudiante no encontrado');
  }
  return user;
};

const round1 = (n) => Math.round(n * 10) / 10;

// ---------- Resumen ----------

const REAL_FIELDS = [
  'id', 'nombre', 'apellido', 'email', 'rol', 'cursosActivos', 'cursos',
  'porcentajeCompletado', 'modulosFinalizados', 'modulosPendientes',
  'actividadesPendientes', 'notaPromedio', 'horasEstudio'
];

// Progreso real: promedio del progreso por tema (solo temas con actividades)
// y módulos finalizados (todos sus temas completados) o pendientes.
const computeProgressMetrics = async (studentId, courses) => {
  const porInscripcion = await Promise.all(
    courses.map((c) => learningModel.listProgress(studentId, c.inscripcionId))
  );

  const porcentajes = [];
  const modulos = new Map();
  porInscripcion.forEach((rows, i) => {
    for (const r of rows) {
      if (r.progreso_porcentaje !== null) porcentajes.push(Number(r.progreso_porcentaje));
      const key = `${courses[i].inscripcionId}-${r.modulo_id}`;
      const completo = modulos.get(key) ?? true;
      modulos.set(key, completo && r.completado === true);
    }
  });

  const finalizados = [...modulos.values()].filter(Boolean).length;
  return {
    porcentajeCompletado: porcentajes.length
      ? round1(porcentajes.reduce((s, x) => s + x, 0) / porcentajes.length)
      : 0,
    modulosFinalizados: finalizados,
    modulosPendientes: modulos.size - finalizados
  };
};

const getSummary = async (id) => {
  const user = await getStudentOrFail(id);
  const [courses, real] = await Promise.all([
    studentModel.findActiveCourses(id),
    studentModel.findRealMetrics(id)
  ]);
  const progress = await computeProgressMetrics(id, courses);

  const metrics = { ...real, ...progress };
  const summary = toStudentSummaryResponse({ user, courses, metrics });

  return { summary, datosReales: REAL_FIELDS };
};

// ---------- Progreso (variaciones y recomendación) ----------

// Fecha local (AAAA-MM-DD) de un instante, en la zona horaria de la plataforma.
const localDay = (date) => new Date(date).toLocaleDateString('en-CA', { timeZone: TIME_ZONE });

const addDays = (day, n) => {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
};

const avg = (xs) => (xs.length ? xs.reduce((s, x) => s + x, 0) / xs.length : null);

// Compara los últimos 7 días (incluido hoy) con los 7 anteriores.
// Si no hay datos en ninguna de las dos semanas, el valor es null (no 0).
const computeVariations = async (studentId, courses) => {
  const hoy = localDay(new Date());
  const inicioActual = addDays(hoy, -6);
  const inicioPrevia = addDays(hoy, -13);
  const hastaExclusiva = addDays(hoy, 1);

  const [minutosPorInsc, actividadPorInsc] = await Promise.all([
    Promise.all(courses.map((c) =>
      learningModel.listMinutes(studentId, c.inscripcionId, inicioPrevia, hastaExclusiva))),
    Promise.all(courses.map((c) =>
      learningModel.listRecentActivity(studentId, c.inscripcionId, 100)))
  ]);

  const semana = { actual: { min: 0, intentos: 0, notas: [] }, previa: { min: 0, intentos: 0, notas: [] } };
  for (const rows of minutosPorInsc) {
    for (const r of rows) {
      const w = r.dia_local >= inicioActual ? semana.actual : semana.previa;
      w.min += Number(r.minutos_transcurridos);
      w.intentos += Number(r.intentos_entregados);
    }
  }
  for (const rows of actividadPorInsc) {
    for (const r of rows) {
      if (r.puntaje_porcentaje === null) continue;
      const dia = localDay(r.ocurrido_en);
      if (dia >= inicioActual) semana.actual.notas.push(Number(r.puntaje_porcentaje));
      else if (dia >= inicioPrevia) semana.previa.notas.push(Number(r.puntaje_porcentaje));
    }
  }

  const sinDatos = semana.actual.intentos === 0 && semana.previa.intentos === 0;
  const notaActual = avg(semana.actual.notas);
  const notaPrevia = avg(semana.previa.notas);

  const hace30 = Date.now() - 30 * 24 * 60 * 60 * 1000;
  return {
    porcentajeSemanal: null, // la base no guarda el historial del progreso
    cursosMes: courses.filter((c) => new Date(c.inscritoEn).getTime() >= hace30).length,
    actividadesSemana: sinDatos ? null : semana.actual.intentos - semana.previa.intentos,
    notaPuntos: notaActual === null || notaPrevia === null ? null : round1(notaActual - notaPrevia),
    horasSemana: sinDatos ? null : round1((semana.actual.min - semana.previa.min) / 60)
  };
};

// Tema más débil: menor promedio entre los temas con intentos calificados.
const findWeakestTopic = async (studentId, courses) => {
  const resultadosPorInsc = await Promise.all(
    courses.map((c) => learningModel.listResults(studentId, c.inscripcionId))
  );

  const temas = new Map();
  resultadosPorInsc.forEach((rows, i) => {
    for (const r of rows) {
      if (r.promedio_porcentaje === null) continue;
      const key = `${courses[i].inscripcionId}-${r.tema_id}`;
      const t = temas.get(key) ?? { inscripcionId: courses[i].inscripcionId, temaId: r.tema_id, valores: [] };
      t.valores.push(Number(r.promedio_porcentaje));
      temas.set(key, t);
    }
  });

  let peor = null;
  for (const t of temas.values()) {
    const promedio = avg(t.valores);
    if (peor === null || promedio < peor.promedio) peor = { ...t, promedio };
  }
  return peor;
};

// La prioridad no la devuelve el motor: se deriva de la acción.
const PRIORIDAD = Object.freeze({
  reinforce_topic: 'alta',
  maintain_difficulty: 'media',
  increase_difficulty: 'baja'
});

const computeRecommendation = async (studentId, courses) => {
  const weakest = await findWeakestTopic(studentId, courses);
  if (!weakest) return null;

  try {
    const rec = await learningService.getRecommendation(studentId, weakest.inscripcionId, weakest.temaId);
    return {
      inscripcionId: rec.inscripcionId,
      temaId: rec.temaId,
      tema: rec.tema,
      accion: rec.accion,
      dificultad: rec.dificultad,
      prioridad: PRIORIDAD[rec.accion] ?? null,
      descripcion: rec.recomendacion,
      motivo: {
        puntuacionPromedio: rec.mastery,
        erroresAcumulados: rec.errors,
        intentosPromedio: rec.attempts
      }
    };
  } catch (err) {
    // Si el motor falla, el resto del progreso se sigue entregando.
    console.error('No se pudo calcular la recomendación del progreso:', err.message);
    return null;
  }
};

const getProgress = async (id) => {
  await getStudentOrFail(id);
  const courses = await studentModel.findActiveCourses(id);
  const [variaciones, recomendacion] = await Promise.all([
    computeVariations(id, courses),
    computeRecommendation(id, courses)
  ]);
  return toProgressResponse({ variaciones, recomendacion });
};

// ---------- Recomendación por nombre de tema (ruta antigua) ----------

const getRecommendation = async (id, topic) => {
  await getStudentOrFail(id);
  const interactions = await studentModel.findInteractionsByTopic(id, topic);
  if (interactions.length === 0) {
    throw new AppError(404, 'El estudiante no tiene intentos calificados en ese tema');
  }
  const result = await runEngineSafe({ student_id: id, topic, interactions });

  const n = interactions.length;
  const evidence = {
    mastery: Math.round((interactions.reduce((s, x) => s + x.score_percentage, 0) / n) * 10) / 10,
    errors: interactions.reduce((s, x) => s + x.errors, 0),
    attempts: Math.round((interactions.reduce((s, x) => s + x.attempts, 0) / n) * 10) / 10
  };
  return { ...toRecommendationResponse(result), ...evidence };
};

module.exports = { getSummary, getProgress, getRecommendation };