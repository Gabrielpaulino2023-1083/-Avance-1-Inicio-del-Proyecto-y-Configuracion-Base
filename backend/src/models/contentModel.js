const pool = require('../config/db');

const q = async (sql, params) => (await pool.query(sql, params)).rows;

// ---- Módulos ----
const listModules = (actor, cursoId) =>
  q('SELECT * FROM public.listar_modulos_por_curso($1,$2)', [actor, cursoId]);
const createModule = async (actor, cursoId, d) =>
  (await q('SELECT * FROM public.crear_modulo($1,$2,$3,$4,$5,$6)',
    [actor, cursoId, d.nombre, d.descripcion, d.orden, d.estado]))[0];
const getModule = async (actor, id) =>
  (await q('SELECT * FROM public.obtener_modulo($1,$2)', [actor, id]))[0];
const updateModule = async (actor, id, d) =>
  (await q('SELECT * FROM public.actualizar_modulo($1,$2,$3,$4,$5,$6)',
    [actor, id, d.nombre, d.descripcion, d.orden, d.estado]))[0];
const changeModuleStatus = async (actor, id, estado) =>
  (await q('SELECT * FROM public.cambiar_estado_modulo($1,$2,$3)', [actor, id, estado]))[0];
const deleteModule = (actor, id) =>
  q('SELECT public.eliminar_modulo($1,$2)', [actor, id]);

// ---- Temas ----
const listTopics = (actor, moduloId) =>
  q('SELECT * FROM public.listar_temas_por_modulo($1,$2)', [actor, moduloId]);
const createTopic = async (actor, moduloId, d) =>
  (await q('SELECT * FROM public.crear_tema($1,$2,$3,$4,$5,$6)',
    [actor, moduloId, d.nombre, d.descripcion, d.orden, d.estado]))[0];
const getTopic = async (actor, id) =>
  (await q('SELECT * FROM public.obtener_tema($1,$2)', [actor, id]))[0];
const updateTopic = async (actor, id, d) =>
  (await q('SELECT * FROM public.actualizar_tema($1,$2,$3,$4,$5,$6)',
    [actor, id, d.nombre, d.descripcion, d.orden, d.estado]))[0];
const changeTopicStatus = async (actor, id, estado) =>
  (await q('SELECT * FROM public.cambiar_estado_tema($1,$2,$3)', [actor, id, estado]))[0];
const deleteTopic = (actor, id) =>
  q('SELECT public.eliminar_tema($1,$2)', [actor, id]);

module.exports = {
  listModules, createModule, getModule, updateModule, changeModuleStatus, deleteModule,
  listTopics, createTopic, getTopic, updateTopic, changeTopicStatus, deleteTopic
};