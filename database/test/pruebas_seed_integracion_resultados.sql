\set ON_ERROR_STOP on
\encoding UTF8
\if :{?demo_email}
\else
  \set demo_email 'estudiante.demo@example.com'
\endif

BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL search_path = pg_catalog, public, pg_temp;
SET LOCAL TIME ZONE 'America/Santo_Domingo';
SELECT set_config('seed.demo_email',lower(btrim(:'demo_email')),true);

DO $$
DECLARE v_usuario INTEGER; v_curso INTEGER; v_inscripcion INTEGER; v_modulo INTEGER;
        v_semana TIMESTAMPTZ; v_fila RECORD; v_n BIGINT; v_esperado NUMERIC;
BEGIN
    SELECT u.id,c.id,i.id,m.id,e.fecha_inicio+INTERVAL '14 days'
    INTO STRICT v_usuario,v_curso,v_inscripcion,v_modulo,v_semana
    FROM public.usuarios u JOIN public.inscripciones i ON i.estudiante_id=u.id
    JOIN public.ediciones_curso e ON e.id=i.edicion_id
    JOIN public.cursos c ON c.id=e.curso_id
    JOIN public.modulos m ON m.curso_id=c.id AND m.orden=1
    WHERE lower(u.email)=current_setting('seed.demo_email') AND c.codigo='DEMO-SQL-007';
    IF NOT EXISTS (SELECT 1 FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id
        JOIN public.roles r ON r.id=ur.rol_id WHERE u.id=v_usuario AND u.activo AND ur.activo AND r.codigo='ESTUDIANTE') THEN
        RAISE EXCEPTION 'FALLO: cuenta o rol del estudiante inactivo.';
    END IF;
    RAISE NOTICE 'OK SEED: estudiante existente con rol activo e inscripcion identificada.';

    SELECT COUNT(*) INTO v_n FROM public.temas WHERE modulo_id=v_modulo
        AND estado='PUBLICADO' AND nombre IN ('SQL SELECT','SQL WHERE','SQL JOIN');
    IF v_n<>3 THEN RAISE EXCEPTION 'FALLO: se esperaban los tres temas publicados.'; END IF;
    SELECT COUNT(*) INTO v_n FROM public.actividades a JOIN public.temas t ON t.id=a.tema_id
    WHERE t.modulo_id=v_modulo AND a.estado='PUBLICADO' AND a.titulo IN (
        'DEMO-SQL-007: SQL SELECT - evaluacion','DEMO-SQL-007: SQL WHERE - evaluacion',
        'DEMO-SQL-007: SQL JOIN - practica','DEMO-SQL-007: SQL JOIN - evaluacion disponible');
    IF v_n<>4 THEN RAISE EXCEPTION 'FALLO: se esperaban las cuatro actividades publicadas.'; END IF;
    RAISE NOTICE 'OK SEED: temas y actividades publicadas.';

    SELECT COUNT(*) INTO v_n FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
    WHERE it.inscripcion_id=v_inscripcion AND it.numero_intento BETWEEN 1 AND 3
      AND a.titulo IN ('DEMO-SQL-007: SQL SELECT - evaluacion','DEMO-SQL-007: SQL WHERE - evaluacion','DEMO-SQL-007: SQL JOIN - practica')
      AND it.estado='CALIFICADO';
    IF v_n<>9 THEN RAISE EXCEPTION 'FALLO: faltan los nueve intentos historicos calificados.'; END IF;
    RAISE NOTICE 'OK SEED: nueve intentos historicos calificados.';

    FOR v_fila IN
        SELECT it.*,a.titulo,a.disponible_desde,a.disponible_hasta,i.inscrito_en,t.nombre AS tema
        FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
        JOIN public.temas t ON t.id=a.tema_id JOIN public.inscripciones i ON i.id=it.inscripcion_id
        WHERE it.inscripcion_id=v_inscripcion AND it.numero_intento BETWEEN 1 AND 3
          AND a.titulo IN ('DEMO-SQL-007: SQL SELECT - evaluacion','DEMO-SQL-007: SQL WHERE - evaluacion','DEMO-SQL-007: SQL JOIN - practica')
    LOOP
        v_esperado:=CASE v_fila.tema
            WHEN 'SQL SELECT' THEN CASE WHEN v_fila.numero_intento=1 THEN 30 ELSE 40 END
            WHEN 'SQL WHERE' THEN CASE WHEN v_fila.numero_intento=1 THEN 20 ELSE 30 END
            WHEN 'SQL JOIN' THEN CASE WHEN v_fila.numero_intento=1 THEN 0 ELSE 10 END END;
        IF v_fila.puntaje_obtenido IS DISTINCT FROM v_esperado OR v_fila.puntaje_maximo<>40 THEN
            RAISE EXCEPTION 'FALLO: puntaje inesperado en intento %.',v_fila.id;
        END IF;
        IF v_fila.iniciado_en<v_fila.inscrito_en OR v_fila.iniciado_en<v_fila.disponible_desde
           OR v_fila.entregado_en<=v_fila.iniciado_en OR v_fila.entregado_en>v_fila.vence_en
           OR v_fila.calificado_en<v_fila.entregado_en OR v_fila.calificado_en>clock_timestamp()
           OR v_fila.entregado_en>=v_fila.disponible_hasta THEN
            RAISE EXCEPTION 'FALLO: cronologia incoherente en intento %.',v_fila.id;
        END IF;
        IF (SELECT COUNT(*) FROM public.respuestas r WHERE r.intento_id=v_fila.id)<>4
           OR EXISTS (SELECT 1 FROM public.respuestas r WHERE r.intento_id=v_fila.id
                AND (r.calificado_en IS DISTINCT FROM v_fila.calificado_en
                     OR r.creado_en IS DISTINCT FROM v_fila.iniciado_en
                     OR r.actualizado_en IS DISTINCT FROM v_fila.calificado_en)) THEN
            RAISE EXCEPTION 'FALLO: respuestas o fechas incompletas para intento %.',v_fila.id;
        END IF;
        IF (SELECT SUM(r.puntaje_obtenido) FROM public.respuestas r WHERE r.intento_id=v_fila.id) IS DISTINCT FROM v_esperado THEN
            RAISE EXCEPTION 'FALLO: suma de respuestas no coincide.';
        END IF;
        IF date_trunc('week',v_fila.iniciado_en) IS DISTINCT FROM
            (CASE WHEN v_fila.numero_intento=1 THEN v_semana-INTERVAL '7 days' ELSE v_semana END) THEN
            RAISE EXCEPTION 'FALLO: distribucion semanal incorrecta.';
        END IF;
    END LOOP;
    RAISE NOTICE 'OK SEED: puntajes, respuestas y fechas historicas coherentes en dos semanas.';

    FOR v_fila IN
        SELECT t.nombre,ROUND(AVG(it.puntaje_obtenido*100.0/it.puntaje_maximo),2) AS promedio
        FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
        JOIN public.temas t ON t.id=a.tema_id
        WHERE it.inscripcion_id=v_inscripcion AND it.numero_intento BETWEEN 1 AND 3
          AND a.titulo IN ('DEMO-SQL-007: SQL SELECT - evaluacion','DEMO-SQL-007: SQL WHERE - evaluacion','DEMO-SQL-007: SQL JOIN - practica')
        GROUP BY t.nombre
    LOOP
        v_esperado:=CASE v_fila.nombre WHEN 'SQL SELECT' THEN 91.67 WHEN 'SQL WHERE' THEN 66.67 ELSE 16.67 END;
        IF v_fila.promedio IS DISTINCT FROM v_esperado THEN RAISE EXCEPTION 'FALLO: promedio historico de %.',v_fila.nombre; END IF;
    END LOOP;
    RAISE NOTICE 'OK SEED: promedios historicos SELECT 91.67, WHERE 66.67, JOIN 16.67.';
