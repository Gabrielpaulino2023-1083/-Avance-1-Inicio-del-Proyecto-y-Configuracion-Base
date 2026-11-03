BEGIN;

SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE FUNCTION public.inscribir_estudiante(
    p_seccion_id INTEGER,
    p_estudiante_id INTEGER,
    p_actor_id INTEGER
)
RETURNS public.inscripciones
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $funcion$
DECLARE
    v_curso_id INTEGER;
    v_edicion_id INTEGER;
    v_estado_curso TEXT;
    v_edicion public.ediciones_curso%ROWTYPE;
    v_seccion public.secciones%ROWTYPE;
    v_inscripcion public.inscripciones%ROWTYPE;
    v_origen TEXT;
    v_ocupados BIGINT;
    v_ahora TIMESTAMPTZ;
BEGIN
    IF p_seccion_id IS NULL
       OR p_estudiante_id IS NULL
       OR p_actor_id IS NULL THEN
        RAISE EXCEPTION
            'Seccion, estudiante y actor son obligatorios.';
    END IF;

    -- La comprobacion del cupo depende de obtener una instantanea
    -- nueva despues de esperar por el bloqueo de la seccion.
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION
            'Esta operacion requiere aislamiento READ COMMITTED.';
    END IF;

    SELECT s.edicion_id, e.curso_id
    INTO v_edicion_id, v_curso_id
    FROM public.secciones s
    JOIN public.ediciones_curso e ON e.id = s.edicion_id
    WHERE s.id = p_seccion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La seccion no existe.';
    END IF;

    -- Orden de bloqueo: curso, edicion, seccion, usuarios y roles.
    SELECT estado INTO v_estado_curso
    FROM public.cursos
    WHERE id = v_curso_id
    FOR SHARE;

    IF NOT FOUND OR v_estado_curso <> 'ACTIVO' THEN
        RAISE EXCEPTION 'El curso no esta activo.';
    END IF;

    SELECT * INTO v_edicion
    FROM public.ediciones_curso
    WHERE id = v_edicion_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La edicion no existe.';
    END IF;

    IF v_edicion.estado <> 'ABIERTA' THEN
        RAISE EXCEPTION 'La edicion no esta abierta para inscripcion.';
    END IF;

    -- Serializa las inscripciones que compiten por el mismo cupo.
    SELECT * INTO v_seccion
    FROM public.secciones
    WHERE id = p_seccion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La seccion no existe.';
    END IF;

    IF v_seccion.estado <> 'ABIERTA' THEN
        RAISE EXCEPTION 'La seccion no esta abierta.';
    END IF;

    -- Bloquear las cuentas en un orden estable.
    PERFORM u.id
    FROM public.usuarios u
    WHERE u.id IN (p_estudiante_id, p_actor_id)
    ORDER BY u.id
    FOR SHARE OF u;

    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE id = p_estudiante_id AND activo
    ) THEN
        RAISE EXCEPTION 'La cuenta del estudiante no existe o esta inactiva.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE id = p_actor_id AND activo
    ) THEN
        RAISE EXCEPTION 'La cuenta del actor no existe o esta inactiva.';
    END IF;

    PERFORM ur.id
    FROM public.usuario_roles ur
    WHERE ur.usuario_id IN (p_estudiante_id, p_actor_id)
    ORDER BY ur.id
    FOR SHARE OF ur;

    IF NOT EXISTS (
        SELECT 1
        FROM public.usuario_roles ur
        JOIN public.roles r ON r.id = ur.rol_id
        WHERE ur.usuario_id = p_estudiante_id
          AND ur.activo
          AND r.codigo = 'ESTUDIANTE'
    ) THEN
        RAISE EXCEPTION 'El usuario no tiene el rol ESTUDIANTE activo.';
    END IF;

    IF p_actor_id = p_estudiante_id THEN
        v_origen := 'AUTONOMA';
    ELSE
        IF NOT EXISTS (
            SELECT 1
            FROM public.usuario_roles ur
            JOIN public.roles r ON r.id = ur.rol_id
            WHERE ur.usuario_id = p_actor_id
              AND ur.activo
              AND r.codigo = 'ADMINISTRADOR'
        ) THEN
            RAISE EXCEPTION
                'Solo un administrador activo puede inscribir a otra persona.';
        END IF;

        v_origen := 'ADMINISTRATIVA';
    END IF;

    -- Evaluar el reloj despues de adquirir los bloqueos.
    v_ahora := clock_timestamp();

    IF v_edicion.inscripcion_desde IS NULL
       OR v_edicion.inscripcion_hasta IS NULL THEN
        RAISE EXCEPTION 'La edicion no tiene una ventana de inscripcion.';
    END IF;

    -- Inicio incluido; cierre excluido.
    IF v_ahora < v_edicion.inscripcion_desde
       OR v_ahora >= v_edicion.inscripcion_hasta THEN
        RAISE EXCEPTION 'Fuera del periodo de inscripcion.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.inscripciones
        WHERE estudiante_id = p_estudiante_id
          AND edicion_id = v_edicion_id
    ) THEN
        RAISE EXCEPTION
            'El estudiante ya tiene una inscripcion en esta edicion.';
    END IF;

    SELECT COUNT(*) INTO v_ocupados
    FROM public.inscripciones
    WHERE seccion_id = p_seccion_id
      AND estado = 'ACTIVA';

    IF v_ocupados >= v_seccion.cupo_maximo THEN
        RAISE EXCEPTION 'La seccion no tiene cupos disponibles.';
    END IF;

    INSERT INTO public.inscripciones (
        estudiante_id,
        edicion_id,
        seccion_id,
        estado,
        origen,
        registrado_por,
        inscrito_en
    )
    VALUES (
        p_estudiante_id,
        v_edicion_id,
        p_seccion_id,
        'ACTIVA',
        v_origen,
        p_actor_id,
        v_ahora
    )
    RETURNING * INTO v_inscripcion;

    RETURN v_inscripcion;
END;
$funcion$;

-- Permisos del rol interno que ejecuta la funcion.
GRANT SELECT ON
    public.cursos,
    public.ediciones_curso,
    public.secciones,
    public.usuarios,
    public.roles,
    public.usuario_roles,
    public.inscripciones
TO plataforma_operaciones;

-- PostgreSQL requiere permiso UPDATE para los bloqueos de filas.
-- La funcion no modifica los identificadores.
GRANT UPDATE (id) ON public.cursos
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.ediciones_curso
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.secciones
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.usuarios
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.usuario_roles
TO plataforma_operaciones;

GRANT INSERT (
    estudiante_id,
    edicion_id,
    seccion_id,
    estado,
    origen,
    registrado_por,
    inscrito_en
)
ON public.inscripciones
TO plataforma_operaciones;

GRANT USAGE ON SEQUENCE public.inscripciones_id_seq
TO plataforma_operaciones;

ALTER FUNCTION public.inscribir_estudiante(INTEGER, INTEGER, INTEGER)
    OWNER TO plataforma_operaciones;

REVOKE ALL ON FUNCTION
    public.inscribir_estudiante(INTEGER, INTEGER, INTEGER)
FROM PUBLIC;

GRANT EXECUTE ON FUNCTION
    public.inscribir_estudiante(INTEGER, INTEGER, INTEGER)
TO plataforma_backend;

COMMIT;