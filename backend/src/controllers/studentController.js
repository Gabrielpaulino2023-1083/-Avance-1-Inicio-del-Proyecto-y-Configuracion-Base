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

const getRecommendation = async (req, res) => {
  const recommendation = await studentService.getRecommendation(req.studentId, req.body.topic);
  res.json({ success: true, simulado: true, recommendation });
};

module.exports = { getSummary, getProgress, getRecommendation };