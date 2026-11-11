BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE FUNCTION public.validar_editor_contenido(p_actor_id INTEGER, p_curso_id INTEGER, p_escritura BOOLEAN)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_estado TEXT;
BEGIN
    IF p_actor_id IS NULL OR p_curso_id IS NULL OR p_escritura IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor, curso y operacion son obligatorios.';
    END IF;
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION USING ERRCODE='25000', MESSAGE='Esta operacion requiere READ COMMITTED.';
    END IF;
    IF p_escritura THEN
        SELECT estado INTO v_estado FROM public.cursos WHERE id=p_curso_id FOR UPDATE;
    ELSE
        SELECT estado INTO v_estado FROM public.cursos WHERE id=p_curso_id FOR SHARE;
    END IF;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El curso no existe.';
    END IF;
    PERFORM id FROM public.usuarios WHERE id=p_actor_id AND activo FOR SHARE;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Cuenta sin autorizacion para administrar contenido.';
    END IF;
    PERFORM ur.id FROM public.usuario_roles ur
    WHERE ur.usuario_id=p_actor_id ORDER BY ur.id FOR SHARE;
    IF NOT EXISTS (
        SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id
        WHERE ur.usuario_id=p_actor_id AND ur.activo AND r.codigo='ADMINISTRADOR'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id
            WHERE ur.usuario_id=p_actor_id AND ur.activo AND r.codigo='DOCENTE'
        ) THEN
            RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere administrador o docente editor autorizado.';
        END IF;
        PERFORM id FROM public.curso_editores
        WHERE curso_id=p_curso_id AND usuario_id=p_actor_id AND activo FOR SHARE;
        IF NOT FOUND THEN
            RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='El docente no es editor activo de este curso.';
        END IF;
    END IF;
    IF p_escritura AND v_estado='ARCHIVADO' THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='No se puede modificar contenido de un curso archivado.';
    END IF;
END;
$$;

CREATE FUNCTION public.validar_datos_contenido(p_nombre TEXT,p_descripcion TEXT,p_orden INTEGER,p_estado TEXT)
RETURNS VOID LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF p_nombre IS NULL OR btrim(p_nombre)='' OR p_descripcion IS NULL OR btrim(p_descripcion)=''
       OR p_orden IS NULL OR p_orden<=0 OR p_estado IS NULL
       OR p_estado NOT IN ('BORRADOR','PUBLICADO','ARCHIVADO') THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Nombre, descripcion, orden o estado invalidos.';
    END IF;
END;
$$;

CREATE FUNCTION public.crear_modulo(p_actor_id INTEGER,p_curso_id INTEGER,p_nombre TEXT,p_descripcion TEXT,p_orden INTEGER,p_estado TEXT DEFAULT 'BORRADOR')
RETURNS TABLE(id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,estado VARCHAR(50),creado_por INTEGER,creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,total_temas BIGINT) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER;
BEGIN
    PERFORM public.validar_editor_contenido(p_actor_id,p_curso_id,TRUE);
    PERFORM public.validar_datos_contenido(p_nombre,p_descripcion,p_orden,p_estado);
    INSERT INTO public.modulos(curso_id,nombre,descripcion,orden,estado,creado_por)
    VALUES(p_curso_id,btrim(p_nombre),btrim(p_descripcion),p_orden,p_estado,p_actor_id) RETURNING public.modulos.id INTO v_id;
    RETURN QUERY SELECT m.*, (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id) AS total_temas FROM public.modulos m WHERE m.id=v_id;
END;
$$;

CREATE FUNCTION public.listar_modulos_por_curso(p_actor_id INTEGER,p_curso_id INTEGER)
RETURNS TABLE(id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,estado VARCHAR(50),creado_por INTEGER,creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,total_temas BIGINT) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER;
BEGIN
    PERFORM public.validar_editor_contenido(p_actor_id,p_curso_id,FALSE);
    RETURN QUERY SELECT m.*, (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id) AS total_temas FROM public.modulos m WHERE m.curso_id=p_curso_id ORDER BY m.orden,m.id;
END;
$$;

CREATE FUNCTION public.obtener_modulo(p_actor_id INTEGER,p_modulo_id INTEGER)
RETURNS TABLE(id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,estado VARCHAR(50),creado_por INTEGER,creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,total_temas BIGINT) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,FALSE);
    PERFORM x.id FROM public.modulos x WHERE x.id=p_modulo_id FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    RETURN QUERY SELECT m.*, (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id) AS total_temas FROM public.modulos m WHERE m.id=p_modulo_id;
END;
$$;

