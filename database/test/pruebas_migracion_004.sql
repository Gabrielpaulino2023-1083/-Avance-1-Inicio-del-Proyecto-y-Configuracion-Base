-- Pruebas basicas de la migracion 004. Ejecutar mediante psql como postgres.
-- Requisitos: 001, 002, 003, security/001_roles_permisos.sql y 004 aplicados.
-- No requiere seeds: prepara usuarios y organizacion propios dentro de BEGIN.
-- Desde la raiz del repositorio, en PowerShell:
-- psql -X -U postgres -d proyectofinal_validacion -f database/test/pruebas_migracion_004.sql
-- Ejecutar sin otra transaccion abierta y en una base local de pruebas.
-- Exito: avisos OK, resumen final y ROLLBACK. No quedan datos de prueba.
-- Las secuencias pueden avanzar; no se espera numeracion consecutiva.
-- Ante error inesperado en sesion interactiva: ejecutar ROLLBACK.
-- Casos ya probados manualmente; esta consolidacion debe ejecutarse localmente.
-- NO cubre fechas, estados, cuentas/roles inactivos ni concurrencia entre sesiones.

\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE TEMP TABLE contexto_prueba_004 (
    admin_id INTEGER NOT NULL,
    estudiante_uno_id INTEGER NOT NULL,
    estudiante_dos_id INTEGER NOT NULL,
    seccion_autonoma_id INTEGER NOT NULL,
    seccion_admin_id INTEGER NOT NULL,
    edicion_autonoma_id INTEGER NOT NULL,
    edicion_admin_id INTEGER NOT NULL
) ON COMMIT DROP;

DO $preparar$
DECLARE
    v_sufijo TEXT := txid_current()::TEXT;
    v_admin INTEGER;
    v_uno INTEGER;
    v_dos INTEGER;
    v_rol_admin INTEGER;
    v_rol_estudiante INTEGER;
    v_curso INTEGER;
    v_e1 INTEGER;
    v_e2 INTEGER;
    v_s1 INTEGER;
    v_s2 INTEGER;
    v_ahora TIMESTAMPTZ := clock_timestamp();
BEGIN
    IF current_user <> 'postgres' THEN
        RAISE EXCEPTION 'Ejecutar estas pruebas como postgres.';
    END IF;

    INSERT INTO public.roles (codigo, nombre)
    VALUES ('ADMINISTRADOR', 'Administrador'), ('ESTUDIANTE', 'Estudiante')
    ON CONFLICT (codigo) DO NOTHING;

    SELECT id INTO STRICT v_rol_admin FROM public.roles WHERE codigo = 'ADMINISTRADOR';
    SELECT id INTO STRICT v_rol_estudiante FROM public.roles WHERE codigo = 'ESTUDIANTE';

    -- Hash ficticio: las cuentas solo se utilizan en pruebas SQL y se revierten.
    INSERT INTO public.usuarios (nombre, apellido, email, password_hash)
    VALUES ('Temporal', 'Admin', 'test004.admin.' || v_sufijo || '@example.com', 'NO_LOGIN_SQL_TEST')
    RETURNING id INTO v_admin;
    INSERT INTO public.usuarios (nombre, apellido, email, password_hash)
    VALUES ('Temporal', 'Uno', 'test004.uno.' || v_sufijo || '@example.com', 'NO_LOGIN_SQL_TEST')
    RETURNING id INTO v_uno;
    INSERT INTO public.usuarios (nombre, apellido, email, password_hash)
    VALUES ('Temporal', 'Dos', 'test004.dos.' || v_sufijo || '@example.com', 'NO_LOGIN_SQL_TEST')
    RETURNING id INTO v_dos;

    INSERT INTO public.usuario_roles (usuario_id, rol_id, asignado_por)
    VALUES (v_admin, v_rol_admin, v_admin),
           (v_uno, v_rol_estudiante, v_admin),
           (v_dos, v_rol_estudiante, v_admin);

    INSERT INTO public.cursos (codigo, nombre, descripcion, estado, creado_por)
    VALUES ('TEST004-' || v_sufijo, 'Curso temporal', 'Prueba transaccional 004', 'ACTIVO', v_admin)
    RETURNING id INTO v_curso;

    INSERT INTO public.ediciones_curso (
        curso_id, codigo, nombre, fecha_inicio, fecha_fin,
        inscripcion_desde, inscripcion_hasta, estado, creado_por
    ) VALUES (
        v_curso, 'AUTO', 'Edicion autonoma', v_ahora,
        v_ahora + INTERVAL '30 days', v_ahora - INTERVAL '1 day',
        v_ahora + INTERVAL '7 days', 'ABIERTA', v_admin
    ) RETURNING id INTO v_e1;

    INSERT INTO public.ediciones_curso (
        curso_id, codigo, nombre, fecha_inicio, fecha_fin,
        inscripcion_desde, inscripcion_hasta, estado, creado_por
    ) VALUES (
        v_curso, 'ADMIN', 'Edicion administrativa', v_ahora,
        v_ahora + INTERVAL '30 days', v_ahora - INTERVAL '1 day',
        v_ahora + INTERVAL '7 days', 'ABIERTA', v_admin
    ) RETURNING id INTO v_e2;

    INSERT INTO public.secciones (edicion_id, codigo, cupo_maximo, estado, creado_por)
    VALUES (v_e1, 'SEC-1', 1, 'ABIERTA', v_admin) RETURNING id INTO v_s1;
    INSERT INTO public.secciones (edicion_id, codigo, cupo_maximo, estado, creado_por)
    VALUES (v_e2, 'SEC-1', 1, 'ABIERTA', v_admin) RETURNING id INTO v_s2;

    INSERT INTO contexto_prueba_004 VALUES (v_admin, v_uno, v_dos, v_s1, v_s2, v_e1, v_e2);
