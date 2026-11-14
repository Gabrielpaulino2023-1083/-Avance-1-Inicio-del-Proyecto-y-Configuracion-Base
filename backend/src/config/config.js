require('dotenv').config();

const isTest = process.env.NODE_ENV === 'test';

// Sin JWT_SECRET el servidor no debe arrancar (salvo en pruebas)
if (!process.env.JWT_SECRET && !isTest) {
  throw new Error('Falta JWT_SECRET en el archivo .env');
}

module.exports = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 3000,
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  jwtSecret: process.env.JWT_SECRET || 'secreto-solo-para-pruebas',
  jwtExpiresIn: '2h'
};