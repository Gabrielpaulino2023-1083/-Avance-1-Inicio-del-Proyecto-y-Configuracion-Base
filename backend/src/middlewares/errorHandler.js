const notFound = (req, res) => {
  res.status(404).json({ success: false, message: 'Ruta no encontrada' });
};

// Único lugar donde se decide cómo responder a un error
const errorHandler = (err, req, res, next) => {
  if (err.status) {
    return res.status(err.status).json({
      success: false,
      message: err.message,
      ...(err.details && { details: err.details })
    });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ success: false, message: 'JSON inválido' });
  }
  // Email duplicado detectado por PostgreSQL (dos registros simultáneos)
  if (err.code === '23505') {
    return res.status(409).json({ success: false, message: 'El registro ya existe' });
  }
  console.error(err);
  res.status(500).json({ success: false, message: 'Error interno del servidor' });
};

module.exports = { notFound, errorHandler };