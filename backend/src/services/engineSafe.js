const AppError = require('../errors/AppError');
const { runEngine } = require('./engineClient');

// Cualquier fallo al ejecutar el motor de Python se informa como 502.
const runEngineSafe = async (payload) => {
  try {
    return await runEngine(payload);
  } catch (err) {
    console.error('[motor adaptativo]', err.message);
    throw new AppError(502, 'El motor de recomendación no está disponible');
  }
};

module.exports = { runEngineSafe };