\set ON_ERROR_STOP on
\encoding UTF8
-- Fixture propio, sin seeds. Ejecutar como postgres sin transaccion abierta.
BEGIN;
SET LOCAL search_path=pg_catalog,public,pg_temp;
CREATE TEMP TABLE contexto009(clave TEXT PRIMARY KEY,id INTEGER NOT NULL) ON COMMIT DROP;
CREATE FUNCTION pg_temp.id009(k TEXT) RETURNS INTEGER LANGUAGE sql STABLE AS
' SELECT id FROM pg_temp.contexto009 WHERE clave=k ';
CREATE FUNCTION pg_temp.ok009(b BOOLEAN,m TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
 IF b IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'FALLO 009: %',m; END IF;
 RAISE NOTICE 'OK 009: %',m;
END;
$$;
CREATE FUNCTION pg_temp.error009(q TEXT,c TEXT,m TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v TEXT;
BEGIN
 BEGIN EXECUTE q; EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS v=RETURNED_SQLSTATE; END;
 PERFORM pg_temp.ok009(v IS NOT DISTINCT FROM c,m||' esperado '||c||', recibido '||coalesce(v,'sin error'));
END;
$$;
INSERT INTO roles(codigo,nombre) VALUES('ESTUDIANTE','Estudiante'),('ADMINISTRADOR','Administrador') ON CONFLICT(codigo) DO NOTHING;
DO $$
DECLARE a INTEGER; u INTEGER; v INTEGER; c INTEGER; e INTEGER; sec INTEGER; m INTEGER;
 t INTEGER; act INTEGER; q INTEGER; k TEXT; sec2 INTEGER;
BEGIN
 FOREACH k IN ARRAY ARRAY['admin','estudiante','otro'] LOOP
  INSERT INTO usuarios(nombre,apellido,email,password_hash)
  VALUES(k,'Prueba009','test009-'||k||'-'||txid_current()||'@example.com','FICTICIO_NO_LOGIN') RETURNING id INTO v;
  INSERT INTO contexto009 VALUES(k,v);
 END LOOP;
 a:=pg_temp.id009('admin');u:=pg_temp.id009('estudiante');
 INSERT INTO usuario_roles(usuario_id,rol_id,asignado_por)
 SELECT x.id,r.id,a FROM contexto009 x CROSS JOIN roles r
 WHERE r.codigo=CASE WHEN x.clave='admin' THEN 'ADMINISTRADOR' ELSE 'ESTUDIANTE' END;
 INSERT INTO cursos(codigo,nombre,descripcion,estado,creado_por)
 VALUES('T009-'||txid_current(),'Prueba009','Prueba','ACTIVO',a) RETURNING id INTO c;
 INSERT INTO contexto009 VALUES('curso',c);
 INSERT INTO ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,inscripcion_desde,inscripcion_hasta,estado,creado_por)
 VALUES(c,'E','Edicion',now()-interval '1 day',now()+interval '1 year',now()-interval '1 day',now()+interval '1 year','ABIERTA',a) RETURNING id INTO e;
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por)
 VALUES(e,'S1',10,'ABIERTA',a) RETURNING id INTO sec;
 INSERT INTO contexto009 VALUES('seccion',sec);
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por)
 VALUES(e,'S2',10,'ABIERTA',a) RETURNING id INTO sec2;
 SELECT id INTO v FROM inscribir_estudiante(sec,u,a);
 INSERT INTO contexto009 VALUES('inscripcion',v);
 SELECT id INTO v FROM inscribir_estudiante(sec2,pg_temp.id009('otro'),a);
 INSERT INTO contexto009 VALUES('otra_inscripcion',v);
 INSERT INTO modulos(curso_id,nombre,descripcion,orden,estado,creado_por)
 VALUES(c,'Modulo','Prueba',1,'PUBLICADO',a) RETURNING id INTO m;
 INSERT INTO contexto009 VALUES('modulo',m);
 INSERT INTO temas(modulo_id,nombre,descripcion,orden,estado,creado_por)
 VALUES(m,'Tema','Prueba',1,'PUBLICADO',a) RETURNING id INTO t;
 INSERT INTO contexto009 VALUES('tema',t);
 INSERT INTO temas(modulo_id,nombre,descripcion,orden,estado,creado_por)
 VALUES(m,'Otro tema','Prueba',2,'PUBLICADO',a) RETURNING id INTO v;
 INSERT INTO contexto009 VALUES('otro_tema',v);
 FOREACH k IN ARRAY ARRAY['referencia','baja','media','alta','sin_nivel','futura','cerrada','borrador','archivada','agotada','abierta','otra_seccion','otro_tema_actividad'] LOOP
  INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,dificultad,max_intentos,disponible_desde,disponible_hasta,creado_por)
  VALUES(CASE WHEN k='otra_seccion' THEN sec2 ELSE sec END,
    CASE WHEN k='otro_tema_actividad' THEN pg_temp.id009('otro_tema') ELSE t END,k,'Prueba',
    CASE k WHEN 'baja' THEN 'BAJA' WHEN 'alta' THEN 'ALTA' WHEN 'sin_nivel' THEN NULL ELSE 'MEDIA' END,
    CASE WHEN k='agotada' THEN 1 ELSE NULL END,
    CASE WHEN k='futura' THEN now()+interval '1 day' ELSE now()-interval '2 days' END,
    CASE WHEN k='cerrada' THEN now()-interval '1 day' ELSE now()+interval '1 year' END,a) RETURNING id INTO act;
  INSERT INTO contexto009 VALUES(k,act);
  INSERT INTO preguntas(actividad_id,enunciado,orden,puntaje_maximo) VALUES(act,'Elige A',1,10) RETURNING id INTO q;
  INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta) VALUES(q,'A',1,TRUE),(q,'B',2,FALSE);
  IF k<>'borrador' THEN UPDATE actividades SET estado='PUBLICADO' WHERE id=act; END IF;
  IF k='archivada' THEN UPDATE actividades SET estado='ARCHIVADO' WHERE id=act; END IF;
 END LOOP;
