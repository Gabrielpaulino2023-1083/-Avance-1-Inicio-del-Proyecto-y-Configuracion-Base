const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const { ROLE_VALUES } = require('./roles');

const specPath = path.join(__dirname, '../docs/openapi.yaml');
const openApiSpec = yaml.load(fs.readFileSync(specPath, 'utf8'));

// El enum de roles sale de roles.js, no se mantiene a mano en el YAML
openApiSpec.components.schemas.User.properties.rol.enum = [...ROLE_VALUES];

module.exports = openApiSpec;