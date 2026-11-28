\set ON_ERROR_STOP on
\encoding UTF8
-- SOLO base nueva; el instalador de 009 comprueba que no existan tablas publicas.
\ir instalar_revision_009.sql
\ir ../migrations/010_gestion_actividades_cuestionarios.sql
