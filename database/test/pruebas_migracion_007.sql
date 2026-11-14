\set ON_ERROR_STOP on
\encoding UTF8
-- Ejecutar como postgres, sin transaccion abierta, despues de 007. Sin seeds.
-- Datos ficticios temporales: no crea cuentas de login utilizables. ROLLBACK final.
-- Las secuencias pueden avanzar aunque los datos se reviertan.
BEGIN;
SET LOCAL search_path=pg_catalog, public, pg_temp;
CREATE TEMP TABLE contexto_007 (clave TEXT PRIMARY KEY, id INTEGER NOT NULL);
CREATE FUNCTION pg_temp.id007(p_clave TEXT) RETURNS INTEGER LANGUAGE sql STABLE AS
' SELECT id FROM pg_temp.contexto_007 WHERE clave=p_clave ';
CREATE FUNCTION pg_temp.ok007(p_ok BOOLEAN,p_mensaje TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_ok IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'FALLO 007: %',p_mensaje; END IF;
    RAISE NOTICE 'OK 007: %',p_mensaje;
END;
$$;
CREATE FUNCTION pg_temp.error007(p_sql TEXT,p_estado TEXT,p_mensaje TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE recibido TEXT;
BEGIN
    BEGIN EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS recibido=RETURNED_SQLSTATE; END;
    PERFORM pg_temp.ok007(recibido IS NOT DISTINCT FROM p_estado,
        p_mensaje||' (esperado '||p_estado||', recibido '||COALESCE(recibido,'sin error')||')');
END;
$$;
INSERT INTO public.roles(codigo,nombre) VALUES
('ADMINISTRADOR','Administrador'),('DOCENTE','Docente'),('ESTUDIANTE','Estudiante')
ON CONFLICT(codigo) DO NOTHING;
DO $$
DECLARE v_id INTEGER; v_admin INTEGER; v_curso INTEGER; v_ed INTEGER; v_s INTEGER;
        v_mod INTEGER; v_t INTEGER; v_a INTEGER; v_q INTEGER; v_r RECORD; v_nombre TEXT;
BEGIN
    FOREACH v_nombre IN ARRAY ARRAY['admin','docente','estudiante','otro','sin_inscripcion'] LOOP
        INSERT INTO public.usuarios(nombre,apellido,email,password_hash)
        VALUES(v_nombre,'Prueba007','test007-'||v_nombre||'-'||txid_current()||'@example.com','NO_ES_UN_HASH_DE_LOGIN')
        RETURNING id INTO v_id;
        INSERT INTO contexto_007 VALUES(v_nombre,v_id);
    END LOOP;
    v_admin:=pg_temp.id007('admin');
    FOR v_r IN SELECT * FROM contexto_007 LOOP
        INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por)
        SELECT v_r.id,r.id,v_admin FROM public.roles r
        WHERE r.codigo=CASE v_r.clave WHEN 'admin' THEN 'ADMINISTRADOR' WHEN 'docente' THEN 'DOCENTE' ELSE 'ESTUDIANTE' END;
    END LOOP;
    FOREACH v_nombre IN ARRAY ARRAY['curso','curso_ajeno'] LOOP
        INSERT INTO public.cursos(codigo,nombre,descripcion,estado,creado_por)
        VALUES('TEST007-'||v_nombre||'-'||txid_current(),v_nombre,'Prueba','ACTIVO',v_admin) RETURNING id INTO v_id;
        INSERT INTO contexto_007 VALUES(v_nombre,v_id);
    END LOOP;
    v_curso:=pg_temp.id007('curso');
    FOREACH v_nombre IN ARRAY ARRAY['edicion','edicion2'] LOOP
        INSERT INTO public.ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,
            inscripcion_desde,inscripcion_hasta,estado,creado_por)
        VALUES(v_curso,v_nombre,v_nombre,now()-interval '1 day',now()+interval '1 year',
            now()-interval '2 days',now()+interval '1 month','EN_CURSO',v_admin) RETURNING id INTO v_ed;
        INSERT INTO contexto_007 VALUES(v_nombre,v_ed);
    END LOOP;
    FOREACH v_nombre IN ARRAY ARRAY['seccion','otra_seccion','seccion_edicion2'] LOOP
        v_ed:=pg_temp.id007(CASE WHEN v_nombre='seccion_edicion2' THEN 'edicion2' ELSE 'edicion' END);
        INSERT INTO public.secciones(edicion_id,codigo,cupo_maximo,estado,creado_por)
        VALUES(v_ed,v_nombre,10,'ABIERTA',v_admin) RETURNING id INTO v_s;
        INSERT INTO contexto_007 VALUES(v_nombre,v_s);
        INSERT INTO public.inscripciones(estudiante_id,edicion_id,seccion_id,origen,registrado_por)
        VALUES(pg_temp.id007(CASE WHEN v_nombre='otra_seccion' THEN 'otro' ELSE 'estudiante' END),v_ed,v_s,'ADMINISTRATIVA',v_admin)
        RETURNING id INTO v_id;
        INSERT INTO contexto_007 VALUES('inscripcion_'||v_nombre,v_id);
    END LOOP;
    FOREACH v_nombre IN ARRAY ARRAY['modulo','modulo_vacio','modulo_borrador','modulo_archivado'] LOOP
        INSERT INTO public.modulos(curso_id,nombre,descripcion,orden,estado,creado_por)
        VALUES(v_curso,v_nombre,'Prueba',(SELECT COUNT(*)+1 FROM public.modulos WHERE curso_id=v_curso),
            CASE v_nombre WHEN 'modulo_borrador' THEN 'BORRADOR' WHEN 'modulo_archivado' THEN 'ARCHIVADO' ELSE 'PUBLICADO' END,v_admin)
        RETURNING id INTO v_mod;
        INSERT INTO contexto_007 VALUES(v_nombre,v_mod);
    END LOOP;
    FOREACH v_nombre IN ARRAY ARRAY['tema','tema_vacio','tema_borrador','tema_archivado','tema_padre_oculto'] LOOP
        v_mod:=pg_temp.id007(CASE WHEN v_nombre='tema_padre_oculto' THEN 'modulo_borrador' ELSE 'modulo' END);
        INSERT INTO public.temas(modulo_id,nombre,descripcion,orden,estado,creado_por)
        VALUES(v_mod,v_nombre,'Prueba',(SELECT COUNT(*)+1 FROM public.temas WHERE modulo_id=v_mod),
            CASE v_nombre WHEN 'tema_borrador' THEN 'BORRADOR' WHEN 'tema_archivado' THEN 'ARCHIVADO' ELSE 'PUBLICADO' END,v_admin)
        RETURNING id INTO v_t;
        INSERT INTO contexto_007 VALUES(v_nombre,v_t);
    END LOOP;
    FOREACH v_nombre IN ARRAY ARRAY['actividad','futura','cerrada','actividad_otra_seccion','actividad_edicion2','actividad_borrador','actividad_archivada'] LOOP
        v_s:=pg_temp.id007(CASE v_nombre WHEN 'actividad_otra_seccion' THEN 'otra_seccion'
            WHEN 'actividad_edicion2' THEN 'seccion_edicion2' ELSE 'seccion' END);
        INSERT INTO public.actividades(seccion_id,tema_id,titulo,instrucciones,disponible_desde,disponible_hasta,creado_por)
        VALUES(v_s,pg_temp.id007('tema'),v_nombre,'Responde las preguntas.',
            CASE WHEN v_nombre='futura' THEN now()+interval '1 day' ELSE now()-interval '2 days' END,
            CASE WHEN v_nombre='cerrada' THEN now()-interval '1 day' ELSE now()+interval '2 days' END,v_admin)
        RETURNING id INTO v_a;
        INSERT INTO contexto_007 VALUES(v_nombre,v_a);
        INSERT INTO public.preguntas(actividad_id,enunciado,orden,puntaje_maximo,explicacion)
        VALUES(v_a,'Elige A',1,10,'EXPLICACION_NO_DEBE_SALIR') RETURNING id INTO v_q;
        INSERT INTO contexto_007 VALUES('pregunta_'||v_nombre,v_q);
        INSERT INTO public.opciones_respuestas(pregunta_id,texto,orden,es_correcta)
        VALUES(v_q,'A',1,TRUE),(v_q,'B',2,FALSE);
        IF v_nombre='actividad' THEN
            INSERT INTO public.preguntas(actividad_id,enunciado,tipo,orden,puntaje_maximo,explicacion)
            VALUES(v_a,'Elige numeros pares','SELECCION_MULTIPLE',2,10,'EXPLICACION_MULTIPLE_OCULTA') RETURNING id INTO v_q;
            INSERT INTO contexto_007 VALUES('pregunta_multiple',v_q);
            INSERT INTO public.opciones_respuestas(pregunta_id,texto,orden,es_correcta)
            VALUES(v_q,'2',1,TRUE),(v_q,'4',2,TRUE),(v_q,'5',3,FALSE);
        END IF;
        IF v_nombre<>'actividad_borrador' THEN
            UPDATE public.actividades SET estado='PUBLICADO' WHERE id=v_a;
            IF v_nombre='actividad_archivada' THEN UPDATE public.actividades SET estado='ARCHIVADO' WHERE id=v_a; END IF;
        END IF;
    END LOOP;
