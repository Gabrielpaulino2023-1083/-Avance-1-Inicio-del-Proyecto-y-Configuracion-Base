\set ON_ERROR_STOP on
\encoding UTF8
-- Fixtures propios. Como postgres, sin transaccion abierta. Revierte filas al final.
BEGIN;
SET LOCAL search_path=pg_catalog,public,pg_temp;
CREATE TEMP TABLE contexto010(k TEXT PRIMARY KEY,v INTEGER NOT NULL) ON COMMIT DROP;
GRANT SELECT,INSERT,UPDATE ON contexto010 TO plataforma_backend;
CREATE FUNCTION pg_temp.id010(x TEXT) RETURNS INTEGER LANGUAGE sql AS 'SELECT v FROM pg_temp.contexto010 WHERE k=x';
CREATE FUNCTION pg_temp.ok010(b BOOLEAN,m TEXT) RETURNS VOID LANGUAGE plpgsql AS $$ BEGIN
 IF b IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'FALLO 010: %',m; END IF; RAISE NOTICE 'OK 010: %',m; END; $$;
CREATE FUNCTION pg_temp.error010(q TEXT,c TEXT,m TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE actual TEXT;
BEGIN BEGIN EXECUTE q; EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS actual=RETURNED_SQLSTATE; END;
 PERFORM pg_temp.ok010(actual IS NOT DISTINCT FROM c,m||' esperado '||c||', recibido '||coalesce(actual,'sin error'));
END; $$;
INSERT INTO roles(codigo,nombre) VALUES('ADMINISTRADOR','Administrador'),('DOCENTE','Docente'),('ESTUDIANTE','Estudiante') ON CONFLICT(codigo) DO NOTHING;
DO $$
DECLARE x INTEGER; ad INTEGER; doc INTEGER; stu INTEGER; c INTEGER; e INTEGER; s INTEGER; m INTEGER; t INTEGER; k TEXT;
BEGIN
 FOREACH k IN ARRAY ARRAY['admin','docente','estudiante','otro'] LOOP
  INSERT INTO usuarios(nombre,apellido,email,password_hash) VALUES(k,'QA010','qa010-'||k||'-'||txid_current()||'@example.com','FICTICIO_NO_LOGIN') RETURNING id INTO x;
  INSERT INTO contexto010 VALUES(k,x);
  INSERT INTO usuario_roles(usuario_id,rol_id,asignado_por) SELECT x,id,x FROM roles WHERE codigo=CASE k WHEN 'admin' THEN 'ADMINISTRADOR' WHEN 'estudiante' THEN 'ESTUDIANTE' ELSE 'DOCENTE' END;
 END LOOP;
 ad:=pg_temp.id010('admin');doc:=pg_temp.id010('docente');stu:=pg_temp.id010('estudiante');
 INSERT INTO cursos(codigo,nombre,descripcion,estado,creado_por) VALUES('QA010-'||txid_current(),'Pruebas010','Fixture','ACTIVO',ad) RETURNING id INTO c;
 INSERT INTO contexto010 VALUES('curso',c);
 INSERT INTO ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,inscripcion_desde,inscripcion_hasta,estado,creado_por)
 VALUES(c,'E','E',now()-interval '1 day',now()+interval '1 year',now()-interval '1 day',now()+interval '1 month','ABIERTA',ad) RETURNING id INTO e;
 INSERT INTO contexto010 VALUES('edicion',e);
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por) VALUES(e,'S',10,'ABIERTA',ad) RETURNING id INTO s;
 INSERT INTO contexto010 VALUES('seccion',s);
 INSERT INTO seccion_docentes(seccion_id,usuario_id,asignado_por) VALUES(s,doc,ad);
 INSERT INTO secciones(edicion_id,codigo,cupo_maximo,estado,creado_por) VALUES(e,'AJENA',10,'ABIERTA',ad) RETURNING id INTO x;
 INSERT INTO contexto010 VALUES('seccion_ajena',x);
 INSERT INTO curso_editores(curso_id,usuario_id,asignado_por) VALUES(c,doc,ad),(c,pg_temp.id010('otro'),ad);
 INSERT INTO modulos(curso_id,nombre,descripcion,orden,estado,creado_por) VALUES(c,'M','M',1,'PUBLICADO',ad) RETURNING id INTO m;
 INSERT INTO contexto010 VALUES('modulo',m);
 INSERT INTO temas(modulo_id,nombre,descripcion,orden,estado,creado_por) VALUES(m,'T','T',1,'PUBLICADO',ad) RETURNING id INTO t;
 INSERT INTO contexto010 VALUES('tema',t);
 SELECT id INTO x FROM inscribir_estudiante(s,stu,stu);
 INSERT INTO contexto010 VALUES('inscripcion',x);
