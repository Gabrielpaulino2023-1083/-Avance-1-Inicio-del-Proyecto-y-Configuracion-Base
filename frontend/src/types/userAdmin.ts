// Usuarios vistos por el administrador.
// Contrato propuesto al backend (todavía no existe):
//   GET   /usuarios
//   PATCH /usuarios/:id/rol     { rol }
//   PATCH /usuarios/:id/estado  { activo }
export type RolUsuario = "ESTUDIANTE" | "DOCENTE" | "ADMINISTRADOR";

export const ROLES_USUARIO: RolUsuario[] = [
  "ESTUDIANTE",
  "DOCENTE",
  "ADMINISTRADOR",
];

export interface UsuarioAdmin {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  rol: RolUsuario;
  activo: boolean;
  creadoEn: string; // ISO
}