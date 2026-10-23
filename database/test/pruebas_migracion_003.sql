-- PRUEBAS DE REGRESION: migracion 003 y permisos.

\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = public, pg_catalog, pg_temp;
SET LOCAL client_min_messages = notice;

CREATE TEMP TABLE qa003_contexto (datos JSONB NOT NULL) ON COMMIT DROP;

CREATE FUNCTION pg_temp.qa003_comprobar(p_condicion BOOLEAN, p_nombre TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_condicion IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FALLO: %', p_nombre;
    END IF;
    RAISE NOTICE 'OK: %', p_nombre;
END;
$$;

-- Cada error esperado se captura en una subtransaccion. Se comprueban
-- tanto el SQLSTATE como un fragmento del mensaje para no aceptar otro error.
CREATE FUNCTION pg_temp.qa003_esperar_error(
    p_sql TEXT, p_estado TEXT, p_fragmento TEXT, p_nombre TEXT
)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_ocurrio BOOLEAN := FALSE;
    v_estado TEXT;
    v_mensaje TEXT;
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_estado = RETURNED_SQLSTATE,
            v_mensaje = MESSAGE_TEXT;
        v_ocurrio := TRUE;
        IF v_estado <> p_estado
           OR position(p_fragmento IN v_mensaje) = 0 THEN
            RAISE EXCEPTION 'FALLO [%]: error inesperado [%] %',
                p_nombre, v_estado, v_mensaje;
        END IF;
    END;
    IF NOT v_ocurrio THEN
        RAISE EXCEPTION 'FALLO [%]: la operacion debia ser rechazada.', p_nombre;
    END IF;
    RAISE NOTICE 'OK: %', p_nombre;
END;
$$;

-- Preparacion y comprobaciones de estructura como administrador.
DO $$
DECLARE
    v_admin INTEGER; v_alumno INTEGER; v_inscripcion INTEGER;
    v_seccion INTEGER; v_seccion2 INTEGER; v_tema INTEGER; v_curso INTEGER;
    v_otro_curso INTEGER; v_otro_modulo INTEGER; v_otro_tema INTEGER;
    v_actividad INTEGER; v_evaluacion INTEGER; v_vencida INTEGER;
    v_invalida INTEGER; v_pregunta INTEGER;
    v_q INTEGER[] := ARRAY[]::INTEGER[];
    v_prefijo TEXT := 'QA003-' || txid_current()::TEXT;
    v_a INTEGER; v_o INTEGER; v_n INTEGER;
BEGIN
    SELECT ad.id, u.id, i.id, s.id, s2.id, t.id, c.id
    INTO STRICT v_admin, v_alumno, v_inscripcion, v_seccion,
                v_seccion2, v_tema, v_curso
    FROM cursos c
    JOIN ediciones_curso e ON e.curso_id = c.id
    JOIN secciones s ON s.edicion_id = e.id
    JOIN secciones s2 ON s2.edicion_id = e.id AND s2.codigo = 'SEC 2'
    JOIN modulos m ON m.curso_id = c.id AND m.orden = 1
    JOIN temas t ON t.modulo_id = m.id AND t.orden = 1
    JOIN inscripciones i ON i.seccion_id = s.id AND i.estado = 'ACTIVA'
    JOIN usuarios u ON u.id = i.estudiante_id
    CROSS JOIN usuarios ad
    WHERE c.codigo = 'CALC-PRUEBA' AND e.codigo = 'ED-PRUEBA-01'
      AND s.codigo = 'SEC 1'
      AND u.email = 'estudiante@example.com'
      AND ad.email = 'admin@example.com';

    INSERT INTO cursos(codigo,nombre,descripcion,creado_por)
    VALUES(v_prefijo,'Curso temporal','Solo prueba',v_admin)
    RETURNING id INTO v_otro_curso;
    INSERT INTO modulos(curso_id,nombre,descripcion,orden,creado_por)
    VALUES(v_otro_curso,'Modulo temporal','Solo prueba',1,v_admin)
    RETURNING id INTO v_otro_modulo;
    INSERT INTO temas(modulo_id,nombre,descripcion,orden,creado_por)
    VALUES(v_otro_modulo,'Tema temporal','Solo prueba',1,v_admin)
    RETURNING id INTO v_otro_tema;

    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.modulos SET curso_id=%s WHERE id=%s',
        v_curso,v_otro_modulo),'P0001','No se permite modificar',
        'No trasladar modulo a otro curso');
    PERFORM pg_temp.qa003_esperar_error(format(
        'INSERT INTO public.actividades(seccion_id,tema_id,titulo,instrucciones,disponible_desde,creado_por) VALUES(%s,%s,''Incompatible'',''Prueba'',clock_timestamp(),%s)',
        v_seccion,v_otro_tema,v_admin),'P0001',
        'La sección y el tema deben pertenecer al mismo curso',
        'Rechazar actividad con tema de otro curso');

    INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,
        max_intentos,duracion_minutos,disponible_desde,creado_por)
    VALUES(v_seccion,v_tema,v_prefijo||'-practica','Solo prueba',2,60,
        clock_timestamp()-INTERVAL '1 minute',v_admin)
    RETURNING id INTO v_actividad;
    INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,
        finalidad,max_intentos,duracion_minutos,disponible_desde,creado_por)
    VALUES(v_seccion,v_tema,v_prefijo||'-evaluacion','Solo prueba',
        'EVALUACION',1,60,clock_timestamp()-INTERVAL '1 minute',v_admin)
    RETURNING id INTO v_evaluacion;
    INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,
        max_intentos,duracion_minutos,disponible_desde,creado_por)
    VALUES(v_seccion,v_tema,v_prefijo||'-vencida','Solo prueba',1,60,
        clock_timestamp()-INTERVAL '1 minute',v_admin)
    RETURNING id INTO v_vencida;
    INSERT INTO actividades(seccion_id,tema_id,titulo,instrucciones,
        disponible_desde,creado_por)
    VALUES(v_seccion,v_tema,v_prefijo||'-invalida','Solo prueba',
        clock_timestamp(),v_admin)
    RETURNING id INTO v_invalida;

    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET estado=''PUBLICADO'' WHERE id=%s',
        v_invalida),'P0001','sin preguntas','Publicacion sin preguntas');
    INSERT INTO preguntas(actividad_id,enunciado,orden,puntaje_maximo)
    VALUES(v_invalida,'Pregunta temporal',1,10) RETURNING id INTO v_pregunta;
    INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta)
    VALUES(v_pregunta,'A',1,TRUE);
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET estado=''PUBLICADO'' WHERE id=%s',
        v_invalida),'P0001','al menos dos opciones','Publicacion con una opcion');
    INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta)
    VALUES(v_pregunta,'B',2,TRUE);
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET estado=''PUBLICADO'' WHERE id=%s',
        v_invalida),'P0001','exactamente una opción correcta',
        'Seleccion unica con dos correctas');
    UPDATE preguntas SET tipo='SELECCION_MULTIPLE' WHERE id=v_pregunta;
    UPDATE opciones_respuestas SET es_correcta=FALSE
    WHERE pregunta_id=v_pregunta AND orden=2;
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET estado=''PUBLICADO'' WHERE id=%s',
        v_invalida),'P0001','al menos dos opciones correctas',
        'Seleccion multiple con una correcta');
    UPDATE opciones_respuestas SET es_correcta=TRUE
    WHERE pregunta_id=v_pregunta AND orden=2;
    UPDATE actividades SET estado='PUBLICADO' WHERE id=v_invalida;
    PERFORM pg_temp.qa003_comprobar(
        (SELECT estado='PUBLICADO' FROM actividades WHERE id=v_invalida),
        'Publicacion valida');
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.preguntas SET enunciado=''Cambio'' WHERE id=%s',v_pregunta),
        'P0001','Solo se pueden editar preguntas','Proteger pregunta publicada');
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.opciones_respuestas SET texto=''Cambio'' WHERE pregunta_id=%s',v_pregunta),
        'P0001','Solo se pueden editar opciones','Proteger opciones publicadas');

    -- Practica de cuatro preguntas; evaluacion y vencimiento de una.
    FOREACH v_a IN ARRAY ARRAY[v_actividad,v_evaluacion,v_vencida] LOOP
        FOR v_n IN 1..CASE WHEN v_a=v_actividad THEN 4 ELSE 1 END LOOP
            INSERT INTO preguntas(actividad_id,enunciado,tipo,orden,puntaje_maximo)
            VALUES(v_a,'Pregunta '||v_n,
                CASE WHEN v_n IN (2,3) THEN 'SELECCION_MULTIPLE'
                     ELSE 'SELECCION_UNICA' END,v_n,10)
            RETURNING id INTO v_pregunta;
            IF v_a=v_actividad THEN v_q:=array_append(v_q,v_pregunta); END IF;
            INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta)
            VALUES(v_pregunta,'A',1,TRUE),
                  (v_pregunta,'B',2,v_n IN (2,3));
            IF v_n IN (2,3) THEN
                INSERT INTO opciones_respuestas(pregunta_id,texto,orden,es_correcta)
                VALUES(v_pregunta,'C',3,FALSE);
            END IF;
        END LOOP;
        UPDATE actividades SET estado='PUBLICADO' WHERE id=v_a;
    END LOOP;

    -- Cada bloque fallido revierte tambien su cambio temporal de preparacion.
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.usuarios SET activo=FALSE WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_alumno,v_actividad,v_inscripcion,v_alumno),
        'P0001','inactiva','Cuenta inactiva no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE usuario_id=%s AND rol_id=(SELECT id FROM public.roles WHERE codigo=''ESTUDIANTE''); PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_alumno,v_actividad,v_inscripcion,v_alumno),
        'P0001','rol ESTUDIANTE activo','Rol desactivado no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.inscripciones SET estado=''RETIRADA'',cerrado_en=clock_timestamp() WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_inscripcion,v_actividad,v_inscripcion,v_alumno),
        'P0001','inscripción no está activa','Inscripcion retirada no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.actividades SET seccion_id=%s WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_seccion2,v_actividad,v_actividad,v_inscripcion,v_alumno),
        'P0001','no pertenece a la sección','Seccion incorrecta no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.actividades SET estado=''BORRADOR'' WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_actividad,v_actividad,v_inscripcion,v_alumno),
        'P0001','debe estar PUBLICADO','Actividad en borrador no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.actividades SET disponible_desde=clock_timestamp()+INTERVAL ''1 day'',disponible_hasta=clock_timestamp()+INTERVAL ''2 days'' WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_actividad,v_actividad,v_inscripcion,v_alumno),
        'P0001','todavía no está disponible','Disponibilidad futura no inicia');
    PERFORM pg_temp.qa003_esperar_error(format(
        'DO $caso$ BEGIN UPDATE public.actividades SET disponible_desde=clock_timestamp()-INTERVAL ''2 days'',disponible_hasta=clock_timestamp()-INTERVAL ''1 day'' WHERE id=%s; PERFORM public.iniciar_intento(%s,%s,%s); END; $caso$',
        v_actividad,v_actividad,v_inscripcion,v_alumno),
        'P0001','disponibilidad de la actividad terminó','Disponibilidad terminada no inicia');

    INSERT INTO qa003_contexto VALUES(jsonb_build_object(
        'admin',v_admin,'alumno',v_alumno,'inscripcion',v_inscripcion,
        'actividad',v_actividad,'evaluacion',v_evaluacion,'vencida',v_vencida,
        'preguntas',to_jsonb(v_q)));
