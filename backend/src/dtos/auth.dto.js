const { z } = require('zod');

// ---- DTOs de ENTRADA (lo que el cliente puede enviar) ----
const registerDto = z.object({
  nombre: z.string().trim().min(1, 'El nombre es obligatorio').max(50),
  apellido: z.string().trim().min(1, 'El apellido es obligatorio').max(50),
  email: z.string().trim().email('Email inválido'),
  // 72 es el máximo que bcrypt procesa
  password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres').max(72)
});

const loginDto = z.object({
  email: z.string().trim().min(1, 'El email es obligatorio'),
  password: z.string().min(1, 'La contraseña es obligatoria')
});

// ---- DTO de SALIDA (lo que el cliente puede ver) ----
// Garantiza que nunca se filtre passwordHash ni otros campos internos.
const toUserResponse = (u) => ({
  id: u.id,
  nombre: u.nombre,
  apellido: u.apellido,
  email: u.email,
  rol: u.rol
});

module.exports = { registerDto, loginDto, toUserResponse };