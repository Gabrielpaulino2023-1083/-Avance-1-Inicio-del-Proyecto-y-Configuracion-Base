const rateLimit = require('express-rate-limit');

// Máximo 10 intentos de login/registro por IP cada 15 minutos
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Demasiados intentos. Intenta de nuevo en unos minutos.'
  }
});

module.exports = { authLimiter };