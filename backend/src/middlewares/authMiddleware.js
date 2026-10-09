const jwt = require('jsonwebtoken');
const config = require('../config/config');
const AppError = require('../errors/AppError');
const { PERMISSIONS } = require('../config/permissions');

// Verifica el token. Encabezado: Authorization: Bearer <token>
const verifyToken = (req, res, next) => {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');

  if (type !== 'Bearer' || !token) {
    throw new AppError(401, 'Token requerido');
  }

  try {
    req.user = jwt.verify(token, config.jwtSecret); // { id, rol, iat, exp }
  } catch (err) {
    throw new AppError(401, 'Token inválido o expirado');
  }
  next();
};

// Restringe por rol: requireRole(ROLES.DOCENTE, ROLES.ADMINISTRADOR)
const requireRole = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.rol)) {
    throw new AppError(403, 'No tienes permiso para esta acción');
  }
  next();
};

// Restringe por permiso: requirePermission('students:list')
const requirePermission = (permission) => (req, res, next) => {
  const allowed = PERMISSIONS[permission];
  if (!allowed) {
    throw new Error(`Permiso no definido: ${permission}`);
  }
  if (!req.user || !allowed.includes(req.user.rol)) {
    throw new AppError(403, 'No tienes permiso para esta acción');
  }
  next();
};

module.exports = { verifyToken, requireRole, requirePermission };