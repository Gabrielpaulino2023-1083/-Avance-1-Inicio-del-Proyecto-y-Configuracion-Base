// Cursos, basados en la tabla `cursos` y el CRUD de cursos del backend.
export type EstadoCurso = "BORRADOR" | "ACTIVO" | "ARCHIVADO";

export const ESTADOS_CURSO: EstadoCurso[] = ["BORRADOR", "ACTIVO", "ARCHIVADO"];

export interface Curso {
  id: number;
  codigo: string;
  nombre: string;
  descripcion: string;
  estado: EstadoCurso;
  creadoEn: string; // ISO
  actualizadoEn: string; // ISO
}

// Lo que escribe el administrador en el formulario.
export interface CursoInput {
  codigo: string;
  nombre: string;
  descripcion: string;
}