const { z } = require('zod');
const { ROLE_VALUES } = require('../config/roles');

const changeRoleDto = z.object({
  rol: z.enum(ROLE_VALUES, { message: `El rol debe ser uno de: ${ROLE_VALUES.join(', ')}` })
});

module.exports = { changeRoleDto };