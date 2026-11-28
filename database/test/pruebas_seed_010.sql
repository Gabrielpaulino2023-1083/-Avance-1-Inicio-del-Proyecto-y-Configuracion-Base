\set ON_ERROR_STOP on
\encoding UTF8
\if :{?docente_email}
\else
 \set docente_email 'docente.demo@example.com'
\endif
\if :{?estudiante_email}
\else
 \set estudiante_email 'estudiante.demo@example.com'
\endif
BEGIN;
-- La lectura editorial usa bloqueos de fila: no usar SET TRANSACTION READ ONLY.
SELECT set_config('demo010.docente',:'docente_email',true),set_config('demo010.estudiante',:'estudiante_email',true);
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE d INTEGER; u INTEGER; s INTEGER; t INTEGER; i INTEGER; c INTEGER; a RECORD;
BEGIN
 SELECT id INTO STRICT d FROM usuarios WHERE lower(email)=lower(current_setting('demo010.docente'));
 SELECT id INTO STRICT u FROM usuarios WHERE lower(email)=lower(current_setting('demo010.estudiante'));
 SELECT x.id,y.id,z.id,e.id INTO STRICT s,t,i,c FROM cursos e JOIN ediciones_curso ed ON ed.curso_id=e.id JOIN secciones x ON x.edicion_id=ed.id JOIN modulos m ON m.curso_id=e.id JOIN temas y ON y.modulo_id=m.id JOIN inscripciones z ON z.seccion_id=x.id AND z.estudiante_id=u WHERE e.codigo='DEMO-CUESTIONARIOS-010';
 IF (SELECT count(*) FROM listar_actividades_gestion(d,s,t))<>2 THEN RAISE EXCEPTION 'Se esperaban dos actividades editoriales.'; END IF;
 IF (SELECT count(*) FROM listar_actividades_publicadas_estudiante(u,i,t))<>2 THEN RAISE EXCEPTION 'Lectura estudiante incompatible.'; END IF;
 FOR a IN SELECT * FROM listar_actividades_gestion(d,s,t) LOOP
  IF a.estado<>'PUBLICADO' OR a.dificultad NOT IN ('BAJA','MEDIA') OR (SELECT count(*) FROM listar_preguntas_gestion(d,a.id))<>1 THEN RAISE EXCEPTION 'Cuestionario inicial no esperado.'; END IF;
 END LOOP;
 RAISE NOTICE 'PRUEBAS SEED 010 COMPLETADAS: docente autorizado y lectura estudiante.';
END; $$;
ROLLBACK;