END;
$$;
GRANT SELECT,INSERT,UPDATE ON contexto_007 TO plataforma_backend;
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.ok007((current_user='plataforma_backend'),'pruebas ejecutadas como backend');

SELECT pg_temp.ok007((has_function_privilege(current_user,'public.listar_modulos_publicados_estudiante(integer,integer)','EXECUTE')),'EXECUTE listar_modulos_publicados_estudiante(integer,integer)');

SELECT pg_temp.ok007((has_function_privilege(current_user,'public.listar_temas_publicados_estudiante(integer,integer)','EXECUTE')),'EXECUTE listar_temas_publicados_estudiante(integer,integer)');

SELECT pg_temp.ok007((has_function_privilege(current_user,'public.listar_actividades_publicadas_estudiante(integer,integer,integer)','EXECUTE')),'EXECUTE listar_actividades_publicadas_estudiante(integer,integer,integer)');

SELECT pg_temp.ok007((has_function_privilege(current_user,'public.obtener_cuestionario_estudiante(integer,integer)','EXECUTE')),'EXECUTE obtener_cuestionario_estudiante(integer,integer)');

SELECT pg_temp.ok007((NOT has_function_privilege(current_user,'public.validar_lectura_estudiante(integer,integer,integer)','EXECUTE')),'helper privado');

