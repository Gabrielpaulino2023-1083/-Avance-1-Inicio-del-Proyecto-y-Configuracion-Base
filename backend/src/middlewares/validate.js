const AppError = require('../errors/AppError');

// Valida req.body con un DTO. Si falla, responde 400 con el detalle por campo.
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    const details = result.error.issues.map((i) => ({
      campo: i.path.join('.'),
      mensaje: i.message
    }));
    throw new AppError(400, 'Datos inválidos', details);
  }
  req.body = result.data; // datos ya limpios (trim, etc.)
  next();
};

module.exports = validate;