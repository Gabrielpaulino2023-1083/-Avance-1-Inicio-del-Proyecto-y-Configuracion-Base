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
SET LOCAL search_path=pg_catalog,public,pg_temp;
CREATE TEMP TABLE parametros010(docente TEXT,estudiante TEXT) ON COMMIT DROP;
INSERT INTO parametros010 VALUES(lower(btrim(:'docente_email')),lower(btrim(:'estudiante_email')));
DO $$
DECLARE ad INTEGER; d INTEGER; u INTEGER; c INTEGER; e INTEGER; s INTEGER; m INTEGER; t INTEGER; x INTEGER; mark TEXT; old TEXT;
 a public.actividades; q public.preguntas; lvl TEXT;
BEGIN
 PERFORM pg_advisory_xact_lock(10010,2026);
 SELECT z.id INTO ad FROM usuarios z JOIN usuario_roles ur ON ur.usuario_id=z.id AND ur.activo JOIN roles r ON r.id=ur.rol_id AND r.codigo='ADMINISTRADOR' WHERE z.activo ORDER BY z.id LIMIT 1;
 SELECT z.id INTO d FROM usuarios z JOIN usuario_roles ur ON ur.usuario_id=z.id AND ur.activo JOIN roles r ON r.id=ur.rol_id AND r.codigo='DOCENTE' WHERE z.activo AND lower(z.email)=(SELECT docente FROM parametros010);
 SELECT z.id INTO u FROM usuarios z JOIN usuario_roles ur ON ur.usuario_id=z.id AND ur.activo JOIN roles r ON r.id=ur.rol_id AND r.codigo='ESTUDIANTE' WHERE z.activo AND lower(z.email)=(SELECT estudiante FROM parametros010);
 IF ad IS NULL OR d IS NULL OR u IS NULL THEN RAISE EXCEPTION 'Cargar antes administrador, docente y estudiante activos. No se crean ni cambian sus credenciales.'; END IF;
 mark:='DEMO010_V1; docente='||d||'; estudiante='||u;
 SELECT id,descripcion INTO c,old FROM cursos WHERE codigo='DEMO-CUESTIONARIOS-010' FOR UPDATE;
 IF FOUND THEN
  IF old IS DISTINCT FROM mark OR (SELECT count(*) FROM actividades ac JOIN secciones sec ON sec.id=ac.seccion_id JOIN ediciones_curso ed ON ed.id=sec.edicion_id WHERE ed.curso_id=c)<>2 THEN
   RAISE EXCEPTION 'Colision o demo modificada/incompleta; no sobrescribir automaticamente.'; END IF;
  RAISE NOTICE 'Demo 010 existente: no se reinician contenido, intentos ni permisos.'; RETURN;
 END IF;
 -- Preparacion administrativa: aun no existe CRUD publico de ediciones/asignaciones.
 INSERT INTO cursos(codigo,nombre,descripcion,estado,creado_por) VALUES('DEMO-CUESTIONARIOS-010','Gestion docente de cuestionarios',mark,'ACTIVO',ad) RETURNING id INTO c;
 INSERT INTO ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,inscripcion_desde,inscripcion_hasta,estado,creado_por)
 VALUES(c,'ED-010','Edicion de demostracion',now()-interval '1 day',now()+interval '1 year',now()-interval '1 day',now()+interval '1 month','ABIERTA',ad) RETURNING id INTO e;
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por) VALUES(e,'SEC-010',30,'ABIERTA',ad) RETURNING id INTO s;
 INSERT INTO curso_editores(curso_id,usuario_id,asignado_por) VALUES(c,d,ad);
 INSERT INTO seccion_docentes(seccion_id,usuario_id,asignado_por) VALUES(s,d,ad);
 SELECT id INTO x FROM inscribir_estudiante(s,u,u);
 SELECT id INTO m FROM crear_modulo(d,c,'Cuestionarios del docente','Contenido creado mediante funciones SQL',1,'PUBLICADO');
 SELECT id INTO t FROM crear_tema(d,m,'SQL JOIN: edicion docente','Dos practicas de demostracion',1,'PUBLICADO');
 FOREACH lvl IN ARRAY ARRAY['BAJA','MEDIA'] LOOP
  a:=crear_actividad(d,s,t,'DEMO-010: SQL JOIN '||lvl,'Selecciona la respuesta correcta.','PRACTICA',lvl,5,30,now()-interval '1 minute',now()+interval '1 year');
  q:=crear_pregunta(d,a.id,CASE lvl WHEN 'BAJA' THEN '¿Que conserva LEFT JOIN cuando no hay coincidencia derecha?' ELSE 'Clientes 1 y 2; pedidos del cliente 1: dos. ¿Cuantas filas devuelve clientes LEFT JOIN pedidos?' END,'SELECCION_UNICA',1,10,NULL);
  PERFORM crear_opcion_respuesta(d,q.id,CASE lvl WHEN 'BAJA' THEN 'La fila izquierda con columnas derechas NULL' ELSE 'Tres filas' END,1,TRUE);
  PERFORM crear_opcion_respuesta(d,q.id,CASE lvl WHEN 'BAJA' THEN 'Ninguna fila' ELSE 'Dos filas' END,2,FALSE);
  PERFORM publicar_actividad(d,a.id);
 END LOOP;
 RAISE NOTICE 'DEMO 010 creada: curso %, seccion %, tema %, docente %, estudiante %. Sin intentos iniciales.',c,s,t,d,u;
END; $$;
COMMIT;
