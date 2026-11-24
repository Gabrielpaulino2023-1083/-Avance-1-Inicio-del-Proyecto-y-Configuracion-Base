\set ON_ERROR_STOP on
\encoding UTF8
-- SOLO una base nueva de revision. Rutas relativas a este archivo.
DO $$
BEGIN
 IF EXISTS(SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname='public') THEN
  RAISE EXCEPTION 'Se requiere una base nueva sin tablas publicas; no reinstalar sobre desarrollo.';
 END IF;
END;
$$;
SET search_path=public;
\ir ../migrations/001_estructura_academica_inicial.sql
\ir ../migrations/002_modulos_temas.sql
\ir ../migrations/003_actividades_intentos_respuestas.sql
\ir ../security/001_roles_permisos.sql
\ir ../migrations/004_inscripcion_estudiantes.sql
\ir ../migrations/005_crud_cursos.sql
\ir ../migrations/006_crud_modulos_temas.sql
\ir ../migrations/007_lectura_contenido_estudiantes.sql
\ir ../migrations/008_consultas_integracion.sql
\ir ../migrations/009_dificultad_candidatas.sql