END; $$;
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE ad INTEGER:=pg_temp.id010('admin');d INTEGER:=pg_temp.id010('docente');u INTEGER:=pg_temp.id010('estudiante');s INTEGER:=pg_temp.id010('seccion');t INTEGER:=pg_temp.id010('tema');
 a public.actividades; b public.actividades; q public.preguntas; q2 public.preguntas; o public.opciones_respuestas; o2 public.opciones_respuestas;
 n INTEGER; it INTEGER; x INTEGER; keys INTEGER[]; r RECORD; ids INTEGER[];
BEGIN
 PERFORM pg_temp.ok010(current_user='plataforma_backend','rol de pruebas limitado');
 PERFORM pg_temp.ok010(NOT has_table_privilege(current_user,'public.actividades','INSERT') AND NOT has_table_privilege(current_user,'public.preguntas','UPDATE') AND NOT has_column_privilege(current_user,'public.opciones_respuestas','es_correcta','SELECT'),'sin escritura directa ni lectura directa de claves');
 PERFORM pg_temp.ok010(NOT has_function_privilege(current_user,'public.g010_contexto(integer,integer,integer,boolean)','EXECUTE'),'auxiliar privado');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',3,30,now(),NULL)',u,s,t),'42501','estudiante no crea');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',3,30,now(),NULL)',pg_temp.id010('otro'),s,t),'42501','editor sin asignacion de seccion no crea');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',3,30,now(),NULL)',d,pg_temp.id010('seccion_ajena'),t),'42501','docente no usa seccion ajena');
 -- Datos y claves editoriales de otros contextos.
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',0,30,now(),NULL)',d,s,t),'22023','maximo de intentos positivo');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',3,30,now(),now()-interval ''1 day'')',d,s,t),'22023','ventana de disponibilidad');
 a:=crear_actividad(d,s,t,' A ',' Instrucciones ','PRACTICA',NULL,3,30,now()-interval '1 minute',now()+interval '1 day');
 INSERT INTO contexto010 VALUES('actividad',a.id);
 PERFORM pg_temp.ok010(a.estado='BORRADOR' AND a.titulo='A' AND a.creado_por=d,'creacion docente en borrador y autoria');
 PERFORM pg_temp.ok010((SELECT count(*)=1 FROM listar_actividades_gestion(d,s,t)),'listar actividades propias');
 PERFORM pg_temp.ok010((obtener_actividad_gestion(ad,a.id)).id=a.id,'administrador consulta');
 PERFORM pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,%s)',u,a.id),'42501','estudiante no consulta editorial');
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','publicar sin nivel');
 a:=actualizar_actividad(d,a.id,'A actualizada','I','PRACTICA','MEDIA',3,30,a.disponible_desde,a.disponible_hasta);
 PERFORM pg_temp.ok010(a.titulo='A actualizada' AND a.dificultad='MEDIA','actualizar borrador');
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','publicar sin preguntas');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_pregunta(%s,%s,''P'',''SELECCION_UNICA'',1,0.001,NULL)',d,a.id),'22023','puntaje redondeado a cero');
 q:=crear_pregunta(d,a.id,'Pregunta','SELECCION_UNICA',1,10,NULL);
 PERFORM pg_temp.ok010(q.actividad_id=a.id,'crear pregunta');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_pregunta(%s,%s,''Duplicada'',''SELECCION_UNICA'',1,10,NULL)',d,a.id),'23505','orden duplicado pregunta');
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','publicacion sin opciones');
 o:=crear_opcion_respuesta(d,q.id,'Correcta',1,TRUE);
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','opcion insuficiente');
 o2:=crear_opcion_respuesta(d,q.id,'Incorrecta',2,FALSE);
 PERFORM pg_temp.error010(format('SELECT * FROM crear_opcion_respuesta(%s,%s,''Dup'',1,FALSE)',d,q.id),'23505','orden duplicado opcion');
 PERFORM pg_temp.ok010((obtener_opcion_gestion(d,o.id)).es_correcta AND (obtener_pregunta_gestion(d,q.id)).id=q.id,'lectura editorial autorizada con clave');
 PERFORM pg_temp.error010(format('SELECT * FROM listar_opciones_gestion(%s,%s)',u,q.id),'42501','estudiante no ve clave editorial');
 PERFORM pg_temp.ok010((SELECT count(*)=2 FROM reordenar_opciones(d,q.id,ARRAY[o2.id,o.id])),'reordenacion opciones sin colision');
 PERFORM pg_temp.ok010((obtener_opcion_gestion(d,o.id)).orden=2,'opcion correcta reordenada');
 PERFORM pg_temp.error010(format('SELECT * FROM reordenar_opciones(%s,%s,ARRAY[%s,%s])',d,q.id,o.id,o.id),'22023','permutacion repetida');
 PERFORM pg_temp.error010(format('SELECT * FROM reordenar_opciones(%s,%s,ARRAY[%s])',d,q.id,o.id),'22023','permutacion incompleta');
 o2:=actualizar_opcion_respuesta(d,o2.id,'Incorrecta editada',1,FALSE);
 PERFORM pg_temp.ok010(o2.texto='Incorrecta editada' AND o2.orden=1,'actualizar opcion');
 q2:=crear_pregunta(d,a.id,'Segunda','SELECCION_MULTIPLE',2,10,'Explicacion');
 PERFORM crear_opcion_respuesta(d,q2.id,'A',1,TRUE); PERFORM crear_opcion_respuesta(d,q2.id,'B',2,FALSE);
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','multiple requiere dos correctas');
 SELECT * INTO o2 FROM listar_opciones_gestion(d,q2.id) WHERE orden=2;
 PERFORM actualizar_opcion_respuesta(d,o2.id,'B',2,TRUE);
 PERFORM pg_temp.ok010((SELECT count(*)=2 FROM reordenar_preguntas(d,a.id,ARRAY[q2.id,q.id])),'reordenar preguntas');
 PERFORM pg_temp.ok010((obtener_pregunta_gestion(d,q.id)).orden=2,'nuevo orden pregunta');
 PERFORM actualizar_pregunta(d,q.id,'Pregunta editada','SELECCION_UNICA',2,10,'E');
 -- Suma fuera del NUMERIC(10,2) de intentos; no deja publicacion parcial.
 PERFORM actualizar_pregunta(d,q.id,'Grande','SELECCION_UNICA',2,99999999.99,NULL);
 PERFORM pg_temp.error010(format('SELECT * FROM publicar_actividad(%s,%s)',d,a.id),'55000','puntaje total excesivo');
 PERFORM pg_temp.ok010((obtener_actividad_gestion(d,a.id)).estado='BORRADOR','publicacion fallida no cambia estado');
 PERFORM actualizar_pregunta(d,q.id,'Pregunta editada','SELECCION_UNICA',2,10,'E');
 PERFORM pg_temp.error010(format('SELECT * FROM reordenar_preguntas(%s,%s,ARRAY[2147483647,%s])',d,a.id,q.id),'22023','permutacion con ID ajeno');
 a:=publicar_actividad(d,a.id);
 PERFORM pg_temp.ok010(a.estado='PUBLICADO','publicacion valida');
 PERFORM pg_temp.error010(format('SELECT * FROM actualizar_pregunta(%s,%s,''X'',''SELECCION_UNICA'',2,10,NULL)',d,q.id),'55000','pregunta publicada inmutable');
 PERFORM pg_temp.error010(format('SELECT * FROM actualizar_actividad(%s,%s,''X'',''I'',''PRACTICA'',''MEDIA'',3,30,now(),NULL)',d,a.id),'55000','configuracion publicada no editable por API');
 PERFORM pg_temp.error010(format('SELECT eliminar_actividad(%s,%s)',d,a.id),'55000','no eliminar publicada');
 a:=cambiar_estado_actividad(d,a.id,'BORRADOR');
 PERFORM pg_temp.ok010(a.estado='BORRADOR','volver borrador sin historial');
 PERFORM publicar_actividad(d,a.id);
 it:=iniciar_intento(a.id,pg_temp.id010('inscripcion'),u);
 INSERT INTO contexto010 VALUES('intento',it);
 PERFORM pg_temp.ok010((SELECT count(*)=2 FROM obtener_cuestionario_estudiante(u,it)),'compatible con 007');
 FOR r IN SELECT * FROM obtener_cuestionario_estudiante(u,it) LOOP
  PERFORM pg_temp.ok010(NOT jsonb_path_exists(r.opciones,'$[*].es_correcta'),'cuestionario no expone claves');
  -- Claves solo mediante lectura editorial autorizada; no SELECT es_correcta directo.
  SELECT array_agg(id) INTO keys FROM listar_opciones_gestion(d,r.pregunta_id) WHERE es_correcta;
  PERFORM guardar_opciones_respuesta(r.respuesta_id,u,keys);
 END LOOP;
 PERFORM pg_temp.error010(format('SELECT * FROM cambiar_estado_actividad(%s,%s,''ARCHIVADO'')',d,a.id),'55000','no archivar con intento abierto');
 PERFORM entregar_intento(it,u);PERFORM calificar_intento(it);
 PERFORM pg_temp.ok010((SELECT estado='CALIFICADO' AND puntaje_obtenido=20 AND puntaje_maximo=20 FROM intentos WHERE id=it),'calificacion real 20/20');
 PERFORM pg_temp.error010(format('SELECT * FROM cambiar_estado_actividad(%s,%s,''BORRADOR'')',d,a.id),'55000','historial no vuelve a borrador');
 a:=cambiar_estado_actividad(d,a.id,'ARCHIVADO');
 PERFORM pg_temp.ok010(a.estado='ARCHIVADO','archivar conserva historial');
 PERFORM pg_temp.error010(format('SELECT * FROM duplicar_actividad(%s,%s,%s,%s,''Ajena'',now(),NULL)',d,a.id,pg_temp.id010('seccion_ajena'),t),'42501','copia valida permisos de destino');
 b:=duplicar_actividad(d,a.id,s,t,'Copia',now()-interval '1 minute',now()+interval '1 day');
 INSERT INTO contexto010 VALUES('copia',b.id);
 PERFORM pg_temp.ok010(b.id<>a.id AND b.estado='BORRADOR' AND NOT EXISTS(SELECT 1 FROM intentos WHERE actividad_id=b.id),'duplicacion sin intentos');
 PERFORM pg_temp.ok010((SELECT count(*)=2 FROM listar_preguntas_gestion(d,b.id)),'copia de preguntas');
 SELECT id INTO x FROM listar_preguntas_gestion(d,b.id) WHERE orden=2;
 PERFORM pg_temp.ok010(x<>q.id AND (SELECT count(*)=2 FROM listar_opciones_gestion(d,x)),'IDs nuevos y opciones copiadas');
 PERFORM eliminar_opcion_respuesta(d,(SELECT id FROM listar_opciones_gestion(d,x) ORDER BY id LIMIT 1));
 PERFORM pg_temp.ok010((SELECT count(*)=1 FROM listar_opciones_gestion(d,x)),'eliminar opcion borrador');
 PERFORM eliminar_pregunta(d,x);
 PERFORM pg_temp.ok010((SELECT count(*)=1 FROM listar_preguntas_gestion(d,b.id)),'eliminar pregunta y opciones');
 PERFORM eliminar_actividad(d,b.id);
 PERFORM pg_temp.ok010(NOT EXISTS(SELECT 1 FROM actividades WHERE id=b.id) AND NOT EXISTS(SELECT 1 FROM preguntas WHERE actividad_id=b.id),'borrado completo de borrador');
 a:=cambiar_estado_actividad(d,a.id,'PUBLICADO');
 PERFORM pg_temp.ok010(a.estado='PUBLICADO' AND (SELECT puntaje_obtenido=20 FROM intentos WHERE id=it),'republicar conserva nota');
 b:=crear_actividad(ad,pg_temp.id010('seccion_ajena'),t,'Admin','I','EVALUACION','ALTA',NULL,NULL,now(),NULL);
 PERFORM pg_temp.ok010(b.creado_por=ad,'admin no necesita asignacion docente');
 PERFORM eliminar_actividad(ad,b.id);
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''INVALIDA'',3,30,now(),NULL)',d,s,t),'22023','dificultad invalida');
 PERFORM pg_temp.error010(format('SELECT * FROM crear_actividad(%s,%s,%s,''A'',''I'',''PRACTICA'',''BAJA'',3,30,''infinity'',NULL)',d,s,t),'22023','fecha infinita rechazada');
 PERFORM pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,0)',d),'22023','ID no positivo');
 PERFORM pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,2147483647)',d),'P0002','actividad inexistente');