END;
$$;

GRANT SELECT ON qa003_contexto TO plataforma_backend;
DO $$
BEGIN
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO plataforma_backend',
        (SELECT nspname FROM pg_namespace WHERE oid=pg_my_temp_schema()));
END;
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qa003_comprobar(BOOLEAN,TEXT)
TO plataforma_backend;
GRANT EXECUTE ON FUNCTION pg_temp.qa003_esperar_error(TEXT,TEXT,TEXT,TEXT)
TO plataforma_backend;

-- Recorrido y rechazos con los permisos efectivos del backend.
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE
    c JSONB; v_alumno INTEGER; v_inscripcion INTEGER; v_actividad INTEGER;
    v_otro INTEGER; v_i INTEGER; v_i2 INTEGER; v_eval INTEGER;
    v_r INTEGER; v_r2 INTEGER; v_o INTEGER; v_o2 INTEGER; v_extra INTEGER;
    v_opciones INTEGER[]; v_n INTEGER;
    v_primera intentos%ROWTYPE; v_segunda intentos%ROWTYPE;
    v_original intentos%ROWTYPE;
BEGIN
    SELECT datos INTO STRICT c FROM pg_temp.qa003_contexto;
    v_alumno:=(c->>'alumno')::INTEGER;
    v_otro:=(c->>'admin')::INTEGER;
    v_inscripcion:=(c->>'inscripcion')::INTEGER;
    v_actividad:=(c->>'actividad')::INTEGER;

    PERFORM pg_temp.qa003_comprobar(current_user='plataforma_backend',
        'Pruebas bajo el rol del backend');
    PERFORM pg_temp.qa003_esperar_error(
        'UPDATE public.intentos SET puntaje_obtenido=100 WHERE FALSE',
        '42501','permission denied','Escritura directa bloqueada');
    PERFORM pg_temp.qa003_esperar_error(
        'SELECT es_correcta FROM public.opciones_respuestas LIMIT 1',
        '42501','permission denied','Clave de correccion no legible directamente');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.iniciar_intento(%s,%s,%s)',v_actividad,v_inscripcion,v_otro),
        'P0001','no pertenece al estudiante','No iniciar para otro estudiante');

    v_i:=public.iniciar_intento(v_actividad,v_inscripcion,v_alumno);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT estado='EN_CURSO' AND puntaje_maximo=40
           AND vence_en-iniciado_en=INTERVAL '60 minutes'
         FROM intentos WHERE id=v_i)
        AND (SELECT COUNT(*)=4 FROM respuestas WHERE intento_id=v_i),
        'Inicio, plazo y cuatro respuestas vacias');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.iniciar_intento(%s,%s,%s)',v_actividad,v_inscripcion,v_alumno),
        'P0001','Ya existe un intento EN_CURSO','No duplicar intento abierto');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.calificar_intento(%s)',v_i),'P0001',
        'Solo se pueden calificar intentos ENTREGADOS','No calificar intento abierto');

    SELECT r.id INTO STRICT v_r FROM respuestas r JOIN preguntas p ON p.id=r.pregunta_id
    WHERE r.intento_id=v_i AND p.orden=1;
    SELECT o.id INTO STRICT v_o FROM opciones_respuestas o JOIN respuestas r ON r.pregunta_id=o.pregunta_id
    WHERE r.id=v_r AND o.orden=1;
    SELECT o.id INTO STRICT v_o2 FROM opciones_respuestas o JOIN respuestas r ON r.pregunta_id=o.pregunta_id
    WHERE r.id=v_r AND o.orden=2;
    SELECT r.id INTO STRICT v_r2 FROM respuestas r JOIN preguntas p ON p.id=r.pregunta_id
    WHERE r.intento_id=v_i AND p.orden=2;
    SELECT o.id INTO STRICT v_extra FROM opciones_respuestas o JOIN respuestas r ON r.pregunta_id=o.pregunta_id
    WHERE r.id=v_r2 AND o.orden=1;

    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,ARRAY[v_o]);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT COUNT(*)=1 AND MIN(opcion_id)=v_o FROM respuesta_opciones WHERE respuesta_id=v_r),
        'Guardar seleccion unica');
    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,ARRAY[v_o2]);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT COUNT(*)=1 AND MIN(opcion_id)=v_o2 FROM respuesta_opciones WHERE respuesta_id=v_r),
        'Reemplazar seleccion');
    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,ARRAY[]::INTEGER[]);
    PERFORM pg_temp.qa003_comprobar(
        NOT EXISTS(SELECT 1 FROM respuesta_opciones WHERE respuesta_id=v_r),
        'Limpiar seleccion');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[%s,%s])',v_r,v_alumno,v_o,v_o2),
        'P0001','admite como máximo una opción','No admitir varias en seleccion unica');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[%s])',v_r,v_alumno,v_extra),
        'P0001','Todas las opciones deben pertenecer','No admitir opcion de otra pregunta');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[%s,%s])',v_r2,v_alumno,v_extra,v_extra),
        'P0001','NULL ni repetidos','No admitir opciones repetidas');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[%s,NULL]::INTEGER[])',v_r2,v_alumno,v_extra),
        'P0001','NULL ni repetidos','No admitir elementos NULL');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[%s])',v_r,v_otro,v_o),
        'P0001','no pertenece al estudiante','No guardar respuesta ajena');

    -- Intento 1: incorrecta, multiple incompleta, multiple con extra, vacia.
    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,ARRAY[v_o2]);
    PERFORM public.guardar_opciones_respuesta(v_r2,v_alumno,ARRAY[v_extra]);
    SELECT r.id INTO STRICT v_r FROM respuestas r JOIN preguntas p ON p.id=r.pregunta_id
    WHERE r.intento_id=v_i AND p.orden=3;
    SELECT array_agg(id ORDER BY orden) INTO v_opciones
    FROM opciones_respuestas WHERE pregunta_id=(SELECT pregunta_id FROM respuestas WHERE id=v_r);
    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,v_opciones);
    v_primera:=public.entregar_intento(v_i,v_alumno);
    v_segunda:=public.entregar_intento(v_i,v_alumno);
    PERFORM pg_temp.qa003_comprobar(
        v_primera.estado='ENTREGADO' AND v_primera.motivo_entrega='MANUAL'
        AND v_primera.puntaje_obtenido IS NULL
        AND v_primera.entregado_en=v_segunda.entregado_en,
        'Entrega manual repetible sin cambiar fecha');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[]::INTEGER[])',v_r,v_alumno),
        'P0001','Solo se pueden guardar opciones de un intento EN_CURSO',
        'No guardar despues de entregar');
    v_original:=public.calificar_intento(v_i);
    PERFORM pg_temp.qa003_comprobar(v_original.estado='CALIFICADO'
        AND v_original.puntaje_obtenido=0
        AND (SELECT COUNT(*)=4 AND bool_and(puntaje_obtenido=0 AND calificado_en IS NOT NULL)
             FROM respuestas WHERE intento_id=v_i),
        'Cero por incorrecta, incompleta, opciones extra y respuesta vacia');
    v_segunda:=public.calificar_intento(v_i);
    PERFORM pg_temp.qa003_comprobar(v_original.calificado_en=v_segunda.calificado_en
        AND v_original.puntaje_obtenido=v_segunda.puntaje_obtenido,
        'Recalificar conserva fecha y puntaje');

    v_i2:=public.iniciar_intento(v_actividad,v_inscripcion,v_alumno);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT intentos_calificados=1 AND intentos_en_curso=1 AND promedio_porcentaje=0
         FROM resultados_actividades WHERE actividad_id=v_actividad AND inscripcion_id=v_inscripcion),
        'Intento abierto excluido del promedio');
    FOR v_n IN 1..4 LOOP
        SELECT r.id INTO STRICT v_r FROM respuestas r JOIN preguntas p ON p.id=r.pregunta_id
        WHERE r.intento_id=v_i2 AND p.orden=v_n;
        SELECT array_agg(o.id ORDER BY o.orden) INTO v_opciones
        FROM opciones_respuestas o
        WHERE o.pregunta_id=(SELECT pregunta_id FROM respuestas WHERE id=v_r)
          AND o.orden<=CASE WHEN v_n IN (2,3) THEN 2 ELSE 1 END;
        PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,v_opciones);
    END LOOP;
    PERFORM public.entregar_intento(v_i2,v_alumno);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT intentos_pendientes_calificacion=1 AND promedio_porcentaje=0
         FROM resultados_actividades WHERE actividad_id=v_actividad AND inscripcion_id=v_inscripcion),
        'Entregado sin calificar excluido del promedio');
    v_segunda:=public.calificar_intento(v_i2);
    PERFORM pg_temp.qa003_comprobar(v_segunda.puntaje_obtenido=40
        AND (SELECT intentos_calificados=2 AND promedio_porcentaje=50
             AND nota_academica_porcentaje IS NULL FROM resultados_actividades
             WHERE actividad_id=v_actividad AND inscripcion_id=v_inscripcion),
        'Seleccion exacta, promedio 50 y practica sin nota academica');
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.iniciar_intento(%s,%s,%s)',v_actividad,v_inscripcion,v_alumno),
        'P0001','agotó el máximo de intentos','Limite de intentos agotado');

    v_eval:=public.iniciar_intento((c->>'evaluacion')::INTEGER,v_inscripcion,v_alumno);
    SELECT r.id,o.id INTO STRICT v_r,v_o
    FROM respuestas r JOIN opciones_respuestas o ON o.pregunta_id=r.pregunta_id
    WHERE r.intento_id=v_eval AND o.orden=1;
    PERFORM public.guardar_opciones_respuesta(v_r,v_alumno,ARRAY[v_o]);
    PERFORM public.entregar_intento(v_eval,v_alumno);
    PERFORM public.calificar_intento(v_eval);
    PERFORM pg_temp.qa003_comprobar(
        (SELECT promedio_porcentaje=100 AND nota_academica_porcentaje=100
         FROM resultados_actividades WHERE actividad_id=(c->>'evaluacion')::INTEGER
           AND inscripcion_id=v_inscripcion),'Evaluacion con nota academica 100');
    PERFORM public.iniciar_intento((c->>'vencida')::INTEGER,v_inscripcion,v_alumno);