SELECT pg_temp.ok007((NOT has_column_privilege(current_user,'public.opciones_respuestas','es_correcta','SELECT')),'sin lectura directa de es_correcta');

SELECT pg_temp.ok007((NOT has_table_privilege(current_user,'public.modulos','INSERT') AND NOT has_table_privilege(current_user,'public.temas','DELETE')),'sin nuevas escrituras directas');

SELECT pg_temp.ok007(((SELECT COUNT(*)=5 AND bool_and(p.prosecdef AND p.provolatile='s' AND pg_get_userbyid(p.proowner)='plataforma_operaciones' AND p.proconfig @> ARRAY['search_path=pg_catalog, public, pg_temp']) FROM pg_proc p WHERE p.oid IN ('public.validar_lectura_estudiante(integer,integer,integer)'::regprocedure,'public.listar_modulos_publicados_estudiante(integer,integer)'::regprocedure,'public.listar_temas_publicados_estudiante(integer,integer)'::regprocedure,'public.listar_actividades_publicadas_estudiante(integer,integer,integer)'::regprocedure,'public.obtener_cuestionario_estudiante(integer,integer)'::regprocedure))),'propietario, snapshot y search_path');

SELECT pg_temp.ok007((NOT EXISTS(SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) acl WHERE p.oid IN ('public.validar_lectura_estudiante(integer,integer,integer)'::regprocedure,'public.listar_modulos_publicados_estudiante(integer,integer)'::regprocedure,'public.listar_temas_publicados_estudiante(integer,integer)'::regprocedure,'public.listar_actividades_publicadas_estudiante(integer,integer,integer)'::regprocedure,'public.obtener_cuestionario_estudiante(integer,integer)'::regprocedure) AND acl.grantee=0 AND acl.privilege_type='EXECUTE')),'sin EXECUTE a PUBLIC');

