const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const config = require('./config/config');
const openApiSpec = require('./config/swagger');
const healthRoutes = require('./routes/healthRoutes');
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const { notFound, errorHandler } = require('./middlewares/errorHandler');

const app = express();

app.use(cors({ origin: config.corsOrigin }));
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ mensaje: 'API del Motor de Aprendizaje Adaptativo funcionando' });
});

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);

// Documentación interactiva (Swagger UI) y especificación en JSON
app.get('/api/docs.json', (req, res) => res.json(openApiSpec));
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiSpec));

// Siempre al final
app.use(notFound);
app.use(errorHandler);

module.exports = app;