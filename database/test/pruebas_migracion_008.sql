\set ON_ERROR_STOP on
\encoding UTF8
-- Ejecutar como postgres tras 008 y los seeds DEMO-SQL-007 y DEMO-006.
-- Usar el seed SQL sin completar su evaluación pendiente, o una base de validación nueva.
BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;
-- Caso homónimo: si existe DEMO-003, sus intentos no deben mezclarse.
UPDATE temas t SET nombre='SQL JOIN'
FROM modulos m JOIN cursos c ON c.id=m.curso_id
WHERE t.modulo_id=m.id AND c.codigo='DEMO-003' AND t.nombre='Operaciones y números pares';
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE v_actor integer; v_otro_estudiante integer; v_docente integer; v_curso integer; v_inscripcion integer;
        v_tema integer; v_evaluacion integer; v_semana date;
        v_otro integer; v_cuenta bigint; v_puntaje numeric;
BEGIN
    SELECT id INTO STRICT v_actor FROM usuarios WHERE email='estudiante.demo@example.com';
    SELECT id INTO STRICT v_otro_estudiante FROM usuarios WHERE email='estudiante@example.com';
    SELECT id INTO STRICT v_docente FROM usuarios WHERE email='docente.demo@example.com';
    SELECT i.inscripcion_id,i.curso_id INTO STRICT v_inscripcion,v_curso
    FROM listar_inscripciones_estudiante(v_actor) i WHERE i.codigo='DEMO-SQL-007';
    SELECT t.id INTO STRICT v_tema FROM temas t JOIN modulos m ON m.id=t.modulo_id
    WHERE m.curso_id=v_curso AND t.nombre='SQL JOIN';
    SELECT a.id INTO STRICT v_evaluacion FROM actividades a JOIN inscripciones i ON i.seccion_id=a.seccion_id
    WHERE i.id=v_inscripcion AND a.tema_id=v_tema AND a.finalidad='EVALUACION';
    SELECT (e.fecha_inicio AT TIME ZONE 'America/Santo_Domingo')::date+14 INTO STRICT v_semana
    FROM inscripciones i JOIN ediciones_curso e ON e.id=i.edicion_id WHERE i.id=v_inscripcion;
    IF NOT EXISTS(SELECT 1 FROM listar_cursos_administrables(v_docente) WHERE codigo='DEMO-006' AND puede_editar_contenido)
       OR EXISTS(SELECT 1 FROM listar_cursos_administrables(v_docente) WHERE curso_id=v_curso)
    THEN RAISE EXCEPTION 'Selector docente incorrecto'; END IF;
    BEGIN
        PERFORM listar_cursos_administrables(v_actor);
        RAISE EXCEPTION 'Estudiante pudo acceder al selector docente';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    IF NOT EXISTS(SELECT 1 FROM listar_resultados_estudiante(v_actor,v_inscripcion)
                  WHERE actividad_id=v_evaluacion AND intentos_calificados=0 AND nota_academica_porcentaje IS NULL)
    THEN RAISE EXCEPTION 'Evaluacion pendiente no aparece correctamente'; END IF;
    IF (SELECT count(*) FROM listar_actividad_reciente_estudiante(v_actor,v_inscripcion,3))<>3
    THEN RAISE EXCEPTION 'Actividad reciente no respeta el limite'; END IF;
    IF NOT EXISTS(SELECT 1 FROM listar_progreso_estudiante(v_actor,v_inscripcion)
        WHERE tema_id=v_tema AND actividades_publicadas=2 AND actividades_calificadas=1
          AND progreso_porcentaje=50 AND NOT completado)
    THEN RAISE EXCEPTION 'Progreso JOIN incorrecto'; END IF;
    IF (SELECT sum(intentos_entregados) FROM listar_minutos_intentos_estudiante(v_actor,v_inscripcion,v_semana-7,v_semana)) IS DISTINCT FROM 3::numeric
       OR (SELECT sum(intentos_entregados) FROM listar_minutos_intentos_estudiante(v_actor,v_inscripcion,v_semana,v_semana+7)) IS DISTINCT FROM 6::numeric
    THEN RAISE EXCEPTION 'Separacion de semanas incorrecta'; END IF;
    SELECT count(*),round(avg(score_percentage),2),sum(errors) INTO v_cuenta,v_puntaje,v_otro
    FROM listar_interacciones_motor_estudiante(v_actor,v_inscripcion,v_tema);
    IF v_cuenta<>3 OR v_puntaje IS DISTINCT FROM 16.67 OR v_otro IS DISTINCT FROM 10
    THEN RAISE EXCEPTION 'Interacciones JOIN incorrectas'; END IF;
    BEGIN
        PERFORM listar_interacciones_motor_estudiante(v_otro_estudiante,v_inscripcion,v_tema);
        RAISE EXCEPTION 'Se permitio leer otra inscripcion';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM listar_minutos_intentos_estudiante(v_actor,v_inscripcion,v_semana,v_semana+367);
        RAISE EXCEPTION 'Se permitio un rango excesivo';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    IF has_function_privilege(current_user,'public.validar_contexto_resultados(integer,integer)','EXECUTE')
    THEN RAISE EXCEPTION 'Auxiliar privado expuesto'; END IF;
    RAISE NOTICE 'PRUEBAS 008 COMPLETADAS: selector, contexto, tablero, motor y permisos.';
END;
$$;
ROLLBACK;
