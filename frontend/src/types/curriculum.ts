// Módulos y temas de un curso, basados en las tablas `modulos` y `temas`.
export type EstadoContenido = "BORRADOR" | "PUBLICADO" | "ARCHIVADO";

export const ESTADOS: EstadoContenido[] = ["BORRADOR", "PUBLICADO", "ARCHIVADO"];

export interface Modulo {
  id: number;
  cursoId: number;
  nombre: string;
  descripcion: string;
  orden: number;
  estado: EstadoContenido;
  actualizadoEn: string; // ISO
  totalTemas: number;
}

export interface Tema {
  id: number;
  moduloId: number;
  nombre: string;
  descripcion: string;
  orden: number;
  estado: EstadoContenido;
  actualizadoEn: string; // ISO
}

// Lo que escribe el usuario en el formulario (crear y editar).
export interface ContenidoInput {
  nombre: string;
  descripcion: string;
  orden: number;
  estado: EstadoContenido;
}