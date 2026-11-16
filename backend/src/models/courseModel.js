const pool = require('../config/db');

const create = async (actorId, { codigo, nombre, descripcion }) => {
  const { rows } = await pool.query(
    'SELECT * FROM public.crear_curso_admin($1,$2,$3,$4)',
    [actorId, codigo, nombre, descripcion]
  );
  return rows[0];
};

const list = async (actorId, { estado, limite, desplazamiento }) => {
  const { rows } = await pool.query(
    'SELECT * FROM public.listar_cursos_admin($1,$2,$3,$4)',
    [actorId, estado ?? null, limite, desplazamiento]
  );
  return rows;
};

const getById = async (actorId, id) => {
  const { rows } = await pool.query(
    'SELECT * FROM public.obtener_curso_admin($1,$2)',
    [actorId, id]
  );
  return rows[0];
};

const update = async (actorId, id, { codigo, nombre, descripcion }) => {
  const { rows } = await pool.query(
    'SELECT * FROM public.actualizar_curso_admin($1,$2,$3,$4,$5)',
    [actorId, id, codigo, nombre, descripcion]
  );
  return rows[0];
};

const changeStatus = async (actorId, id, estado) => {
  const { rows } = await pool.query(
    'SELECT * FROM public.cambiar_estado_curso_admin($1,$2,$3)',
    [actorId, id, estado]
  );
  return rows[0];
};

module.exports = { create, list, getById, update, changeStatus };