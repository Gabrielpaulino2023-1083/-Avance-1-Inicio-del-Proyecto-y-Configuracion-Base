\set ON_ERROR_STOP on
\encoding UTF8
\prompt 'Hash bcrypt del administrador demo: ' admin_hash

-- Solo desarrollo. Ejecutar como postgres, después del seed inicial.
-- No reutiliza ni promueve cuentas existentes. No cambia roles PostgreSQL.
BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;
CREATE TEMP TABLE parametros_admin_demo (hash TEXT NOT NULL) ON COMMIT DROP;
INSERT INTO parametros_admin_demo VALUES (:'admin_hash');
\unset admin_hash

DO $$
DECLARE
    v_hash TEXT;
    v_admin INTEGER;
    v_rol INTEGER;
    v_creador INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(3005, 2026);
    SELECT hash INTO STRICT v_hash FROM parametros_admin_demo;
    IF v_hash !~ '^\$2[aby]\$10\$[./A-Za-z0-9]{53}$' THEN
        RAISE EXCEPTION 'Se requiere un hash bcrypt de costo 10 generado por el backend.';
    END IF;
    IF EXISTS (SELECT 1 FROM public.usuarios WHERE lower(email) = 'administrador.demo@example.com') THEN
        RAISE EXCEPTION 'La cuenta demo ya existe; no se sobrescribe ni se modifican sus roles.';
    END IF;
    SELECT id INTO STRICT v_rol FROM public.roles WHERE codigo = 'ADMINISTRADOR';
    SELECT u.id INTO v_creador
    FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.activo AND ur.activo AND ur.rol_id = v_rol ORDER BY u.id LIMIT 1;
    IF v_creador IS NULL THEN
        RAISE EXCEPTION 'Falta el administrador inicial; ejecutar primero datos_prueba.sql.';
    END IF;
    INSERT INTO public.usuarios(nombre, apellido, email, password_hash)
    VALUES ('Administrador', 'Demo Equipo', 'administrador.demo@example.com', v_hash)
    RETURNING id INTO v_admin;
    INSERT INTO public.usuario_roles(usuario_id, rol_id, asignado_por)
    VALUES (v_admin, v_rol, v_creador);
    RAISE NOTICE 'Administrador demo creado. ID: %.', v_admin;
END;
$$;
COMMIT;

SELECT u.id, u.email, u.activo, r.codigo AS rol
FROM public.usuarios u
JOIN public.usuario_roles ur ON ur.usuario_id = u.id AND ur.activo
JOIN public.roles r ON r.id = ur.rol_id
WHERE u.email = 'administrador.demo@example.com';