END;
$$;
GRANT SELECT,INSERT ON contexto009 TO plataforma_backend;
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE u INTEGER:=pg_temp.id009('estudiante'); i INTEGER:=pg_temp.id009('inscripcion');
 t INTEGER:=pg_temp.id009('tema'); ref INTEGER:=pg_temp.id009('referencia'); n BIGINT; it INTEGER; k TEXT; fila RECORD;
BEGIN
 SELECT count(*) INTO n FROM listar_candidatas_actividad(u,i,t);
 PERFORM pg_temp.ok009(n=0,'sin historial no hay referencia');
 PERFORM pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s,%s)',u,i,t,ref),'42501','referencia sin intento propio');
 FOREACH k IN ARRAY ARRAY['referencia','agotada'] LOOP
  it:=iniciar_intento(pg_temp.id009(k),i,u);
  INSERT INTO contexto009 VALUES('intento_'||k,it);
  PERFORM entregar_intento(it,u);PERFORM calificar_intento(it);
 END LOOP;
 it:=iniciar_intento(pg_temp.id009('abierta'),i,u);
 INSERT INTO contexto009 VALUES('intento_abierto',it);
 SELECT count(*) INTO n FROM listar_candidatas_actividad(u,i,t,ref);
 PERFORM pg_temp.ok009(n=4,'solo referencia y tres niveles, sin futuras/cerradas/agotadas/abiertas/ocultas/ajenas');
 SELECT * INTO STRICT fila FROM listar_candidatas_actividad(u,i,t,ref) WHERE actividad_id=ref;
 PERFORM pg_temp.ok009(fila.dificultad_referencia='MEDIA' AND fila.es_repeticion AND fila.intentos_restantes IS NULL AND fila.intentos_iniciados=1,'referencia media y repeticion ilimitada');
 SELECT * INTO STRICT fila FROM listar_candidatas_actividad(u,i,t,ref) WHERE actividad_id=pg_temp.id009('baja');
 PERFORM pg_temp.ok009(fila.intentos_iniciados=0 AND NOT fila.es_repeticion,'candidata distinta sin intentos');
 PERFORM pg_temp.ok009((SELECT bool_and(actividad_referencia_id=pg_temp.id009('agotada')) FROM listar_candidatas_actividad(u,i,t)),'referencia automatica ultimo calificado aun agotada');
 PERFORM pg_temp.ok009((SELECT count(*)=3 FROM intentos WHERE inscripcion_id=i),'lecturas no crean intentos');
 PERFORM pg_temp.ok009(has_function_privilege(current_user,'public.listar_candidatas_actividad(integer,integer,integer,integer)','EXECUTE'),'EXECUTE backend');
 PERFORM pg_temp.ok009(NOT has_any_column_privilege(current_user,'public.actividades','UPDATE'),'sin escritura directa nueva');
 PERFORM pg_temp.ok009(NOT has_column_privilege(current_user,'public.opciones_respuestas','es_correcta','SELECT'),'sin soluciones directas');
 PERFORM pg_temp.ok009((SELECT p.prosecdef AND p.provolatile='s' AND pg_get_userbyid(p.proowner)='plataforma_operaciones' AND p.proconfig @> ARRAY['search_path=pg_catalog, public, pg_temp'] FROM pg_proc p WHERE p.oid='public.listar_candidatas_actividad(integer,integer,integer,integer)'::regprocedure),'propietario y search_path');
 PERFORM pg_temp.ok009(NOT EXISTS(SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(p.proacl) a WHERE p.oid='public.listar_candidatas_actividad(integer,integer,integer,integer)'::regprocedure AND a.grantee=0 AND a.privilege_type='EXECUTE'),'sin EXECUTE PUBLIC');
 PERFORM pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('otro'),i,t),'42501','actor ajeno');
 PERFORM pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',u,pg_temp.id009('otra_inscripcion'),t),'42501','inscripcion ajena');
 PERFORM pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s,%s)',u,i,pg_temp.id009('otro_tema'),ref),'42501','referencia otro tema');
 PERFORM pg_temp.error009('SELECT * FROM listar_candidatas_actividad(NULL,1,1)','22023','actor nulo');
 PERFORM pg_temp.error009('SELECT * FROM listar_candidatas_actividad(1,NULL,1)','22023','inscripcion nula');
 PERFORM pg_temp.error009('SELECT * FROM listar_candidatas_actividad(1,1,0)','22023','tema invalido');
 PERFORM pg_temp.error009('SELECT * FROM listar_candidatas_actividad(1,1,1,0)','22023','referencia invalida');
 PERFORM pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,2147483647)',u,i),'P0002','tema inexistente');
