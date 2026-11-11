\set ON_ERROR_STOP on
\encoding UTF8
-- Ejecutar como postgres después de 006, sin transacción abierta. No depende de seeds.
BEGIN;
SET LOCAL search_path=pg_catalog, public, pg_temp;
CREATE TEMP TABLE contexto_006(admin_id INTEGER,docente_id INTEGER,estudiante_id INTEGER,curso_id INTEGER,otro_curso_id INTEGER,modulo_id INTEGER,tema_id INTEGER);
INSERT INTO public.roles(codigo,nombre) VALUES('ADMINISTRADOR','Administrador'),('DOCENTE','Docente'),('ESTUDIANTE','Estudiante') ON CONFLICT(codigo) DO NOTHING;
DO $$
DECLARE a INTEGER; d INTEGER; e INTEGER; c INTEGER; c2 INTEGER;
BEGIN
    INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES('Admin','006','a006-'||txid_current()||'@example.com','HASH_FICTICIO_NO_USAR') RETURNING id INTO a;
    INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES('Docente','006','d006-'||txid_current()||'@example.com','HASH_FICTICIO_NO_USAR') RETURNING id INTO d;
    INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES('Estudiante','006','e006-'||txid_current()||'@example.com','HASH_FICTICIO_NO_USAR') RETURNING id INTO e;
    INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) SELECT a,id,a FROM public.roles WHERE codigo='ADMINISTRADOR';
    INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) SELECT d,id,a FROM public.roles WHERE codigo='DOCENTE';
    INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) SELECT e,id,a FROM public.roles WHERE codigo='ESTUDIANTE';
    SELECT id INTO c FROM public.crear_curso_admin(a,'T006-'||txid_current(),'Curso 006','Prueba');
    SELECT id INTO c2 FROM public.crear_curso_admin(a,'T006-OTRO-'||txid_current(),'Otro curso','Prueba');
    INSERT INTO public.curso_editores(curso_id,usuario_id,asignado_por) VALUES(c,d,a);
    INSERT INTO contexto_006 VALUES(a,d,e,c,c2,NULL,NULL);
END;
$$;
GRANT SELECT,UPDATE ON contexto_006 TO plataforma_backend;
CREATE FUNCTION pg_temp.esperar_error_006(p_sql TEXT,p_estado TEXT) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE recibido TEXT;
BEGIN
    BEGIN EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS recibido=RETURNED_SQLSTATE; END;
    IF recibido IS DISTINCT FROM p_estado THEN
        RAISE EXCEPTION 'FALLO: SQLSTATE esperado %, recibido %, SQL %',p_estado,recibido,p_sql;
    END IF;