SELECT pg_temp.ok007((SELECT COUNT(*)=2 AND bool_and(estado='PUBLICADO') FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso'))),'solo modulos publicados sin duplicar por dos inscripciones');

SELECT pg_temp.ok007((SELECT total_temas=2 FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso')) WHERE id=pg_temp.id007('modulo')),'contador excluye borradores y archivados');

SELECT pg_temp.ok007((SELECT total_temas=0 FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso')) WHERE id=pg_temp.id007('modulo_vacio')),'modulo publicado sin temas');

SELECT pg_temp.ok007((SELECT COUNT(*)=2 AND bool_and(estado='PUBLICADO') FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo'))),'solo temas publicados');

SELECT pg_temp.ok007((SELECT COUNT(*)=0 FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo_vacio'))),'lista vacia valida');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('sin_inscripcion'),pg_temp.id007('curso'))$caso$,'42501','rechazo sin_inscripcion');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('admin'),pg_temp.id007('curso'))$caso$,'42501','rechazo admin');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('docente'),pg_temp.id007('curso'))$caso$,'42501','rechazo docente');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso_ajeno'))$caso$,'42501','curso ajeno');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_por_curso(pg_temp.id007('estudiante'),pg_temp.id007('curso'))$caso$,'42501','006 sigue siendo administrativa');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo_borrador'))$caso$,'P0002','padre no publicado modulo_borrador');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo_archivado'))$caso$,'P0002','padre no publicado modulo_archivado');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema_borrador'))$caso$,'P0002','tema oculto tema_borrador');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema_archivado'))$caso$,'P0002','tema oculto tema_archivado');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema_padre_oculto'))$caso$,'P0002','tema oculto tema_padre_oculto');

SELECT pg_temp.ok007((SELECT COUNT(*)=3 AND bool_and(seccion_id=pg_temp.id007('seccion')) FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))),'actividades limitadas a la seccion de inscripcion');

SELECT pg_temp.ok007((SELECT disponible_ahora FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema')) WHERE id=pg_temp.id007('actividad')),'ventana actual');

SELECT pg_temp.ok007((SELECT NOT disponible_ahora FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema')) WHERE id=pg_temp.id007('futura')),'metadatos visibles, ventana no disponible futura');

SELECT pg_temp.ok007((SELECT NOT disponible_ahora FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema')) WHERE id=pg_temp.id007('cerrada')),'metadatos visibles, ventana no disponible cerrada');

SELECT pg_temp.ok007((SELECT COUNT(*)=0 FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema_vacio'))),'tema sin actividades');

SELECT pg_temp.ok007((SELECT COUNT(*)=1 AND min(id)=pg_temp.id007('actividad_edicion2') FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion_edicion2'),pg_temp.id007('tema'))),'aislamiento entre ediciones del mismo estudiante');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_otra_seccion'),pg_temp.id007('tema'))$caso$,'42501','inscripcion de otro estudiante');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(NULL,1)$caso$,'22023','parametro invalido');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(1,0)$caso$,'22023','parametro invalido');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(1,NULL,1)$caso$,'22023','parametro invalido');

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(1,-1)$caso$,'22023','parametro invalido');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),2147483647)$caso$,'P0002','modulo inexistente');

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),2147483647)$caso$,'P0002','intento inexistente');

