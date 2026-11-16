const AppError = require('../errors/AppError');
const courseService = require('../services/courseService');

const parseId = (value) => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0 || id > 2147483647) {
    throw new AppError(400, 'Id de curso inválido');
  }
  return id;
};

const create = async (req, res) => {
  const data = await courseService.create(req.user.id, req.body);
  res.status(201).json({ success: true, data });
};

const list = async (req, res) => {
  const estado = req.query.estado;
  if (estado && !['BORRADOR', 'ACTIVO', 'ARCHIVADO'].includes(estado)) {
    throw new AppError(400, 'Estado de filtro inválido');
  }
  const limite = req.query.limite ? Number(req.query.limite) : 50;
  const desplazamiento = req.query.desplazamiento ? Number(req.query.desplazamiento) : 0;
  if (!Number.isInteger(limite) || limite < 1 || limite > 100 ||
      !Number.isInteger(desplazamiento) || desplazamiento < 0) {
    throw new AppError(400, 'Paginación inválida');
  }
  const data = await courseService.list(req.user.id, { estado, limite, desplazamiento });
  res.json({ success: true, data });
};

const getById = async (req, res) => {
  const data = await courseService.getById(req.user.id, parseId(req.params.id));
  res.json({ success: true, data });
};

const update = async (req, res) => {
  const data = await courseService.update(req.user.id, parseId(req.params.id), req.body);
  res.json({ success: true, data });
};

const changeStatus = async (req, res) => {
  const data = await courseService.changeStatus(req.user.id, parseId(req.params.id), req.body.estado);
  res.json({ success: true, data });
};

module.exports = { create, list, getById, update, changeStatus };