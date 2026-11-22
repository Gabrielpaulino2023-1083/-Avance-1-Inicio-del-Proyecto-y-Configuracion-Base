\set ON_ERROR_STOP on
\encoding UTF8
\if :{?demo_email}
\else
 \set demo_email 'estudiante.demo@example.com'
\endif
BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL search_path=pg_catalog,public,pg_temp;
SELECT set_config('demo009.email',lower(btrim(:'demo_email')),true);
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE u INTEGER; i INTEGER; t INTEGER; r INTEGER; f RECORD;
BEGIN
 SELECT x.id,z.id,y.id INTO STRICT u,i,t FROM usuarios x
 JOIN inscripciones z ON z.estudiante_id=x.id JOIN ediciones_curso e ON e.id=z.edicion_id
 JOIN cursos c ON c.id=e.curso_id JOIN modulos m ON m.curso_id=c.id
 JOIN temas y ON y.modulo_id=m.id
 WHERE lower(x.email)=current_setting('demo009.email') AND c.codigo='DEMO-DIFICULTAD-009'
 AND y.nombre='SQL JOIN (demo dificultad)';
 SELECT id INTO STRICT r FROM actividades WHERE tema_id=t AND titulo='DEMO-009: Referencia: relacionar pedidos y clientes';
 IF NOT EXISTS(SELECT 1 FROM intentos WHERE actividad_id=r AND inscripcion_id=i
     AND numero_intento=1 AND estado='CALIFICADO' AND puntaje_obtenido=0 AND puntaje_maximo=20) THEN
  RAISE EXCEPTION 'Falta el intento inicial de referencia 0/20.';
 END IF;
 IF (SELECT count(DISTINCT dificultad) FROM actividades WHERE tema_id=t AND estado='PUBLICADO')<>3 THEN
  RAISE EXCEPTION 'La demo no tiene los tres niveles publicados.';
 END IF;
 IF (SELECT count(*) FROM listar_modulos_publicados_estudiante(u,(SELECT e.curso_id FROM inscripciones z JOIN ediciones_curso e ON e.id=z.edicion_id WHERE z.id=i)))<>1 THEN
  RAISE EXCEPTION 'Lectura 007 incompatible.';
 END IF;
 -- Comparacion inicial: si ya hubo practica adicional, usar base nueva para repetirla.
 IF (SELECT count(*) FROM listar_candidatas_actividad(u,i,t,r))<>4 THEN
  RAISE EXCEPTION 'Se esperaban cuatro candidatas iniciales (incluida referencia). La demo pudo cambiar por practica.';
 END IF;
 FOR f IN SELECT * FROM listar_candidatas_actividad(u,i,t,r) LOOP
  IF f.dificultad_referencia<>'MEDIA' OR f.max_intentos<>3 OR f.intentos_restantes<1 THEN
   RAISE EXCEPTION 'Contexto o cupo de intentos incorrecto.';
  END IF;
 END LOOP;
 RAISE NOTICE 'PRUEBAS SEED 009 COMPLETADAS: referencia, niveles, lectura y candidatas.';
END;
$$;
ROLLBACK;