END;
$$;
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE c RECORD; m RECORD; t RECORD; n BIGINT; sql TEXT; anterior TIMESTAMPTZ;
BEGIN
    SELECT * INTO c FROM contexto_006;
    IF has_any_column_privilege(current_user,'public.modulos','INSERT')
       OR has_any_column_privilege(current_user,'public.modulos','UPDATE')
       OR has_table_privilege(current_user,'public.modulos','DELETE')
       OR has_any_column_privilege(current_user,'public.temas','INSERT')
       OR has_any_column_privilege(current_user,'public.temas','UPDATE')
       OR has_table_privilege(current_user,'public.temas','DELETE') THEN RAISE EXCEPTION 'FALLO: escritura directa concedida'; END IF;
    PERFORM pg_temp.esperar_error_006('DELETE FROM public.temas WHERE FALSE','42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT public.validar_editor_contenido(%s,%s,FALSE)',c.admin_id,c.curso_id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(%s,%s,''Otro'',''Desc'',1)',c.docente_id,c.otro_curso_id),'42501');
    SELECT * INTO m FROM public.crear_modulo(c.docente_id,c.curso_id,' Modulo ',' Descripcion ',1);
    IF m.creado_por<>c.docente_id OR m.nombre<>'Modulo' OR m.estado<>'BORRADOR' OR m.total_temas<>0 THEN RAISE EXCEPTION 'FALLO: modulo creado incorrectamente'; END IF;
    UPDATE contexto_006 SET modulo_id=m.id;
    SELECT * INTO t FROM public.crear_tema(c.docente_id,m.id,'Tema','Descripcion',1);
    UPDATE contexto_006 SET tema_id=t.id;
    IF t.creado_por<>c.docente_id OR t.modulo_id<>m.id THEN RAISE EXCEPTION 'FALLO: tema creado incorrectamente'; END IF;
    SELECT * INTO m FROM public.obtener_modulo(c.admin_id,m.id);
    IF m.total_temas<>1 THEN RAISE EXCEPTION 'FALLO: total_temas'; END IF;
    SELECT COUNT(*) INTO n FROM public.listar_modulos_por_curso(c.docente_id,c.curso_id); IF n<>1 THEN RAISE EXCEPTION 'FALLO: listado modulos'; END IF;
    SELECT COUNT(*) INTO n FROM public.listar_temas_por_modulo(c.docente_id,m.id); IF n<>1 THEN RAISE EXCEPTION 'FALLO: listado temas'; END IF;
    SELECT * INTO t FROM public.obtener_tema(c.admin_id,t.id);
    -- Mismo orden en otro padre debe permitirse.
    PERFORM public.crear_modulo(c.admin_id,c.otro_curso_id,'Otro','Descripcion',1);
    RAISE NOTICE 'OK 1: permisos, creacion docente/admin, listados y total_temas.';
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(%s,%s,''X'',''D'',10)',c.estudiante_id,c.curso_id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.listar_modulos_por_curso(%s,%s)',c.estudiante_id,c.curso_id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.obtener_modulo(%s,%s)',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.actualizar_modulo(%s,%s,''X'',''D'',1,''BORRADOR'')',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.cambiar_estado_modulo(%s,%s,''PUBLICADO'')',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.eliminar_modulo(%s,%s)',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_tema(%s,%s,''X'',''D'',10)',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.listar_temas_por_modulo(%s,%s)',c.estudiante_id,m.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.obtener_tema(%s,%s)',c.estudiante_id,t.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.actualizar_tema(%s,%s,''X'',''D'',1,''BORRADOR'')',c.estudiante_id,t.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.cambiar_estado_tema(%s,%s,''PUBLICADO'')',c.estudiante_id,t.id),'42501');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.eliminar_tema(%s,%s)',c.estudiante_id,t.id),'42501');

    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(%s,%s,''Duplicado'',''Desc'',1)',c.admin_id,c.curso_id),'23505');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_tema(%s,%s,''Duplicado'',''Desc'',1)',c.admin_id,m.id),'23505');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(%s,%s,'' '',''Desc'',2)',c.admin_id,c.curso_id),'22023');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_tema(%s,%s,''Nombre'',NULL,2)',c.admin_id,m.id),'22023');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_tema(%s,%s,''Nombre'',''Desc'',0)',c.admin_id,m.id),'22023');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.cambiar_estado_modulo(%s,%s,''ACTIVO'')',c.admin_id,m.id),'22023');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.obtener_tema(%s,NULL)',c.admin_id),'P0002');
    PERFORM pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(NULL,%s,''X'',''D'',2)',c.curso_id),'22023');
    SELECT * INTO m FROM public.actualizar_modulo(c.docente_id,m.id,'Editado','Descripcion nueva',2,'PUBLICADO');
    IF m.nombre<>'Editado' OR m.orden<>2 OR m.creado_por<>c.docente_id OR m.total_temas<>1 THEN RAISE EXCEPTION 'FALLO: editar modulo'; END IF;
    SELECT * INTO t FROM public.actualizar_tema(c.admin_id,t.id,'Tema editado','Descripcion nueva',2,'PUBLICADO');
    IF t.nombre<>'Tema editado' OR t.orden<>2 OR t.creado_por<>c.docente_id THEN RAISE EXCEPTION 'FALLO: editar tema'; END IF;
    PERFORM pg_temp.esperar_error_006(format('SELECT public.eliminar_modulo(%s,%s)',c.admin_id,m.id),'55000');
    PERFORM pg_temp.esperar_error_006(format('SELECT public.eliminar_tema(%s,%s)',c.admin_id,t.id),'55000');
    SELECT * INTO m FROM public.cambiar_estado_modulo(c.docente_id,m.id,'ARCHIVADO');
    IF m.estado<>'ARCHIVADO' THEN RAISE EXCEPTION 'FALLO: archivar modulo'; END IF;
    anterior:=m.actualizado_en;
    SELECT * INTO m FROM public.cambiar_estado_modulo(c.docente_id,m.id,'ARCHIVADO');
    IF m.actualizado_en<>anterior THEN RAISE EXCEPTION 'FALLO: estado repetido cambia fecha'; END IF;
    SELECT * INTO t FROM public.obtener_tema(c.admin_id,t.id);
    IF t.estado<>'PUBLICADO' THEN RAISE EXCEPTION 'FALLO: cambio de estado en cascada'; END IF;
    PERFORM public.cambiar_estado_modulo(c.docente_id,m.id,'BORRADOR');
    PERFORM public.cambiar_estado_tema(c.docente_id,t.id,'BORRADOR');
    PERFORM pg_temp.esperar_error_006(format('SELECT public.eliminar_modulo(%s,%s)',c.admin_id,m.id),'55000');
    RAISE NOTICE 'OK 2: rechazo estudiante en 12 operaciones, orden, campos, estados y dependencias.';
