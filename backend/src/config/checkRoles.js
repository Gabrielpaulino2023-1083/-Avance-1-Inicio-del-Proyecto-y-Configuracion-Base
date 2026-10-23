const pool = require('./db');
const { ROLE_VALUES } = require('./roles');

// Comprueba al arrancar que todos los roles del código existen en la base.
const checkRoles = async () => {
  const { rows } = await pool.query('SELECT codigo FROM roles');
  const inDb = rows.map((r) => r.codigo);
  const missing = ROLE_VALUES.filter((r) => !inDb.includes(r));
  if (missing.length) {
    throw new Error(`Roles ausentes en la base de datos: ${missing.join(', ')}`);
  }
};

module.exports = checkRoles;