END; $$;
RESET ROLE;
-- Revocaciones y estado del contexto, sin destruir fixtures.
UPDATE seccion_docentes SET activo=FALSE WHERE usuario_id=pg_temp.id010('docente');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,%s)',pg_temp.id010('docente'),pg_temp.id010('actividad')),'42501','asignacion revocada');
RESET ROLE;
UPDATE seccion_docentes SET activo=TRUE WHERE usuario_id=pg_temp.id010('docente');
UPDATE curso_editores SET activo=FALSE WHERE usuario_id=pg_temp.id010('docente');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,%s)',pg_temp.id010('docente'),pg_temp.id010('actividad')),'42501','editor revocado');
RESET ROLE;
UPDATE curso_editores SET activo=TRUE WHERE usuario_id=pg_temp.id010('docente');
UPDATE usuarios SET activo=FALSE WHERE id=pg_temp.id010('docente');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,%s)',pg_temp.id010('docente'),pg_temp.id010('actividad')),'42501','cuenta inactiva');
RESET ROLE;
UPDATE usuarios SET activo=TRUE WHERE id=pg_temp.id010('docente');
UPDATE usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=pg_temp.id010('docente');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error010(format('SELECT * FROM obtener_actividad_gestion(%s,%s)',pg_temp.id010('docente'),pg_temp.id010('actividad')),'42501','rol inactivo');
RESET ROLE;
UPDATE usuario_roles SET activo=TRUE,desactivado_en=NULL WHERE usuario_id=pg_temp.id010('docente');
UPDATE cursos SET estado='ARCHIVADO' WHERE id=pg_temp.id010('curso');
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.error010(format('SELECT * FROM cambiar_estado_actividad(%s,%s,''ARCHIVADO'')',pg_temp.id010('docente'),pg_temp.id010('actividad')),'55000','curso archivado no se escribe');
SELECT pg_temp.ok010((obtener_actividad_gestion(pg_temp.id010('docente'),pg_temp.id010('actividad'))).id=pg_temp.id010('actividad'),'lectura editorial historica permitida');
RESET ROLE;
SELECT pg_temp.error010(format('DELETE FROM public.actividades WHERE id=%s',pg_temp.id010('actividad')),'55000','trigger protege borrado directo');
DO $$ BEGIN RAISE NOTICE 'PRUEBAS 010 COMPLETADAS.'; END; $$;
ROLLBACK;
-- Contrato de aislamiento: la gestion no acepta snapshots largos.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL ROLE plataforma_backend;
DO $$ BEGIN
 BEGIN
  PERFORM crear_actividad(1,1,1,'A','I','PRACTICA','BAJA',3,30,now(),NULL);
  RAISE EXCEPTION 'FALLO 010: se acepto REPEATABLE READ';
 EXCEPTION WHEN SQLSTATE '25000' THEN RAISE NOTICE 'OK 010: REPEATABLE READ rechazado';
 END;
END; $$;
ROLLBACK;
