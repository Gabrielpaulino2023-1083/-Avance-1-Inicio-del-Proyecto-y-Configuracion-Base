const AppError = require('./AppError');

const parseId = (value, label) => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0 || id > 2147483647) {
    throw new AppError(400, `Id de ${label} inválido`);
  }
  return id;
};

// Traduce SQLSTATE de las funciones a HTTP sin exponer el texto interno de SQL.
const mapDbError = (err) => {
  switch (err.code) {
    case '42501': throw new AppError(403, 'No tienes acceso a este recurso');
    case '22023': throw new AppError(400, 'Datos inválidos');
    case 'P0002': throw new AppError(404, 'El recurso no está disponible');
    case '55000': throw new AppError(409, 'La operación no es válida en el estado actual');
    case '23505': throw new AppError(409, 'Ya existe un registro en conflicto');
    case '22007':
    case '22008': throw new AppError(400, 'Fecha inválida');
    default: throw err;
  }
};

const run = async (fn) => {
  try { return await fn(); } catch (err) { return mapDbError(err); }
};

const ok = (res, data, status = 200) => res.status(status).json({ success: true, data });

module.exports = { parseId, mapDbError, run, ok };