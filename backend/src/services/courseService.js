const AppError = require('../errors/AppError');
const courseModel = require('../models/courseModel');
const { toCourseResponse } = require('../dtos/course.dto');

// Traduce los SQLSTATE de las funciones de cursos a errores HTTP.
const mapDbError = (err) => {
  switch (err.code) {
    case '42501': throw new AppError(403, 'No tienes permiso para administrar cursos');
    case '22023': throw new AppError(400, 'Datos inválidos');
    case 'P0002': throw new AppError(404, 'El curso no existe');
    case '23505': throw new AppError(409, 'Ya existe un curso con ese código');
    case '55000': throw new AppError(409, 'La operación no es válida para el estado actual del curso');
    default: throw err;
  }
};

const run = async (fn) => {
  try {
    return await fn();
  } catch (err) {
    return mapDbError(err);
  }
};

const create = (actorId, data) =>
  run(async () => toCourseResponse(await courseModel.create(actorId, data)));

const list = (actorId, filters) =>
  run(async () => (await courseModel.list(actorId, filters)).map(toCourseResponse));

const getById = (actorId, id) =>
  run(async () => toCourseResponse(await courseModel.getById(actorId, id)));

const update = (actorId, id, data) =>
  run(async () => toCourseResponse(await courseModel.update(actorId, id, data)));

const changeStatus = (actorId, id, estado) =>
  run(async () => toCourseResponse(await courseModel.changeStatus(actorId, id, estado)));

module.exports = { create, list, getById, update, changeStatus };