END;
$$;

RESET ROLE;

-- Proteccion del historial y simulacion local de vencimiento.
DO $$
DECLARE c JSONB; v_a INTEGER;
BEGIN
    SELECT datos INTO STRICT c FROM pg_temp.qa003_contexto;
    v_a:=(c->>'actividad')::INTEGER;
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET estado=''BORRADOR'' WHERE id=%s',v_a),
        'P0001','no puede volver a BORRADOR','No volver a borrador con intentos');
    PERFORM pg_temp.qa003_esperar_error(format(
        'UPDATE public.actividades SET max_intentos=10 WHERE id=%s',v_a),
        'P0001','No se puede modificar la configuración','No cambiar maximo con intentos');
    UPDATE actividades SET estado='ARCHIVADO' WHERE id=v_a;
    PERFORM pg_temp.qa003_comprobar(
        (SELECT estado='ARCHIVADO' FROM actividades WHERE id=v_a),
        'Archivar actividad con intentos');
    UPDATE intentos
    SET iniciado_en=clock_timestamp()-INTERVAL '30 minutes',
        vence_en=clock_timestamp()-INTERVAL '10 minutes'
    WHERE actividad_id=(c->>'vencida')::INTEGER
      AND inscripcion_id=(c->>'inscripcion')::INTEGER;
