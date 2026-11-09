const AppError = require('../errors/AppError');
const { ROLES } = require('../config/roles');
const studentModel = require('../models/studentModel');

const MAX_INT = 2147483647;

// - ESTUDIANTE: solo su propio id.
// - ADMINISTRADOR: cualquiera.
// - DOCENTE: solo estudiantes inscritos en secciones que él tiene asignadas.
const canAccessStudent = async (req, res, next) => {
  const studentId = Number(req.params.id);
  if (!Number.isInteger(studentId) || studentId <= 0 || studentId > MAX_INT) {
    throw new AppError(400, 'Id de estudiante inválido');
  }

  const { id: userId, rol } = req.user;
  let allowed = userId === studentId;

  if (!allowed && rol === ROLES.ADMINISTRADOR) {
    allowed = true;
  }

  if (!allowed && rol === ROLES.DOCENTE) {
    allowed = await studentModel.isTeacherOfStudent(userId, studentId);
  }

  if (!allowed) {
    throw new AppError(403, 'No tienes permiso para ver este estudiante');
  }

  req.studentId = studentId;
  next();
};

module.exports = { canAccessStudent };