INSERT INTO contexto_007 SELECT 'intento',public.iniciar_intento(pg_temp.id007('actividad'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('estudiante'));

INSERT INTO contexto_007 SELECT 'intento_otro',public.iniciar_intento(pg_temp.id007('actividad_otra_seccion'),pg_temp.id007('inscripcion_otra_seccion'),pg_temp.id007('otro'));

SELECT pg_temp.ok007((SELECT COUNT(*)=2 AND bool_and(respuesta_id IS NOT NULL) FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))),'cuestionario y respuestas reales de iniciar_intento');

SELECT pg_temp.ok007((SELECT jsonb_array_length(opciones)=2 FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) WHERE orden=1),'opciones unica');

SELECT pg_temp.ok007((SELECT jsonb_array_length(opciones)=3 FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) WHERE orden=2),'opciones multiple');

SELECT pg_temp.ok007((SELECT bool_and(cardinality(opciones_seleccionadas)=0) FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))),'selecciones inicialmente vacias');

SELECT pg_temp.ok007((NOT EXISTS(SELECT 1 FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) q CROSS JOIN LATERAL jsonb_object_keys(to_jsonb(q)) k WHERE k NOT IN ('intento_id','actividad_id','instrucciones','vence_en','pregunta_id','respuesta_id','enunciado','tipo','orden','puntaje_maximo','opciones','opciones_seleccionadas'))),'lista cerrada de campos del cuestionario');

SELECT pg_temp.ok007((NOT EXISTS(SELECT 1 FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) q CROSS JOIN LATERAL jsonb_array_elements(q.opciones) o CROSS JOIN LATERAL jsonb_object_keys(o) k WHERE k NOT IN ('id','texto','orden'))),'opciones sin claves de correccion');

SELECT pg_temp.ok007((SELECT position('EXPLICACION_' IN jsonb_agg(to_jsonb(q))::TEXT)=0 FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) q),'no filtra explicaciones');

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento_otro'))$caso$,'42501','intento ajeno');

SELECT public.guardar_opciones_respuesta(q.respuesta_id,pg_temp.id007('estudiante'),ARRAY[(q.opciones->0->>'id')::INTEGER]) FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) q WHERE q.orden=1;

SELECT pg_temp.ok007((SELECT cardinality(opciones_seleccionadas)=1 AND opciones_seleccionadas[1]=(opciones->0->>'id')::INTEGER FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento')) WHERE orden=1),'recupera seleccion guardada propia');

RESET ROLE;
UPDATE public.usuarios SET activo=FALSE WHERE id=pg_temp.id007('estudiante');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','cuenta inactiva invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','cuenta inactiva invalida listado de actividades');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso'))$caso$,'42501','cuenta inactiva invalida listado de modulos');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo'))$caso$,'42501','cuenta inactiva invalida listado de temas');

RESET ROLE;
UPDATE public.usuarios SET activo=TRUE WHERE id=pg_temp.id007('estudiante');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=pg_temp.id007('estudiante');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','rol inactivo invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','rol inactivo invalida listado de actividades');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso'))$caso$,'42501','rol inactivo invalida listado de modulos');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo'))$caso$,'42501','rol inactivo invalida listado de temas');

RESET ROLE;
UPDATE public.usuario_roles SET activo=TRUE,desactivado_en=NULL WHERE usuario_id=pg_temp.id007('estudiante');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.cursos SET estado='ARCHIVADO' WHERE id=pg_temp.id007('curso');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','curso archivado invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','curso archivado invalida listado de actividades');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso'))$caso$,'42501','curso archivado invalida listado de modulos');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_temas_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('modulo'))$caso$,'42501','curso archivado invalida listado de temas');

