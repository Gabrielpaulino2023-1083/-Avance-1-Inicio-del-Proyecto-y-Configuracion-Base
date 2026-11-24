const notFound = (req, res) => {
  res.status(404).json({ success: false, message: 'Ruta no encontrada' });
};

// Único lugar donde se decide cómo responder a un error
const errorHandler = (err, req, res, next) => {
  // Errores del lector de cuerpos de Express: tienen status, por eso van primero
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ success: false, message: 'JSON inválido' });
  }
  if (err.type === 'entity.too.large') {
    return res.status(413).json({
      success: false,
      message: 'El cuerpo de la petición es demasiado grande'
    });
  }
  if (err.status) {
    return res.status(err.status).json({
      success: false,
      message: err.message,
      ...(err.details && { details: err.details })
    });
  }
  // Email duplicado detectado por PostgreSQL (dos registros simultáneos)
  if (err.code === '23505') {
    return res.status(409).json({ success: false, message: 'El registro ya existe' });
  }
  console.error(err);
  res.status(500).json({ success: false, message: 'Error interno del servidor' });
};

module.exports = { notFound, errorHandler };