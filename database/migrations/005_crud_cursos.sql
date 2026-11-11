-- Actor: ID obtenido del JWT verificado; nunca del body del cliente.
BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE FUNCTION public.validar_administrador_cursos(p_actor_id INTEGER)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    PERFORM id FROM public.usuarios
    WHERE id = p_actor_id AND activo FOR SHARE;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Se requiere un administrador activo.';
    END IF;
    PERFORM ur.id FROM public.usuario_roles ur
    JOIN public.roles r ON r.id = ur.rol_id
    WHERE ur.usuario_id = p_actor_id AND ur.activo AND r.codigo = 'ADMINISTRADOR'
    FOR SHARE OF ur;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Se requiere un administrador activo.';
    END IF;
END;
$$;

CREATE FUNCTION public.crear_curso_admin(
    p_actor_id INTEGER, p_codigo TEXT, p_nombre TEXT, p_descripcion TEXT
)
RETURNS public.cursos LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso public.cursos;
BEGIN
    PERFORM public.validar_administrador_cursos(p_actor_id);
    IF p_codigo IS NULL OR btrim(p_codigo) = ''
       OR p_nombre IS NULL OR btrim(p_nombre) = ''
       OR p_descripcion IS NULL OR btrim(p_descripcion) = '' THEN
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Codigo, nombre y descripcion son obligatorios.';
    END IF;
    INSERT INTO public.cursos(codigo, nombre, descripcion, creado_por)
    VALUES (btrim(p_codigo), btrim(p_nombre), btrim(p_descripcion), p_actor_id)
    RETURNING * INTO v_curso;
    RETURN v_curso;
END;
$$;

CREATE FUNCTION public.listar_cursos_admin(
    p_actor_id INTEGER, p_estado TEXT DEFAULT NULL,
    p_limite INTEGER DEFAULT 50, p_desplazamiento INTEGER DEFAULT 0
)
RETURNS SETOF public.cursos LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    PERFORM public.validar_administrador_cursos(p_actor_id);
    IF (p_estado IS NOT NULL AND p_estado NOT IN ('BORRADOR', 'ACTIVO', 'ARCHIVADO'))
       OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 100
       OR p_desplazamiento IS NULL OR p_desplazamiento < 0 THEN
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Filtro o paginacion invalida.';
    END IF;
    RETURN QUERY SELECT c.* FROM public.cursos c
    WHERE p_estado IS NULL OR c.estado = p_estado
    ORDER BY c.id DESC LIMIT p_limite OFFSET p_desplazamiento;
END;
$$;

CREATE FUNCTION public.obtener_curso_admin(p_actor_id INTEGER, p_curso_id INTEGER)
RETURNS public.cursos LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso public.cursos;
BEGIN
    PERFORM public.validar_administrador_cursos(p_actor_id);
    SELECT * INTO v_curso FROM public.cursos WHERE id = p_curso_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'El curso no existe.';
    END IF;
    RETURN v_curso;
END;
$$;

CREATE FUNCTION public.actualizar_curso_admin(
    p_actor_id INTEGER, p_curso_id INTEGER,
    p_codigo TEXT, p_nombre TEXT, p_descripcion TEXT
)
RETURNS public.cursos LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso public.cursos;
BEGIN
    -- Mismo orden curso -> usuario/rol que la inscripción 004.
    SELECT * INTO v_curso FROM public.cursos WHERE id = p_curso_id FOR UPDATE;
    PERFORM public.validar_administrador_cursos(p_actor_id);
    IF v_curso.id IS NULL THEN
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'El curso no existe.';
    END IF;
    IF v_curso.estado = 'ARCHIVADO' THEN
        RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'Un curso archivado no admite edicion.';
    END IF;
    IF p_codigo IS NULL OR btrim(p_codigo) = ''
       OR p_nombre IS NULL OR btrim(p_nombre) = ''
       OR p_descripcion IS NULL OR btrim(p_descripcion) = '' THEN
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Codigo, nombre y descripcion son obligatorios.';
    END IF;
    UPDATE public.cursos SET codigo = btrim(p_codigo), nombre = btrim(p_nombre),
        descripcion = btrim(p_descripcion), actualizado_en = clock_timestamp()
    WHERE id = p_curso_id RETURNING * INTO v_curso;
    RETURN v_curso;
END;
$$;