END;
$preparar$;

GRANT SELECT ON contexto_prueba_004 TO plataforma_backend;
SET LOCAL ROLE plataforma_backend;

DO $validar$
DECLARE
    c RECORD;
    v_fila public.inscripciones%ROWTYPE;
    v_total BIGINT;
    v_rechazado BOOLEAN;
BEGIN
    SELECT * INTO STRICT c FROM contexto_prueba_004;

    IF current_user <> 'plataforma_backend' THEN
        RAISE EXCEPTION 'No se esta probando con plataforma_backend.';
    END IF;
    IF has_column_privilege(current_user, 'public.inscripciones', 'estudiante_id', 'INSERT') THEN
        RAISE EXCEPTION 'El backend tiene INSERT directo no esperado sobre estudiante_id.';
    END IF;
    IF NOT has_function_privilege(current_user,
        'public.inscribir_estudiante(integer,integer,integer)', 'EXECUTE') THEN
        RAISE EXCEPTION 'Falta EXECUTE sobre inscribir_estudiante.';
    END IF;
    RAISE NOTICE 'OK 1: rol y permisos basicos.';

    SELECT * INTO STRICT v_fila FROM public.inscribir_estudiante(
        c.seccion_autonoma_id, c.estudiante_uno_id, c.estudiante_uno_id
    );
    IF v_fila.estudiante_id IS DISTINCT FROM c.estudiante_uno_id
       OR v_fila.registrado_por IS DISTINCT FROM c.estudiante_uno_id
       OR v_fila.seccion_id IS DISTINCT FROM c.seccion_autonoma_id
       OR v_fila.edicion_id IS DISTINCT FROM c.edicion_autonoma_id
       OR v_fila.estado IS DISTINCT FROM 'ACTIVA'
       OR v_fila.origen IS DISTINCT FROM 'AUTONOMA'
       OR v_fila.inscrito_en IS NULL OR v_fila.cerrado_en IS NOT NULL THEN
        RAISE EXCEPTION 'Resultado inesperado en inscripcion autonoma.';
    END IF;
    RAISE NOTICE 'OK 2: inscripcion autonoma.';

    v_rechazado := FALSE;
    BEGIN
        PERFORM public.inscribir_estudiante(
            c.seccion_autonoma_id, c.estudiante_uno_id, c.estudiante_uno_id
        );
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        IF SQLERRM <> 'El estudiante ya tiene una inscripcion en esta edicion.' THEN
            RAISE;
        END IF;
        v_rechazado := TRUE;
    END;
    IF NOT v_rechazado THEN RAISE EXCEPTION 'No se rechazo el duplicado.'; END IF;
    SELECT COUNT(*) INTO v_total FROM public.inscripciones
    WHERE edicion_id = c.edicion_autonoma_id;
    IF v_total <> 1 THEN RAISE EXCEPTION 'Conteo incorrecto tras duplicado.'; END IF;
    RAISE NOTICE 'OK 3: duplicado rechazado; se conserva una inscripcion.';

    v_rechazado := FALSE;
    BEGIN
        PERFORM public.inscribir_estudiante(
            c.seccion_admin_id, c.estudiante_dos_id, c.estudiante_uno_id
        );
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        IF SQLERRM <> 'Solo un administrador activo puede inscribir a otra persona.' THEN
            RAISE;
        END IF;
        v_rechazado := TRUE;
    END;
    IF NOT v_rechazado THEN RAISE EXCEPTION 'Se permitio un actor no autorizado.'; END IF;
    SELECT COUNT(*) INTO v_total FROM public.inscripciones
    WHERE edicion_id = c.edicion_admin_id;
    IF v_total <> 0 THEN RAISE EXCEPTION 'El rechazo dejo una inscripcion.'; END IF;
    RAISE NOTICE 'OK 4: estudiante no puede inscribir a otra persona.';

    SELECT * INTO STRICT v_fila FROM public.inscribir_estudiante(
        c.seccion_admin_id, c.estudiante_uno_id, c.admin_id
    );
    IF v_fila.estudiante_id IS DISTINCT FROM c.estudiante_uno_id
       OR v_fila.registrado_por IS DISTINCT FROM c.admin_id
       OR v_fila.seccion_id IS DISTINCT FROM c.seccion_admin_id
       OR v_fila.edicion_id IS DISTINCT FROM c.edicion_admin_id
       OR v_fila.estado IS DISTINCT FROM 'ACTIVA'
       OR v_fila.origen IS DISTINCT FROM 'ADMINISTRATIVA'
       OR v_fila.inscrito_en IS NULL OR v_fila.cerrado_en IS NOT NULL THEN
        RAISE EXCEPTION 'Resultado inesperado en inscripcion administrativa.';
    END IF;
    RAISE NOTICE 'OK 5: inscripcion administrativa.';

    v_rechazado := FALSE;
    BEGIN
        PERFORM public.inscribir_estudiante(
            c.seccion_admin_id, c.estudiante_dos_id, c.admin_id
        );
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        IF SQLERRM <> 'La seccion no tiene cupos disponibles.' THEN RAISE; END IF;
        v_rechazado := TRUE;
    END;
    IF NOT v_rechazado THEN RAISE EXCEPTION 'Se permitio exceder el cupo.'; END IF;
    RAISE NOTICE 'OK 6: cupo lleno rechazado incluso para administrador.';

    SELECT COUNT(*) INTO v_total FROM public.inscripciones
    WHERE seccion_id = c.seccion_admin_id AND estado = 'ACTIVA';
    IF v_total <> 1 THEN RAISE EXCEPTION 'Ocupacion final incorrecta.'; END IF;
    IF EXISTS (SELECT 1 FROM public.inscripciones
        WHERE estudiante_id = c.estudiante_dos_id
          AND edicion_id = c.edicion_admin_id) THEN
        RAISE EXCEPTION 'Se guardo la inscripcion rechazada por cupo.';
    END IF;
    RAISE NOTICE 'OK 7: un cupo y una inscripcion activa; sin inscripciones residuales.';
    RAISE NOTICE 'PRUEBAS 004 COMPLETADAS: todos los casos basicos incluidos pasaron.';
END;
$validar$;

ROLLBACK;
SELECT current_user AS usuario_tras_rollback;
