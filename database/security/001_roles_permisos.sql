-- Configuración de acceso para desarrollo.
-- Ejecutar como postgres después de las migraciones 001, 002 y 003.
-- No contiene contraseñas ni cambia la contraseña de roles existentes.
-- Puede repetirse para estos roles de proyecto; no elimina permisos ajenos
-- concedidos manualmente ni audita todas las posibles membresías.
-- No concede permisos para administrar cursos o editar actividades desde Express.

BEGIN;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'plataforma_backend') THEN
        CREATE ROLE plataforma_backend
            LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOREPLICATION NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'plataforma_operaciones') THEN
        CREATE ROLE plataforma_operaciones
            NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOREPLICATION NOBYPASSRLS;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname IN ('plataforma_backend', 'plataforma_operaciones')
          AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)
    ) THEN
        RAISE EXCEPTION 'Los roles existentes tienen privilegios elevados; revisar antes de continuar.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_roles
        WHERE (rolname = 'plataforma_backend' AND NOT rolcanlogin)
           OR (rolname = 'plataforma_operaciones' AND rolcanlogin)
    ) THEN
        RAISE EXCEPTION 'La configuración LOGIN/NOLOGIN de los roles existentes no es la esperada.';
    END IF;

    IF pg_has_role('plataforma_backend', 'plataforma_operaciones', 'MEMBER') THEN
        RAISE EXCEPTION 'El backend no debe ser miembro de plataforma_operaciones.';
    END IF;

    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO plataforma_backend',
        current_database()
    );
END;
$$;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

GRANT USAGE ON SCHEMA public
TO plataforma_backend, plataforma_operaciones;


-- =========================================================
-- BACKEND: lectura para autenticación y consultas académicas
-- =========================================================

GRANT SELECT ON TABLE
    public.usuarios,
    public.roles,
    public.usuario_roles,
    public.cursos,
    public.curso_editores,
    public.ediciones_curso,
    public.secciones,
    public.seccion_docentes,
    public.inscripciones,
    public.modulos,
    public.temas,
    public.actividades,
    public.preguntas,
    public.intentos,
    public.respuestas,
    public.respuesta_opciones,
    public.resultados_actividades
TO plataforma_backend;

GRANT SELECT (
    id, pregunta_id, texto, orden
)
ON public.opciones_respuestas
TO plataforma_backend;


-- =========================================================
-- BACKEND: conservar compatibilidad con el registro actual
-- =========================================================

GRANT INSERT (
    nombre, apellido, email, password_hash
)
ON public.usuarios
TO plataforma_backend;

GRANT INSERT (
    usuario_id, rol_id, asignado_por
)
ON public.usuario_roles
TO plataforma_backend;

GRANT USAGE ON SEQUENCE
    public.usuarios_id_seq,
    public.usuario_roles_id_seq
TO plataforma_backend;


-- =========================================================
-- ROL INTERNO: permisos necesarios para las cuatro funciones
-- =========================================================

GRANT SELECT ON TABLE
    public.usuarios,
    public.roles,
    public.usuario_roles,
    public.inscripciones,
    public.actividades,
    public.preguntas,
    public.opciones_respuestas,
    public.intentos,
    public.respuestas,
    public.respuesta_opciones
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.usuarios
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.usuario_roles
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.inscripciones
TO plataforma_operaciones;

GRANT UPDATE (id) ON public.actividades
TO plataforma_operaciones;

GRANT INSERT ON public.intentos, public.respuestas
TO plataforma_operaciones;

GRANT UPDATE (
    estado,
    entregado_en,
    motivo_entrega,
    calificado_en,
    puntaje_obtenido
)
ON public.intentos
TO plataforma_operaciones;

GRANT UPDATE (
    actualizado_en,
    calificado_en,
    puntaje_obtenido
)
ON public.respuestas
TO plataforma_operaciones;

GRANT INSERT, DELETE ON public.respuesta_opciones
TO plataforma_operaciones;

GRANT USAGE ON SEQUENCE
    public.intentos_id_seq,
    public.respuestas_id_seq
TO plataforma_operaciones;


REVOKE ALL PRIVILEGES ON TABLE
    public.intentos,
    public.respuestas,
    public.respuesta_opciones
FROM PUBLIC;


-- =========================================================
-- Ejecutar funciones con el rol interno, no como postgres
-- =========================================================

ALTER FUNCTION public.iniciar_intento(
    INTEGER, INTEGER, INTEGER
) OWNER TO plataforma_operaciones;

ALTER FUNCTION public.guardar_opciones_respuesta(
    INTEGER, INTEGER, INTEGER[]
) OWNER TO plataforma_operaciones;

ALTER FUNCTION public.entregar_intento(
    INTEGER, INTEGER
) OWNER TO plataforma_operaciones;

ALTER FUNCTION public.calificar_intento(
    INTEGER
) OWNER TO plataforma_operaciones;


ALTER FUNCTION public.iniciar_intento(
    INTEGER, INTEGER, INTEGER
) SECURITY DEFINER;

ALTER FUNCTION public.guardar_opciones_respuesta(
    INTEGER, INTEGER, INTEGER[]
) SECURITY DEFINER;

ALTER FUNCTION public.entregar_intento(
    INTEGER, INTEGER
) SECURITY DEFINER;

ALTER FUNCTION public.calificar_intento(
    INTEGER
) SECURITY DEFINER;


ALTER FUNCTION public.iniciar_intento(
    INTEGER, INTEGER, INTEGER
) SET search_path = pg_catalog, public, pg_temp;

ALTER FUNCTION public.guardar_opciones_respuesta(
    INTEGER, INTEGER, INTEGER[]
) SET search_path = pg_catalog, public, pg_temp;

ALTER FUNCTION public.entregar_intento(
    INTEGER, INTEGER
) SET search_path = pg_catalog, public, pg_temp;

ALTER FUNCTION public.calificar_intento(
    INTEGER
) SET search_path = pg_catalog, public, pg_temp;


REVOKE ALL ON FUNCTION public.iniciar_intento(
    INTEGER, INTEGER, INTEGER
) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.guardar_opciones_respuesta(
    INTEGER, INTEGER, INTEGER[]
) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.entregar_intento(
    INTEGER, INTEGER
) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.calificar_intento(
    INTEGER
) FROM PUBLIC;


GRANT EXECUTE ON FUNCTION public.iniciar_intento(
    INTEGER, INTEGER, INTEGER
) TO plataforma_backend;

GRANT EXECUTE ON FUNCTION public.guardar_opciones_respuesta(
    INTEGER, INTEGER, INTEGER[]
) TO plataforma_backend;

GRANT EXECUTE ON FUNCTION public.entregar_intento(
    INTEGER, INTEGER
) TO plataforma_backend;

GRANT EXECUTE ON FUNCTION public.calificar_intento(
    INTEGER
) TO plataforma_backend;

COMMIT;