END;
$$;
RESET ROLE;
SELECT pg_temp.error009(format('UPDATE actividades SET dificultad=''FACIL'' WHERE id=%s',pg_temp.id009('baja')),'23514','nivel desconocido');
SELECT pg_temp.error009(format('UPDATE actividades SET dificultad=''ALTA'' WHERE id=%s',pg_temp.id009('referencia')),'55000','reclasificacion con intentos');
SELECT pg_temp.error009(format('UPDATE actividades SET dificultad=NULL WHERE id=%s',pg_temp.id009('referencia')),'55000','borrar nivel con intentos');
UPDATE actividades SET dificultad='ALTA' WHERE id=pg_temp.id009('media');
UPDATE actividades SET dificultad='MEDIA' WHERE id=pg_temp.id009('media');
SELECT pg_temp.ok009((SELECT dificultad='MEDIA' FROM actividades WHERE id=pg_temp.id009('media')),'editable sin intentos');
UPDATE intentos SET iniciado_en=now()-interval '2 hours',vence_en=now()-interval '1 hour' WHERE id=pg_temp.id009('intento_abierto');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.ok009(NOT EXISTS(SELECT 1 FROM listar_candidatas_actividad(pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema'),pg_temp.id009('referencia')) WHERE actividad_id=pg_temp.id009('abierta')),'intento vencido abierto no es candidato');
RESET ROLE;
-- Revocacion de cuenta, rol y contexto academico.
UPDATE usuarios SET activo=FALSE WHERE id=pg_temp.id009('estudiante');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema')),'42501','cuenta inactiva');
RESET ROLE;
UPDATE usuarios SET activo=TRUE WHERE id=pg_temp.id009('estudiante');
UPDATE usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=pg_temp.id009('estudiante');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema')),'42501','rol inactivo');
RESET ROLE;
UPDATE usuario_roles SET activo=TRUE,desactivado_en=NULL WHERE usuario_id=pg_temp.id009('estudiante');
UPDATE inscripciones SET estado='RETIRADA',cerrado_en=clock_timestamp() WHERE id=pg_temp.id009('inscripcion');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema')),'42501','inscripcion retirada');
RESET ROLE;
UPDATE inscripciones SET estado='ACTIVA',cerrado_en=NULL WHERE id=pg_temp.id009('inscripcion');
UPDATE cursos SET estado='ARCHIVADO' WHERE id=pg_temp.id009('curso');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema')),'42501','curso archivado');
RESET ROLE;
UPDATE cursos SET estado='ACTIVO' WHERE id=pg_temp.id009('curso');
UPDATE modulos SET estado='BORRADOR' WHERE id=pg_temp.id009('modulo');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error009(format('SELECT * FROM listar_candidatas_actividad(%s,%s,%s)',pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema')),'P0002','padre oculto');
RESET ROLE;
UPDATE modulos SET estado='PUBLICADO' WHERE id=pg_temp.id009('modulo');
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE it INTEGER; u INTEGER:=pg_temp.id009('estudiante'); i INTEGER:=pg_temp.id009('inscripcion');
BEGIN
 it:=iniciar_intento(pg_temp.id009('sin_nivel'),i,u);
 PERFORM entregar_intento(it,u);PERFORM calificar_intento(it);
 PERFORM pg_temp.ok009((SELECT count(*)=0 FROM listar_candidatas_actividad(u,i,pg_temp.id009('tema'))),'ultimo sin clasificar no reemplazado por referencia vieja');
END;
$$;
RESET ROLE;
-- Clasificacion inicial explicita de contenido heredado permitida una sola vez.
UPDATE actividades SET dificultad='BAJA' WHERE id=pg_temp.id009('sin_nivel');
SELECT pg_temp.error009(format('UPDATE actividades SET dificultad=''MEDIA'' WHERE id=%s',pg_temp.id009('sin_nivel')),'55000','primera clasificacion unica con historial');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.ok009((SELECT bool_and(dificultad_referencia='BAJA') FROM listar_candidatas_actividad(pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema'))),'primera clasificacion habilita referencia');
RESET ROLE;
UPDATE actividades SET estado='ARCHIVADO' WHERE seccion_id=pg_temp.id009('seccion') AND tema_id=pg_temp.id009('tema');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.ok009((SELECT count(*)=0 FROM listar_candidatas_actividad(pg_temp.id009('estudiante'),pg_temp.id009('inscripcion'),pg_temp.id009('tema'),pg_temp.id009('referencia'))),'sin candidatas lista vacia');
RESET ROLE;
DO $$ BEGIN RAISE NOTICE 'PRUEBAS 009 COMPLETADAS.'; END; $$;
ROLLBACK;