RESET ROLE;
UPDATE public.cursos SET estado='ACTIVO' WHERE id=pg_temp.id007('curso');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.secciones SET estado='CANCELADA' WHERE id=pg_temp.id007('seccion');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','seccion cancelada invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','seccion cancelada invalida listado de actividades');

RESET ROLE;
UPDATE public.secciones SET estado='ABIERTA' WHERE id=pg_temp.id007('seccion');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.ediciones_curso SET estado='CANCELADA' WHERE id=pg_temp.id007('edicion');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','edicion cancelada invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','edicion cancelada invalida listado de actividades');

RESET ROLE;
UPDATE public.ediciones_curso SET estado='EN_CURSO' WHERE id=pg_temp.id007('edicion');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.inscripciones SET estado='RETIRADA',cerrado_en=clock_timestamp() WHERE id=pg_temp.id007('inscripcion_seccion');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'42501','inscripcion retirada invalida cuestionario');

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_actividades_publicadas_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('inscripcion_seccion'),pg_temp.id007('tema'))$caso$,'42501','inscripcion retirada invalida listado de actividades');

RESET ROLE;
UPDATE public.inscripciones SET estado='ACTIVA',cerrado_en=NULL WHERE id=pg_temp.id007('inscripcion_seccion');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.modulos SET estado='ARCHIVADO' WHERE id=pg_temp.id007('modulo');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'P0002','modulo archivado invalida cuestionario');

RESET ROLE;
UPDATE public.modulos SET estado='PUBLICADO' WHERE id=pg_temp.id007('modulo');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.temas SET estado='ARCHIVADO' WHERE id=pg_temp.id007('tema');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'P0002','tema archivado invalida cuestionario');

RESET ROLE;
UPDATE public.temas SET estado='PUBLICADO' WHERE id=pg_temp.id007('tema');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.actividades SET estado='ARCHIVADO' WHERE id=pg_temp.id007('actividad');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'P0002','actividad archivada invalida cuestionario');

RESET ROLE;
UPDATE public.actividades SET estado='PUBLICADO' WHERE id=pg_temp.id007('actividad');
SET LOCAL ROLE plataforma_backend;

RESET ROLE;
UPDATE public.inscripciones SET estado='RETIRADA',cerrado_en=clock_timestamp() WHERE estudiante_id=pg_temp.id007('estudiante');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.listar_modulos_publicados_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('curso'))$caso$,'42501','sin ninguna inscripcion activa');

RESET ROLE;
UPDATE public.inscripciones SET estado='ACTIVA',cerrado_en=NULL WHERE estudiante_id=pg_temp.id007('estudiante');

CREATE TEMP TABLE fechas_007 AS SELECT id,iniciado_en,vence_en FROM public.intentos WHERE id=pg_temp.id007('intento');
UPDATE public.intentos SET iniciado_en=now()-interval '2 hours',vence_en=now()-interval '1 hour' WHERE id=pg_temp.id007('intento');
SET LOCAL ROLE plataforma_backend;

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'55000','intento vencido');

RESET ROLE;
UPDATE public.intentos it SET iniciado_en=f.iniciado_en,vence_en=f.vence_en FROM fechas_007 f WHERE it.id=f.id;
SET LOCAL ROLE plataforma_backend;

SELECT public.entregar_intento(pg_temp.id007('intento'),pg_temp.id007('estudiante'));

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'55000','intento entregado');

SELECT public.calificar_intento(pg_temp.id007('intento'));

SELECT pg_temp.error007($caso$SELECT * FROM public.obtener_cuestionario_estudiante(pg_temp.id007('estudiante'),pg_temp.id007('intento'))$caso$,'55000','intento calificado');

RESET ROLE;
DO $$ BEGIN RAISE NOTICE 'PRUEBAS 007 COMPLETADAS: todos los casos incluidos pasaron.'; END; $$;
ROLLBACK;
