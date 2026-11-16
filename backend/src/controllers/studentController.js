const studentService = require('../services/studentService');

const getSummary = async (req, res) => {
  const { summary, datosReales } = await studentService.getSummary(req.studentId);
  res.json({ success: true, simulado: false, datosReales, student: summary });
};

const getProgress = async (req, res) => {
  const progress = await studentService.getProgress(req.studentId);
  res.json({ success: true, simulado: false, progress });
};

const getRecommendation = async (req, res) => {
  const recommendation = await studentService.getRecommendation(req.studentId, req.body.topic);
  res.json({ success: true, recommendation });
};

module.exports = { getSummary, getProgress, getRecommendation };