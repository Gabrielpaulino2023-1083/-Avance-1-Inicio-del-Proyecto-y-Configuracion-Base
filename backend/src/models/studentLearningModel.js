const pool = require('../config/db');

const q = async (sql, params) => (await pool.query(sql, params)).rows;

const listEnrollments = (actor) =>
  q('SELECT * FROM public.listar_inscripciones_estudiante($1)', [actor]);

const listPublishedModules = (actor, cursoId) =>
  q('SELECT * FROM public.listar_modulos_publicados_estudiante($1,$2)', [actor, cursoId]);

const listPublishedTopics = (actor, moduloId) =>
  q('SELECT * FROM public.listar_temas_publicados_estudiante($1,$2)', [actor, moduloId]);

module.exports = { listEnrollments, listPublishedModules, listPublishedTopics };