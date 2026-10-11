const AppError = require('../errors/AppError');
const { ROLES } = require('../config/roles');

const MAX_INT = 2147483647;

// El estudiante solo ve su propio :id. Docente y administrador pueden ver cualquiera.
// TODO: limitar al docente a los estudiantes de sus secciones (seccion_docentes + inscripciones).
const canAccessStudent = (req, res, next) => {
  const studentId = Number(req.params.id);
  if (!Number.isInteger(studentId) || studentId <= 0 || studentId > MAX_INT) {
    throw new AppError(400, 'Id de estudiante inválido');
  }

  const isOwner = req.user.id === studentId;
  const isStaff = [ROLES.DOCENTE, ROLES.ADMINISTRADOR].includes(req.user.rol);
  if (!isOwner && !isStaff) {
    throw new AppError(403, 'No tienes permiso para ver este estudiante');
  }

  req.studentId = studentId;
  next();
};

module.exports = { canAccessStudent };