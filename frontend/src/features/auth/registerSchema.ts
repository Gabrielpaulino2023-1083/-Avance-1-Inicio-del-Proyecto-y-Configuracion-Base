import { z } from "zod";

// Las reglas siguen las del backend (registerDto): nombre y apellido
// hasta 50 caracteres, y contraseña de 8 a 72.
export const registerSchema = z
  .object({
    nombre: z
      .string()
      .trim()
      .min(1, "Ingresa tu nombre.")
      .max(50, "Máximo 50 caracteres."),
    apellido: z
      .string()
      .trim()
      .min(1, "Ingresa tu apellido.")
      .max(50, "Máximo 50 caracteres."),
    email: z
      .string()
      .trim()
      .min(1, "Ingresa tu correo.")
      .email("Ingresa un correo válido."),
    password: z
      .string()
      .min(8, "La contraseña debe tener al menos 8 caracteres.")
      .max(72, "Máximo 72 caracteres."),
    confirmPassword: z.string().min(1, "Confirma tu contraseña."),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Las contraseñas no coinciden.",
    path: ["confirmPassword"],
  });

export type RegisterFormValues = z.infer<typeof registerSchema>;