END;
$$;

SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE c JSONB; v_i INTEGER; v_r INTEGER; v_resultado intentos%ROWTYPE;
BEGIN
    SELECT datos INTO STRICT c FROM pg_temp.qa003_contexto;
    SELECT it.id,r.id INTO STRICT v_i,v_r FROM intentos it
    JOIN respuestas r ON r.intento_id=it.id
    WHERE it.actividad_id=(c->>'vencida')::INTEGER
      AND it.inscripcion_id=(c->>'inscripcion')::INTEGER;
    PERFORM pg_temp.qa003_esperar_error(format(
        'SELECT public.guardar_opciones_respuesta(%s,%s,ARRAY[]::INTEGER[])',
        v_r,(c->>'alumno')::INTEGER),'P0001','El intento venció',
        'No guardar despues del vencimiento');
    v_resultado:=public.entregar_intento(v_i,(c->>'alumno')::INTEGER);
    PERFORM pg_temp.qa003_comprobar(v_resultado.estado='ENTREGADO'
        AND v_resultado.motivo_entrega='VENCIMIENTO','Entrega solicitada despues de vencer');
    v_resultado:=public.calificar_intento(v_i);
    PERFORM pg_temp.qa003_comprobar(v_resultado.estado='CALIFICADO'
        AND v_resultado.puntaje_obtenido=0,'Calificar entrega vencida sin respuestas');
END;
$$;

RESET ROLE;
DO $$ BEGIN
    RAISE NOTICE 'PRUEBAS 003 COMPLETADAS: todos los casos incluidos pasaron.';
END; $$;
ROLLBACK;
