const { ROLES } = require('./roles');

// Cada permiso lista los roles que lo tienen.
// Si cambia quién puede qué, solo se edita este archivo.
const PERMISSIONS = Object.freeze({
  'students:list': [ROLES.DOCENTE, ROLES.ADMINISTRADOR],
  'students:read': [ROLES.ESTUDIANTE, ROLES.DOCENTE, ROLES.ADMINISTRADOR],
  'users:change-role': [ROLES.ADMINISTRADOR]
});

module.exports = { PERMISSIONS };