const config = require('./config/config');
const app = require('./app');
const checkRoles = require('./config/checkRoles');

checkRoles()
  .then(() => {
    app.listen(config.port, () => {
      console.log(`Servidor corriendo en http://localhost:${config.port}`);
    });
  })
  .catch((err) => {
    console.error('No se pudo iniciar:', err.message);
    process.exit(1);
  });