CREATE FUNCTION public.cambiar_estado_curso_admin(
    p_actor_id INTEGER, p_curso_id INTEGER, p_estado TEXT
)
RETURNS public.cursos LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso public.cursos;
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION USING ERRCODE = '25000', MESSAGE = 'Esta operacion requiere READ COMMITTED.';
    END IF;
    SELECT * INTO v_curso FROM public.cursos WHERE id = p_curso_id FOR UPDATE;
    PERFORM public.validar_administrador_cursos(p_actor_id);
    IF v_curso.id IS NULL THEN
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'El curso no existe.';
    END IF;
    IF p_estado IS NULL OR p_estado NOT IN ('ACTIVO', 'ARCHIVADO') THEN
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Estado de destino invalido.';
    END IF;
    IF v_curso.estado = p_estado THEN RETURN v_curso; END IF;
    IF v_curso.estado = 'ARCHIVADO' THEN
        RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'No se permite reactivar un curso archivado en esta version.';
    END IF;
    IF p_estado = 'ARCHIVADO' THEN
        PERFORM id FROM public.ediciones_curso WHERE curso_id = p_curso_id ORDER BY id FOR SHARE;
        IF EXISTS (SELECT 1 FROM public.ediciones_curso
                   WHERE curso_id = p_curso_id AND estado IN ('PLANIFICADA', 'ABIERTA', 'EN_CURSO')) THEN
            RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'El curso tiene ediciones pendientes o en ejecucion.';
        END IF;
    END IF;
    UPDATE public.cursos SET estado = p_estado, actualizado_en = clock_timestamp()
    WHERE id = p_curso_id RETURNING * INTO v_curso;
    RETURN v_curso;
END;
$$;

GRANT SELECT ON public.cursos, public.ediciones_curso, public.usuarios,
    public.usuario_roles, public.roles TO plataforma_operaciones;
GRANT UPDATE (id) ON public.usuarios, public.usuario_roles, public.ediciones_curso
    TO plataforma_operaciones;
GRANT INSERT (codigo, nombre, descripcion, creado_por) ON public.cursos TO plataforma_operaciones;
GRANT UPDATE (id, codigo, nombre, descripcion, estado, actualizado_en)
    ON public.cursos TO plataforma_operaciones;
GRANT USAGE ON SEQUENCE public.cursos_id_seq TO plataforma_operaciones;
-- Conserva SELECT del backend; la administración se hace por funciones.
-- No elimina concesiones manuales por columna ni heredadas: se verifican en pruebas.
REVOKE INSERT, UPDATE, DELETE ON public.cursos FROM plataforma_backend, PUBLIC;

ALTER FUNCTION public.validar_administrador_cursos(INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.validar_administrador_cursos(INTEGER) FROM PUBLIC, plataforma_backend;

ALTER FUNCTION public.crear_curso_admin(INTEGER, TEXT, TEXT, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_curso_admin(INTEGER, TEXT, TEXT, TEXT) FROM PUBLIC, plataforma_backend;
GRANT EXECUTE ON FUNCTION public.crear_curso_admin(INTEGER, TEXT, TEXT, TEXT) TO plataforma_backend;

ALTER FUNCTION public.listar_cursos_admin(INTEGER, TEXT, INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_cursos_admin(INTEGER, TEXT, INTEGER, INTEGER) FROM PUBLIC, plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_cursos_admin(INTEGER, TEXT, INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_curso_admin(INTEGER, INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_curso_admin(INTEGER, INTEGER) FROM PUBLIC, plataforma_backend;
GRANT EXECUTE ON FUNCTION public.obtener_curso_admin(INTEGER, INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_curso_admin(INTEGER, INTEGER, TEXT, TEXT, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_curso_admin(INTEGER, INTEGER, TEXT, TEXT, TEXT) FROM PUBLIC, plataforma_backend;
GRANT EXECUTE ON FUNCTION public.actualizar_curso_admin(INTEGER, INTEGER, TEXT, TEXT, TEXT) TO plataforma_backend;

ALTER FUNCTION public.cambiar_estado_curso_admin(INTEGER, INTEGER, TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_estado_curso_admin(INTEGER, INTEGER, TEXT) FROM PUBLIC, plataforma_backend;
GRANT EXECUTE ON FUNCTION public.cambiar_estado_curso_admin(INTEGER, INTEGER, TEXT) TO plataforma_backend;

COMMIT;