CREATE FUNCTION public.actualizar_modulo(p_actor_id INTEGER,p_modulo_id INTEGER,p_nombre TEXT,p_descripcion TEXT,p_orden INTEGER,p_estado TEXT)
RETURNS TABLE(id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,estado VARCHAR(50),creado_por INTEGER,creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,total_temas BIGINT) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.modulos x WHERE x.id=p_modulo_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_datos_contenido(p_nombre,p_descripcion,p_orden,p_estado);
    UPDATE public.modulos SET nombre=btrim(p_nombre),descripcion=btrim(p_descripcion),orden=p_orden,estado=p_estado,actualizado_en=clock_timestamp() WHERE public.modulos.id=p_modulo_id;
    RETURN QUERY SELECT m.*, (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id) AS total_temas FROM public.modulos m WHERE m.id=p_modulo_id;
END;
$$;

CREATE FUNCTION public.cambiar_estado_modulo(p_actor_id INTEGER,p_modulo_id INTEGER,p_estado TEXT)
RETURNS TABLE(id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,estado VARCHAR(50),creado_por INTEGER,creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,total_temas BIGINT) LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.modulos x WHERE x.id=p_modulo_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    IF p_estado IS NULL OR p_estado NOT IN ('BORRADOR','PUBLICADO','ARCHIVADO') THEN RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Estado invalido.'; END IF;
    UPDATE public.modulos SET estado=p_estado,actualizado_en=clock_timestamp() WHERE public.modulos.id=p_modulo_id AND public.modulos.estado IS DISTINCT FROM p_estado;
    RETURN QUERY SELECT m.*, (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id) AS total_temas FROM public.modulos m WHERE m.id=p_modulo_id;
END;
$$;

CREATE FUNCTION public.eliminar_modulo(p_actor_id INTEGER,p_modulo_id INTEGER)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.modulos x WHERE x.id=p_modulo_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    IF EXISTS(SELECT 1 FROM public.modulos WHERE public.modulos.id=p_modulo_id AND public.modulos.estado<>'BORRADOR') THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='Solo se puede eliminar un modulo en BORRADOR.';
    END IF;
    IF EXISTS(SELECT 1 FROM public.temas WHERE modulo_id=p_modulo_id) THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='No se puede eliminar: existen temas dependientes.';
    END IF;
    BEGIN
        DELETE FROM public.modulos WHERE public.modulos.id=p_modulo_id;
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='No se puede eliminar: existen registros dependientes.';
    END;
    RETURN p_modulo_id;
END;
$$;

CREATE FUNCTION public.crear_tema(p_actor_id INTEGER,p_modulo_id INTEGER,p_nombre TEXT,p_descripcion TEXT,p_orden INTEGER,p_estado TEXT DEFAULT 'BORRADOR')
RETURNS public.temas LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER; v_fila public.temas;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM id FROM public.modulos WHERE id=p_modulo_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_datos_contenido(p_nombre,p_descripcion,p_orden,p_estado);
    INSERT INTO public.temas(modulo_id,nombre,descripcion,orden,estado,creado_por)
    VALUES(p_modulo_id,btrim(p_nombre),btrim(p_descripcion),p_orden,p_estado,p_actor_id) RETURNING public.temas.id INTO v_id;
    SELECT t.* INTO v_fila FROM public.temas t WHERE t.id=v_id; RETURN v_fila;
END;
$$;

CREATE FUNCTION public.listar_temas_por_modulo(p_actor_id INTEGER,p_modulo_id INTEGER)
RETURNS SETOF public.temas LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER;
BEGIN
    SELECT x.curso_id INTO v_curso FROM public.modulos x WHERE x.id=p_modulo_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,FALSE);
    PERFORM id FROM public.modulos WHERE id=p_modulo_id FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El modulo no existe.'; END IF;
    RETURN QUERY SELECT t.* FROM public.temas t WHERE t.modulo_id=p_modulo_id ORDER BY t.orden,t.id;
END;
$$;

CREATE FUNCTION public.obtener_tema(p_actor_id INTEGER,p_tema_id INTEGER)
RETURNS public.temas LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER; v_fila public.temas;
BEGIN
    SELECT m.curso_id INTO v_curso FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=p_tema_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,FALSE);
    PERFORM x.id FROM public.temas x WHERE x.id=p_tema_id FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    SELECT t.* INTO v_fila FROM public.temas t WHERE t.id=p_tema_id; RETURN v_fila;
END;
$$;

