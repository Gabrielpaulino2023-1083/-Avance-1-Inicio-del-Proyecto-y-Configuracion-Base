const authService = require('../services/authService');

const register = async (req, res) => {
  const user = await authService.register(req.body);
  res.status(201).json({ success: true, user });
};

const login = async (req, res) => {
  const result = await authService.login(req.body);
  res.json({ success: true, ...result });
};

const me = async (req, res) => {
  const user = await authService.getMe(req.user.id);
  res.json({ success: true, user });
};

module.exports = { register, login, me };