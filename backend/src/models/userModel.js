const pool = require('../config/db');

const findByEmail = async (email) => {
  const { rows } = await pool.query(
    `SELECT u.id, u.nombre, u.apellido, u.email, u.activo,
            u.password_hash AS "passwordHash", r.codigo AS rol
     FROM usuarios u
     JOIN usuario_roles ur ON ur.usuario_id = u.id AND ur.activo = TRUE
     JOIN roles r ON r.id = ur.rol_id
     WHERE lower(u.email) = lower($1)
     LIMIT 1`,
    [email]
  );
  return rows[0] || null;
};

const findById = async (id) => {
  const { rows } = await pool.query(
    `SELECT u.id, u.nombre, u.apellido, u.email, u.activo, r.codigo AS rol
     FROM usuarios u
     JOIN usuario_roles ur ON ur.usuario_id = u.id AND ur.activo = TRUE
     JOIN roles r ON r.id = ur.rol_id
     WHERE u.id = $1
     LIMIT 1`,
    [id]
  );
  return rows[0] || null;
};

// Crea el usuario y su rol en una sola transacción:
// si algo falla, no queda nada a medias.
const create = async ({ nombre, apellido, email, passwordHash, rol }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      `INSERT INTO usuarios (nombre, apellido, email, password_hash)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nombre, apellido, email`,
      [nombre, apellido, email, passwordHash]
    );
    const user = rows[0];

    // El registro público se asigna a sí mismo (asignado_por = su propio id)
    const roleResult = await client.query(
      `INSERT INTO usuario_roles (usuario_id, rol_id, asignado_por)
       SELECT $1, id, $1 FROM roles WHERE codigo = $2`,
      [user.id, rol]
    );
    if (roleResult.rowCount === 0) {
      throw new Error(`El rol ${rol} no existe en la base de datos (¿corriste el seed?)`);
    }

    await client.query('COMMIT');
    return { ...user, rol };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = { findByEmail, findById, create };