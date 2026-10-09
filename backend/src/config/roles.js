// Única fuente de verdad de los roles. Deben coincidir con roles.codigo en PostgreSQL.
const ROLES = Object.freeze({
  ESTUDIANTE: 'ESTUDIANTE',
  DOCENTE: 'DOCENTE',
  ADMINISTRADOR: 'ADMINISTRADOR'
});

const ROLE_VALUES = Object.freeze(Object.values(ROLES));

module.exports = { ROLES, ROLE_VALUES };