const pool = require('../config/db');

const q = async (sql, params) => (await pool.query(sql, params)).rows;

const listEnrollments = (actor) =>
  q('SELECT * FROM public.listar_inscripciones_estudiante($1)', [actor]);

const listPublishedModules = (actor, cursoId) =>
  q('SELECT * FROM public.listar_modulos_publicados_estudiante($1,$2)', [actor, cursoId]);

const listPublishedTopics = (actor, moduloId) =>
  q('SELECT * FROM public.listar_temas_publicados_estudiante($1,$2)', [actor, moduloId]);
const listResults = (actor, inscripcionId) =>
  q('SELECT * FROM public.listar_resultados_estudiante($1,$2)', [actor, inscripcionId]);

const listRecentActivity = (actor, inscripcionId, limite) =>
  q('SELECT * FROM public.listar_actividad_reciente_estudiante($1,$2,$3)', [actor, inscripcionId, limite]);

const listProgress = (actor, inscripcionId) =>
  q('SELECT * FROM public.listar_progreso_estudiante($1,$2)', [actor, inscripcionId]);

const listMinutes = (actor, inscripcionId, desde, hasta) =>
  q(`SELECT to_char(dia_local,'YYYY-MM-DD') AS dia_local, intentos_entregados, minutos_transcurridos
     FROM public.listar_minutos_intentos_estudiante($1,$2,$3::date,$4::date)`,
    [actor, inscripcionId, desde, hasta]);

module.exports = {
  listEnrollments, listPublishedModules, listPublishedTopics,
  listResults, listRecentActivity, listProgress, listMinutes
};