CREATE FUNCTION public.actualizar_tema(p_actor_id INTEGER,p_tema_id INTEGER,p_nombre TEXT,p_descripcion TEXT,p_orden INTEGER,p_estado TEXT)
RETURNS public.temas LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER; v_fila public.temas;
BEGIN
    SELECT m.curso_id INTO v_curso FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=p_tema_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.temas x WHERE x.id=p_tema_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    PERFORM public.validar_datos_contenido(p_nombre,p_descripcion,p_orden,p_estado);
    UPDATE public.temas SET nombre=btrim(p_nombre),descripcion=btrim(p_descripcion),orden=p_orden,estado=p_estado,actualizado_en=clock_timestamp() WHERE public.temas.id=p_tema_id;
    SELECT t.* INTO v_fila FROM public.temas t WHERE t.id=p_tema_id; RETURN v_fila;
END;
$$;

CREATE FUNCTION public.cambiar_estado_tema(p_actor_id INTEGER,p_tema_id INTEGER,p_estado TEXT)
RETURNS public.temas LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER; v_id INTEGER; v_fila public.temas;
BEGIN
    SELECT m.curso_id INTO v_curso FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=p_tema_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.temas x WHERE x.id=p_tema_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    IF p_estado IS NULL OR p_estado NOT IN ('BORRADOR','PUBLICADO','ARCHIVADO') THEN RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Estado invalido.'; END IF;
    UPDATE public.temas SET estado=p_estado,actualizado_en=clock_timestamp() WHERE public.temas.id=p_tema_id AND public.temas.estado IS DISTINCT FROM p_estado;
    SELECT t.* INTO v_fila FROM public.temas t WHERE t.id=p_tema_id; RETURN v_fila;
END;
$$;

CREATE FUNCTION public.eliminar_tema(p_actor_id INTEGER,p_tema_id INTEGER)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso INTEGER;
BEGIN
    SELECT m.curso_id INTO v_curso FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=p_tema_id;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    PERFORM public.validar_editor_contenido(p_actor_id,v_curso,TRUE);
    PERFORM x.id FROM public.temas x WHERE x.id=p_tema_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='El tema no existe.'; END IF;
    IF EXISTS(SELECT 1 FROM public.temas WHERE public.temas.id=p_tema_id AND public.temas.estado<>'BORRADOR') THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='Solo se puede eliminar un tema en BORRADOR.';
    END IF;
    IF EXISTS(SELECT 1 FROM public.actividades WHERE tema_id=p_tema_id) THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='No se puede eliminar: existen actividades dependientes.';
    END IF;
    BEGIN
        DELETE FROM public.temas WHERE public.temas.id=p_tema_id;
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='No se puede eliminar: existen registros dependientes.';
    END;
    RETURN p_tema_id;
END;
$$;

GRANT SELECT ON public.modulos,public.temas,public.actividades,public.curso_editores TO plataforma_operaciones;
GRANT UPDATE(id) ON public.curso_editores TO plataforma_operaciones;
GRANT INSERT(curso_id,nombre,descripcion,orden,estado,creado_por) ON public.modulos TO plataforma_operaciones;
GRANT INSERT(modulo_id,nombre,descripcion,orden,estado,creado_por) ON public.temas TO plataforma_operaciones;
GRANT UPDATE(id,nombre,descripcion,orden,estado,actualizado_en) ON public.modulos,public.temas TO plataforma_operaciones;
GRANT DELETE ON public.modulos,public.temas TO plataforma_operaciones;
GRANT USAGE ON SEQUENCE public.modulos_id_seq,public.temas_id_seq TO plataforma_operaciones;
REVOKE INSERT,UPDATE,DELETE ON public.modulos,public.temas FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.validar_editor_contenido(INTEGER, INTEGER, BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.validar_editor_contenido(INTEGER, INTEGER, BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.validar_datos_contenido(TEXT, TEXT, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.validar_datos_contenido(TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.crear_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.crear_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.listar_modulos_por_curso(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_modulos_por_curso(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_modulos_por_curso(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_modulo(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_modulo(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.obtener_modulo(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.actualizar_modulo(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.cambiar_estado_modulo(INTEGER, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_estado_modulo(INTEGER, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.cambiar_estado_modulo(INTEGER, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.eliminar_modulo(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.eliminar_modulo(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.eliminar_modulo(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.crear_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.crear_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.listar_temas_por_modulo(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_temas_por_modulo(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_temas_por_modulo(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_tema(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_tema(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.obtener_tema(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.actualizar_tema(INTEGER, INTEGER, TEXT, TEXT, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.cambiar_estado_tema(INTEGER, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_estado_tema(INTEGER, INTEGER, TEXT) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.cambiar_estado_tema(INTEGER, INTEGER, TEXT) TO plataforma_backend;

ALTER FUNCTION public.eliminar_tema(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.eliminar_tema(INTEGER, INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.eliminar_tema(INTEGER, INTEGER) TO plataforma_backend;

COMMIT;
