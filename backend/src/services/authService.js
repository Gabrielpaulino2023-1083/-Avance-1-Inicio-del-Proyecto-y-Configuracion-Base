const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { ROLES } = require('../config/roles');
const AppError = require('../errors/AppError');
const userModel = require('../models/userModel');
const { toUserResponse } = require('../dtos/auth.dto');

const register = async ({ nombre, apellido, email, password }) => {
  const existing = await userModel.findByEmail(email);
  if (existing) throw new AppError(409, 'Ya existe un usuario con ese email');

  const passwordHash = await bcrypt.hash(password, 10);
  // Todo registro público es ESTUDIANTE; docentes y admins se crean aparte.
  const user = await userModel.create({
    nombre, apellido, email, passwordHash, rol: ROLES.ESTUDIANTE
  });
  return toUserResponse(user);
};

const login = async ({ email, password }) => {
  const user = await userModel.findByEmail(email);
  const valid = user && user.activo && (await bcrypt.compare(password, user.passwordHash));
  if (!valid) throw new AppError(401, 'Credenciales inválidas');

  const token = jwt.sign({ id: user.id, rol: user.rol }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn
  });
  return { token, user: toUserResponse(user) };
};

const getMe = async (id) => {
  const user = await userModel.findById(id);
  if (!user || !user.activo) throw new AppError(401, 'Usuario no encontrado o inactivo');
  return toUserResponse(user);
};

module.exports = { register, login, getMe };