\set ON_ERROR_STOP on
\prompt 'Hash bcrypt del estudiante demo: ' demo_hash
\encoding UTF8

BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE TEMP TABLE parametros_seed_003 (password_hash TEXT NOT NULL) ON COMMIT DROP;
INSERT INTO parametros_seed_003 VALUES (:'demo_hash');
\unset demo_hash

DO $seed$
DECLARE
    v_hash TEXT;
    v_admin INTEGER;
    v_rol INTEGER;
    v_estudiante INTEGER;
    v_curso INTEGER;
    v_edicion INTEGER;
    v_seccion INTEGER;
    v_inscripcion INTEGER;
    v_modulo INTEGER;
    v_tema INTEGER;
    v_actividad INTEGER;
    v_pregunta INTEGER;
    v_intento INTEGER;
    v_opciones INTEGER[];
    v_respuesta RECORD;
    v_n INTEGER;
    v_j INTEGER;
    v_resultado RECORD;
    v_ahora TIMESTAMPTZ := clock_timestamp();
BEGIN
    PERFORM pg_advisory_xact_lock(3003, 2026);
    SELECT password_hash INTO STRICT v_hash FROM parametros_seed_003;
    IF v_hash !~ '^\$2[aby]\$10\$[./A-Za-z0-9]{53}$' THEN
        RAISE EXCEPTION 'Se esperaba un hash bcrypt de costo 10. Genérelo con bcryptjs.';
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE lower(email) = 'estudiante.demo@example.com')
       OR EXISTS (SELECT 1 FROM cursos WHERE codigo = 'DEMO-003') THEN
        RAISE EXCEPTION 'Ya existe la cuenta o el curso DEMO-003. No se sobrescriben. Use una base de pruebas nueva para reconstruir la demo.';
    END IF;

    SELECT u.id INTO v_admin
    FROM usuarios u
    JOIN usuario_roles ur ON ur.usuario_id = u.id AND ur.activo
    JOIN roles r ON r.id = ur.rol_id
    WHERE u.activo AND r.codigo = 'ADMINISTRADOR'
    ORDER BY u.id LIMIT 1;
    IF v_admin IS NULL THEN
        RAISE EXCEPTION 'Falta un administrador activo. Ejecute primero el seed inicial de usuarios y roles.';
    END IF;
    SELECT id INTO STRICT v_rol FROM roles WHERE codigo = 'ESTUDIANTE';

    INSERT INTO usuarios (nombre, apellido, email, password_hash)
    VALUES ('Estudiante', 'Demo Equipo', 'estudiante.demo@example.com', v_hash)
    RETURNING id INTO v_estudiante;
    INSERT INTO usuario_roles (usuario_id, rol_id, asignado_por)
    VALUES (v_estudiante, v_rol, v_admin);

    INSERT INTO cursos (codigo, nombre, descripcion, estado, creado_por)
    VALUES ('DEMO-003', 'Matemática: integración de actividades',
        'Datos de demostración para backend y motor adaptativo.', 'ACTIVO', v_admin)
    RETURNING id INTO v_curso;

    INSERT INTO ediciones_curso (curso_id, codigo, nombre, fecha_inicio, fecha_fin,
        inscripcion_desde, inscripcion_hasta, estado, creado_por)
    VALUES (v_curso, 'DEMO-003-ED-01', 'Edición de integración',
        v_ahora - INTERVAL '1 day', v_ahora + INTERVAL '1 year',
        v_ahora - INTERVAL '7 days', v_ahora + INTERVAL '1 year', 'ABIERTA', v_admin)
    RETURNING id INTO v_edicion;

    INSERT INTO secciones (edicion_id, codigo, cupo_maximo, estado, creado_por)
    VALUES (v_edicion, 'DEMO-SEC-1', 30, 'ABIERTA', v_admin)
    RETURNING id INTO v_seccion;
    INSERT INTO inscripciones (estudiante_id, edicion_id, seccion_id, origen, registrado_por)
    VALUES (v_estudiante, v_edicion, v_seccion, 'ADMINISTRATIVA', v_admin)
    RETURNING id INTO v_inscripcion;

    INSERT INTO modulos (curso_id, nombre, descripcion, orden, estado, creado_por)
    VALUES (v_curso, 'Fundamentos', 'Módulo de integración.', 1, 'PUBLICADO', v_admin)
    RETURNING id INTO v_modulo;
    INSERT INTO temas (modulo_id, nombre, descripcion, orden, estado, creado_por)
    VALUES (v_modulo, 'Operaciones y números pares', 'Tema de demostración.', 1, 'PUBLICADO', v_admin)
    RETURNING id INTO v_tema;

    FOR v_n IN 1..3 LOOP
        INSERT INTO actividades (seccion_id, tema_id, titulo, instrucciones, finalidad,
            max_intentos, duracion_minutos, disponible_desde, disponible_hasta, creado_por)
        VALUES (v_seccion, v_tema,
            CASE v_n WHEN 1 THEN 'DEMO-003: práctica con promedio'
                     WHEN 2 THEN 'DEMO-003: evaluación calificada'
                     ELSE 'DEMO-003: práctica disponible' END,
            'Responde las dos preguntas. En selección múltiple debes marcar todas las correctas y ninguna incorrecta.',
            CASE WHEN v_n = 2 THEN 'EVALUACION' ELSE 'PRACTICA' END,
            NULL, 30, v_ahora - INTERVAL '1 minute', v_ahora + INTERVAL '1 year', v_admin)
        RETURNING id INTO v_actividad;

        INSERT INTO preguntas (actividad_id, enunciado, tipo, orden, puntaje_maximo)
        VALUES (v_actividad, '¿Cuánto es 2 + 2?', 'SELECCION_UNICA', 1, 10)
        RETURNING id INTO v_pregunta;
        INSERT INTO opciones_respuestas (pregunta_id, texto, orden, es_correcta)
        VALUES (v_pregunta, '4', 1, TRUE), (v_pregunta, '5', 2, FALSE);

        INSERT INTO preguntas (actividad_id, enunciado, tipo, orden, puntaje_maximo)
        VALUES (v_actividad, 'Selecciona los números pares.', 'SELECCION_MULTIPLE', 2, 10)
        RETURNING id INTO v_pregunta;
        INSERT INTO opciones_respuestas (pregunta_id, texto, orden, es_correcta)
        VALUES (v_pregunta, '2', 1, TRUE), (v_pregunta, '4', 2, TRUE),
               (v_pregunta, '3', 3, FALSE);

        UPDATE actividades SET estado = 'PUBLICADO', actualizado_en = clock_timestamp()
        WHERE id = v_actividad;

        IF v_n = 3 THEN CONTINUE; END IF;

        FOR v_j IN 1..(CASE WHEN v_n = 1 THEN 2 ELSE 1 END) LOOP
            v_intento := public.iniciar_intento(v_actividad, v_inscripcion, v_estudiante);
            FOR v_respuesta IN
                SELECT id, pregunta_id FROM respuestas WHERE intento_id = v_intento ORDER BY id
            LOOP
                SELECT array_agg(id ORDER BY orden) INTO v_opciones
                FROM opciones_respuestas
                WHERE pregunta_id = v_respuesta.pregunta_id
                  AND es_correcta = NOT (v_n = 1 AND v_j = 1);
                PERFORM public.guardar_opciones_respuesta(v_respuesta.id, v_estudiante, v_opciones);
            END LOOP;
            PERFORM public.entregar_intento(v_intento, v_estudiante);
            PERFORM public.calificar_intento(v_intento);
        END LOOP;

        SELECT * INTO STRICT v_resultado FROM resultados_actividades
        WHERE actividad_id = v_actividad AND inscripcion_id = v_inscripcion;
        IF v_n = 1 AND (
            v_resultado.intentos_calificados IS DISTINCT FROM 2::BIGINT
            OR v_resultado.promedio_porcentaje IS DISTINCT FROM 50::NUMERIC
            OR v_resultado.nota_academica_porcentaje IS NOT NULL
        ) THEN RAISE EXCEPTION 'El promedio de práctica no coincide con el esperado.'; END IF;
        IF v_n = 2 AND (
            v_resultado.intentos_calificados IS DISTINCT FROM 1::BIGINT
            OR v_resultado.promedio_porcentaje IS DISTINCT FROM 100::NUMERIC
            OR v_resultado.nota_academica_porcentaje IS DISTINCT FROM 100::NUMERIC
        ) THEN RAISE EXCEPTION 'La nota de evaluación no coincide con la esperada.'; END IF;
    END LOOP;
    RAISE NOTICE 'Seed creado: estudiante %, inscripción %, curso %.', v_estudiante, v_inscripcion, v_curso;
END;
$seed$;

COMMIT;

SELECT u.email, a.titulo, a.finalidad,
       COALESCE(ra.intentos_calificados, 0) AS intentos_calificados,
       ra.promedio_porcentaje, ra.nota_academica_porcentaje
FROM usuarios u
JOIN inscripciones i ON i.estudiante_id = u.id
JOIN secciones s ON s.id = i.seccion_id
JOIN ediciones_curso e ON e.id = s.edicion_id
JOIN cursos c ON c.id = e.curso_id
JOIN actividades a ON a.seccion_id = s.id
LEFT JOIN resultados_actividades ra
    ON ra.actividad_id = a.id AND ra.inscripcion_id = i.id
WHERE u.email = 'estudiante.demo@example.com' AND c.codigo = 'DEMO-003'
ORDER BY a.id;
