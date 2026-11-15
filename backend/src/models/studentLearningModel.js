const pool = require('../config/db');

const q = async (sql, params) => (await pool.query(sql, params)).rows;

const listEnrollments = (actor) =>
  q('SELECT * FROM public.listar_inscripciones_estudiante($1)', [actor]);

const listPublishedModules = (actor, cursoId) =>
  q('SELECT * FROM public.listar_modulos_publicados_estudiante($1,$2)', [actor, cursoId]);

const listPublishedTopics = (actor, moduloId) =>
  q('SELECT * FROM public.listar_temas_publicados_estudiante($1,$2)', [actor, moduloId]);

const listActivities = (actor, inscripcionId, temaId) =>
  q('SELECT * FROM public.listar_actividades_publicadas_estudiante($1,$2,$3)',
    [actor, inscripcionId, temaId]);

const getQuestionnaire = (actor, intentoId) =>
  q('SELECT * FROM public.obtener_cuestionario_estudiante($1,$2)', [actor, intentoId]);

// Inicia el intento y lee el cuestionario en la misma transacción.
const startAttempt = async (actor, inscripcionId, actividadId) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'SELECT public.iniciar_intento($1,$2,$3) AS intento_id',
      [actividadId, inscripcionId, actor]);
    const { rows: preguntas } = await client.query(
      'SELECT * FROM public.obtener_cuestionario_estudiante($1,$2)',
      [actor, rows[0].intento_id]);
    await client.query('COMMIT');
    return preguntas;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const saveSelection = (actor, respuestaId, opciones) =>
  q('SELECT public.guardar_opciones_respuesta($1,$2,$3::INTEGER[])', [respuestaId, actor, opciones]);

// Entrega y califica en una sola transacción. Solo se califica después de que
// entregar_intento verificó que el intento pertenece al estudiante autenticado.
const submitAttempt = async (actor, intentoId) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: entregado } = await client.query(
      'SELECT * FROM public.entregar_intento($1,$2)', [intentoId, actor]);
    let intento = entregado[0];
    if (intento.estado === 'ENTREGADO') {
      const { rows: calificado } = await client.query(
        'SELECT * FROM public.calificar_intento($1)', [intentoId]);
      intento = calificado[0];
    }
    await client.query('COMMIT');
    return intento;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};
module.exports = { 
    listEnrollments, listPublishedModules, 
    listPublishedTopics, listActivities, getQuestionnaire, startAttempt,
    saveSelection, submitAttempt };