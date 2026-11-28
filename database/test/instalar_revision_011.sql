\set ON_ERROR_STOP on
\encoding UTF8
-- SOLO base nueva. No cierra permisos del registro antiguo.
\ir instalar_revision_010.sql
\ir ../migrations/011_usuarios_roles.sql
