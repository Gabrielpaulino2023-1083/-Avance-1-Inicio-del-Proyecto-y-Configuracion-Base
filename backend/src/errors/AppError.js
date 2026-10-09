// Error "esperado" con código HTTP (400, 401, 409...)
class AppError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

module.exports = AppError;