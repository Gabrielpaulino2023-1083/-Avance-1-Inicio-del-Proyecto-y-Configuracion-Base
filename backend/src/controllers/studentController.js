const studentService = require('../services/studentService');

// "simulado: true" indica que parte de los datos aún no sale de la base de datos.
const getSummary = async (req, res) => {
  const student = await studentService.getSummary(req.studentId);
  res.json({ success: true, simulado: true, student });
};

const getProgress = async (req, res) => {
  const progress = await studentService.getProgress(req.studentId);
  res.json({ success: true, simulado: true, progress });
};

module.exports = { getSummary, getProgress };