END;
$$;

SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE v_usuario INTEGER; v_curso INTEGER; v_modulo INTEGER; v_inscripcion INTEGER;
        v_tema RECORD; v_n BIGINT;
BEGIN
    SELECT u.id,c.id,m.id,i.id INTO STRICT v_usuario,v_curso,v_modulo,v_inscripcion
    FROM public.usuarios u JOIN public.inscripciones i ON i.estudiante_id=u.id
    JOIN public.ediciones_curso e ON e.id=i.edicion_id JOIN public.cursos c ON c.id=e.curso_id
    JOIN public.modulos m ON m.curso_id=c.id AND m.orden=1
    WHERE lower(u.email)=current_setting('seed.demo_email') AND c.codigo='DEMO-SQL-007';
    SELECT COUNT(*) INTO v_n FROM public.listar_modulos_publicados_estudiante(v_usuario,v_curso);
    IF v_n<1 THEN RAISE EXCEPTION 'FALLO: 007 no devuelve modulos.'; END IF;
    SELECT COUNT(*) INTO v_n FROM public.listar_temas_publicados_estudiante(v_usuario,v_modulo)
    WHERE nombre IN ('SQL SELECT','SQL WHERE','SQL JOIN');
    IF v_n<>3 THEN RAISE EXCEPTION 'FALLO: 007 no devuelve los tres temas.'; END IF;
    FOR v_tema IN SELECT * FROM public.listar_temas_publicados_estudiante(v_usuario,v_modulo)
        WHERE nombre IN ('SQL SELECT','SQL WHERE','SQL JOIN') LOOP
        SELECT COUNT(*) INTO v_n FROM public.listar_actividades_publicadas_estudiante(v_usuario,v_inscripcion,v_tema.id);
        IF v_n<(CASE WHEN v_tema.nombre='SQL JOIN' THEN 2 ELSE 1 END) THEN
            RAISE EXCEPTION 'FALLO: 007 no devuelve actividades para %.',v_tema.nombre;
        END IF;
    END LOOP;
    RAISE NOTICE 'OK SEED: lectura de 007 comprobada como plataforma_backend.';
    RAISE NOTICE 'PRUEBAS SEED INTEGRACION COMPLETADAS.';
END;
$$;
ROLLBACK;
