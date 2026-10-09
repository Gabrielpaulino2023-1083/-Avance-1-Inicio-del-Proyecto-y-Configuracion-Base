const getHealth = (req, res) => {
  res.json({
    status: 'ok',
    service: 'backend',
    timestamp: new Date().toISOString()
  });
};

module.exports = { getHealth };