END;
$$;
RESET ROLE;
-- Cuenta inactiva, rol inactivo y editor inactivo se prueban por separado.
UPDATE public.usuarios SET activo=FALSE WHERE id=(SELECT docente_id FROM contexto_006);
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.esperar_error_006(format('SELECT * FROM public.listar_modulos_por_curso(%s,%s)',docente_id,curso_id),'42501') FROM contexto_006;
RESET ROLE;
UPDATE public.usuarios SET activo=TRUE WHERE id=(SELECT docente_id FROM contexto_006);
UPDATE public.usuario_roles SET activo=FALSE, desactivado_en=clock_timestamp() WHERE usuario_id=(SELECT docente_id FROM contexto_006);
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.esperar_error_006(format('SELECT * FROM public.listar_modulos_por_curso(%s,%s)',docente_id,curso_id),'42501') FROM contexto_006;
RESET ROLE;
UPDATE public.usuario_roles SET activo=TRUE, desactivado_en=NULL WHERE usuario_id=(SELECT docente_id FROM contexto_006);
UPDATE public.curso_editores SET activo=FALSE WHERE usuario_id=(SELECT docente_id FROM contexto_006);
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.esperar_error_006(format('SELECT * FROM public.listar_modulos_por_curso(%s,%s)',docente_id,curso_id),'42501') FROM contexto_006;
RESET ROLE;
UPDATE public.curso_editores SET activo=TRUE WHERE usuario_id=(SELECT docente_id FROM contexto_006);

-- Dependencia real: actividad sobre el tema, sin borrar ni alterar los triggers.
DO $$
DECLARE c RECORD; ed INTEGER; sec INTEGER;
BEGIN
    SELECT * INTO c FROM contexto_006;
    INSERT INTO public.ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,creado_por)
    VALUES(c.curso_id,'E006','Prueba',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP+INTERVAL '1 year',c.admin_id) RETURNING id INTO ed;
    INSERT INTO public.secciones(edicion_id,codigo,cupo_maximo,creado_por) VALUES(ed,'S006',10,c.admin_id) RETURNING id INTO sec;
    INSERT INTO public.actividades(seccion_id,tema_id,titulo,instrucciones,disponible_desde,creado_por)
    VALUES(sec,c.tema_id,'Prueba 006','Prueba',CURRENT_TIMESTAMP,c.admin_id);
END;
$$;
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.esperar_error_006(format('SELECT public.eliminar_tema(%s,%s)',admin_id,tema_id),'55000') FROM contexto_006;
RESET ROLE;
DELETE FROM public.actividades WHERE tema_id=(SELECT tema_id FROM contexto_006);
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE c RECORD; n BIGINT; m RECORD;
BEGIN
    SELECT * INTO c FROM contexto_006;
    PERFORM public.eliminar_tema(c.docente_id,c.tema_id);
    SELECT * INTO m FROM public.obtener_modulo(c.docente_id,c.modulo_id);
    IF m.total_temas<>0 THEN RAISE EXCEPTION 'FALLO: conteo tras eliminar'; END IF;
    PERFORM public.eliminar_modulo(c.docente_id,c.modulo_id);
    SELECT COUNT(*) INTO n FROM public.listar_modulos_por_curso(c.docente_id,c.curso_id);
    IF n<>0 THEN RAISE EXCEPTION 'FALLO: borrado no persistio'; END IF;
    PERFORM pg_temp.esperar_error_006(format('SELECT public.eliminar_modulo(%s,%s)',c.docente_id,c.modulo_id),'P0002');
    RAISE NOTICE 'OK 3: revocacion de cuenta/rol/editor, dependencias y borrado valido.';
END;
$$;
RESET ROLE;
-- El curso sin ediciones puede archivarse mediante 005.
SELECT public.cambiar_estado_curso_admin(admin_id,otro_curso_id,'ARCHIVADO') FROM contexto_006;
SET LOCAL ROLE plataforma_backend;
SELECT pg_temp.esperar_error_006(format('SELECT * FROM public.crear_modulo(%s,%s,''X'',''D'',4)',admin_id,otro_curso_id),'55000') FROM contexto_006;
SELECT * FROM public.listar_modulos_por_curso((SELECT admin_id FROM contexto_006),(SELECT otro_curso_id FROM contexto_006));
DO $$ BEGIN RAISE NOTICE 'PRUEBAS 006 COMPLETADAS: todos los casos incluidos pasaron.'; END; $$;
ROLLBACK;
