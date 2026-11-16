\set ON_ERROR_STOP on
\encoding UTF8
-- Desarrollo local: ejecutar como postgres. Requiere 001-007 y security/001.
-- Reutiliza el usuario existente; NUNCA cambia su hash, roles ni datos personales.
\if :{?demo_email}
\else
  \set demo_email 'estudiante.demo@example.com'
\endif
\if :{?fecha_referencia}
\else
  \set fecha_referencia ''
\endif

BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;
SET LOCAL TIME ZONE 'America/Santo_Domingo';
CREATE TEMP TABLE parametros_seed_integracion (
    email TEXT NOT NULL, referencia TIMESTAMPTZ NOT NULL
) ON COMMIT DROP;
INSERT INTO parametros_seed_integracion
VALUES(lower(btrim(:'demo_email')),COALESCE(NULLIF(:'fecha_referencia','')::TIMESTAMPTZ,clock_timestamp()));

-- Datos de autoría de la demo, no se publican como soluciones por 007.
CREATE TEMP TABLE plantilla_seed_integracion (
    tema_orden INTEGER, tema TEXT, finalidad TEXT, pregunta_orden INTEGER,
    enunciado TEXT, tipo TEXT, opciones JSONB
) ON COMMIT DROP;
INSERT INTO plantilla_seed_integracion VALUES
(1,'SQL SELECT','EVALUACION',1,'¿Para qué se utiliza SELECT?','SELECCION_UNICA','[{"texto": "Consultar datos", "es_correcta": true}, {"texto": "Eliminar una tabla", "es_correcta": false}, {"texto": "Crear un índice", "es_correcta": false}]'),
(1,'SQL SELECT','EVALUACION',2,'¿Qué devuelve SELECT nombre FROM usuarios?','SELECCION_UNICA','[{"texto": "La columna nombre de las filas consultadas", "es_correcta": true}, {"texto": "Todas las columnas de usuarios", "es_correcta": false}, {"texto": "La definición de la tabla", "es_correcta": false}]'),
(1,'SQL SELECT','EVALUACION',3,'¿Qué hace SELECT DISTINCT ciudad FROM usuarios?','SELECCION_UNICA','[{"texto": "Devuelve valores de ciudad sin duplicados", "es_correcta": true}, {"texto": "Elimina usuarios repetidos", "es_correcta": false}, {"texto": "Ordena siempre las ciudades de mayor a menor", "es_correcta": false}]'),
(1,'SQL SELECT','EVALUACION',4,'Selecciona las sentencias que son consultas SELECT.','SELECCION_MULTIPLE','[{"texto": "SELECT 1;", "es_correcta": true}, {"texto": "SELECT nombre FROM usuarios;", "es_correcta": true}, {"texto": "DELETE FROM usuarios;", "es_correcta": false}]'),
(2,'SQL WHERE','EVALUACION',1,'¿Cuál es la función principal de WHERE?','SELECCION_UNICA','[{"texto": "Filtrar filas según una condición", "es_correcta": true}, {"texto": "Ordenar el resultado", "es_correcta": false}, {"texto": "Cambiar el nombre de la tabla", "es_correcta": false}]'),
(2,'SQL WHERE','EVALUACION',2,'¿Qué condición selecciona edades de 18 años o más?','SELECCION_UNICA','[{"texto": "edad >= 18", "es_correcta": true}, {"texto": "edad > 18", "es_correcta": false}, {"texto": "edad < 18", "es_correcta": false}]'),
(2,'SQL WHERE','EVALUACION',3,'¿Cómo se comprueba que una columna no tiene valor?','SELECCION_UNICA','[{"texto": "columna IS NULL", "es_correcta": true}, {"texto": "columna = NULL", "es_correcta": false}, {"texto": "columna = 0", "es_correcta": false}]'),
(2,'SQL WHERE','EVALUACION',4,'¿Qué filas cumplen edad >= 18 AND activo = TRUE?','SELECCION_MULTIPLE','[{"texto": "edad 20, activo TRUE", "es_correcta": true}, {"texto": "edad 18, activo TRUE", "es_correcta": true}, {"texto": "edad 17, activo TRUE", "es_correcta": false}]'),
(3,'SQL JOIN','PRACTICA',1,'¿Qué filas devuelve un INNER JOIN con una condición ON?','SELECCION_UNICA','[{"texto": "Las combinaciones que cumplen la condición de unión", "es_correcta": true}, {"texto": "Todas las filas izquierdas aunque no coincidan", "es_correcta": false}, {"texto": "Siempre todas las combinaciones posibles", "es_correcta": false}]'),
(3,'SQL JOIN','PRACTICA',2,'En un LEFT JOIN, ¿qué ocurre con una fila izquierda sin coincidencia derecha?','SELECCION_UNICA','[{"texto": "Se conserva con NULL en las columnas derechas", "es_correcta": true}, {"texto": "Se elimina del resultado", "es_correcta": false}, {"texto": "Se duplica automáticamente", "es_correcta": false}]'),
(3,'SQL JOIN','PRACTICA',3,'Un pedido tiene tres detalles. ¿Cuántas filas produce su unión con esos detalles por pedido_id?','SELECCION_UNICA','[{"texto": "Tres", "es_correcta": true}, {"texto": "Una", "es_correcta": false}, {"texto": "Seis", "es_correcta": false}]'),
(3,'SQL JOIN','PRACTICA',4,'Dadas las FK pedidos.cliente_id → clientes.id e inscripciones.estudiante_id → usuarios.id, selecciona las uniones que usan esas relaciones.','SELECCION_MULTIPLE','[{"texto": "clientes JOIN pedidos ON clientes.id = pedidos.cliente_id", "es_correcta": true}, {"texto": "usuarios JOIN inscripciones ON usuarios.id = inscripciones.estudiante_id", "es_correcta": true}, {"texto": "clientes JOIN pedidos ON clientes.id = pedidos.id", "es_correcta": false}]');

DO $seed$
DECLARE
    v_email TEXT; v_ref TIMESTAMPTZ; v_now TIMESTAMPTZ := clock_timestamp();
    v_semana TIMESTAMPTZ; v_base TIMESTAMPTZ; v_margen INTERVAL;
    v_admin INTEGER; v_estudiante INTEGER; v_hash TEXT; v_curso INTEGER;
    v_edicion INTEGER; v_seccion INTEGER; v_inscripcion INTEGER; v_modulo INTEGER;
    v_tema INTEGER; v_actividad INTEGER; v_pregunta INTEGER; v_intento INTEGER;
    v_n INTEGER; v_a INTEGER; v_j INTEGER; v_correctas INTEGER; v_slot INTEGER;
    v_inicio TIMESTAMPTZ; v_entrega TIMESTAMPTZ; v_calificacion TIMESTAMPTZ; v_duracion INTERVAL;
    v_titulo TEXT; v_nombre_tema TEXT; v_finalidad TEXT;
    v_marca TEXT; v_descripcion TEXT; v_opciones INTEGER[];
    v_fila RECORD; v_respuesta RECORD; v_estado public.intentos;
BEGIN
    PERFORM pg_advisory_xact_lock(7007,2026);
    SELECT email,referencia INTO STRICT v_email,v_ref FROM parametros_seed_integracion;
    IF v_email='' THEN RAISE EXCEPTION 'El correo del estudiante es obligatorio.'; END IF;
    IF NOT isfinite(v_ref) OR v_ref>v_now THEN
        RAISE EXCEPTION 'La fecha de referencia debe ser finita y no estar en el futuro.';
    END IF;
    IF to_regprocedure('public.obtener_cuestionario_estudiante(integer,integer)') IS NULL THEN
        RAISE EXCEPTION 'Falta la migracion 007. Aplicar migraciones y permisos antes del seed.';
    END IF;

    SELECT u.id,u.password_hash INTO v_estudiante,v_hash
    FROM public.usuarios u WHERE lower(u.email)=v_email AND u.activo FOR SHARE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Falta el estudiante activo %. Cargue primero su seed de login; no se crea ni reactiva automaticamente.',v_email;
    END IF;
    IF v_hash !~ '^\$2[aby]\$(0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}$' THEN
        RAISE EXCEPTION 'La cuenta no tiene formato bcrypt valido. Configure su login antes de cargar esta demo.';
    END IF;
    PERFORM ur.id FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id
    WHERE ur.usuario_id=v_estudiante AND ur.activo AND r.codigo='ESTUDIANTE' FOR SHARE OF ur;
    IF NOT FOUND THEN RAISE EXCEPTION 'El usuario no tiene rol ESTUDIANTE activo.'; END IF;

    -- La marca distingue el curso de esta demo de un curso ajeno con el mismo codigo.
    v_marca:='SEED_INTEGRACION_SQL_V1; estudiante_id='||v_estudiante||'; fechas simuladas.';
    SELECT c.id,c.descripcion INTO v_curso,v_descripcion
    FROM public.cursos c WHERE c.codigo='DEMO-SQL-007' FOR UPDATE;
    IF FOUND THEN
        IF v_descripcion IS DISTINCT FROM v_marca THEN
            RAISE EXCEPTION 'DEMO-SQL-007 ya existe con otro propietario de demo o contenido. No se modifica.';
        END IF;
        -- No reescribir ni completar automaticamente una demo modificada o parcial.
        SELECT e.id,s.id,i.id,m.id INTO v_edicion,v_seccion,v_inscripcion,v_modulo
        FROM public.ediciones_curso e
        JOIN public.secciones s ON s.edicion_id=e.id AND s.codigo='DEMO-SQL-SEC-1'
        JOIN public.inscripciones i ON i.seccion_id=s.id AND i.edicion_id=e.id AND i.estudiante_id=v_estudiante
        JOIN public.modulos m ON m.curso_id=e.curso_id AND m.orden=1 AND m.nombre='Consultas SQL'
        WHERE e.curso_id=v_curso AND e.codigo='DEMO-SQL-ED-01';
        IF NOT FOUND OR (
            SELECT COUNT(*) FROM public.temas t
            JOIN public.actividades a ON a.tema_id=t.id AND a.seccion_id=v_seccion
            WHERE t.modulo_id=v_modulo AND (t.nombre,a.titulo) IN (
                ('SQL SELECT','DEMO-SQL-007: SQL SELECT - evaluacion'),
                ('SQL WHERE','DEMO-SQL-007: SQL WHERE - evaluacion'),
                ('SQL JOIN','DEMO-SQL-007: SQL JOIN - practica'),
                ('SQL JOIN','DEMO-SQL-007: SQL JOIN - evaluacion disponible')
            )
        )<>4 OR EXISTS (
            SELECT 1 FROM public.actividades a JOIN public.temas t ON t.id=a.tema_id
            WHERE t.modulo_id=v_modulo AND a.seccion_id=v_seccion
              AND a.titulo IN ('DEMO-SQL-007: SQL SELECT - evaluacion',
                  'DEMO-SQL-007: SQL WHERE - evaluacion','DEMO-SQL-007: SQL JOIN - practica')
              AND (SELECT COUNT(*) FROM public.intentos it
                   WHERE it.actividad_id=a.id AND it.inscripcion_id=v_inscripcion
                     AND it.numero_intento BETWEEN 1 AND 3 AND it.estado='CALIFICADO')<>3
        ) THEN
            RAISE EXCEPTION 'La demo existente esta incompleta o modificada. No se reconstruye ni se sobrescribe automaticamente.';
        END IF;
        RAISE NOTICE 'DEMO-SQL-007 ya existe. Sin cambios: se conservan fechas, notas, nuevos intentos y credenciales. Inscripcion %.',v_inscripcion;
        RETURN;
    END IF;

    SELECT u.id INTO v_admin FROM public.usuarios u
    JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
    JOIN public.roles r ON r.id=ur.rol_id AND r.codigo='ADMINISTRADOR'
    WHERE u.activo ORDER BY u.id LIMIT 1;
    IF v_admin IS NULL THEN RAISE EXCEPTION 'Falta un administrador activo para la autoria e inscripcion.'; END IF;

    -- Semana ISO local (lunes 00:00), no una ventana movil de siete dias.
    v_semana:=date_trunc('week',v_ref);
    v_base:=v_semana-INTERVAL '14 days';
    v_margen:=v_ref-v_semana;
    IF v_margen<INTERVAL '8 seconds' THEN
        RAISE EXCEPTION 'La referencia debe estar al menos ocho segundos despues del inicio del lunes para distribuir intentos sin fechas futuras.';
    END IF;

    INSERT INTO public.cursos(codigo,nombre,descripcion,estado,creado_por,creado_en,actualizado_en)
    VALUES('DEMO-SQL-007','SQL: integracion y resultados',v_marca,'ACTIVO',v_admin,v_base,v_base)
    RETURNING id INTO v_curso;
    INSERT INTO public.ediciones_curso(curso_id,codigo,nombre,fecha_inicio,fecha_fin,
        inscripcion_desde,inscripcion_hasta,estado,creado_por,creado_en)
    VALUES(v_curso,'DEMO-SQL-ED-01','Edicion de pruebas SQL',v_base,v_now+INTERVAL '1 year',
        v_base,v_now+INTERVAL '1 year','ABIERTA',v_admin,v_base) RETURNING id INTO v_edicion;
    INSERT INTO public.secciones(edicion_id,codigo,cupo_maximo,estado,creado_por,creado_en)
    VALUES(v_edicion,'DEMO-SQL-SEC-1',30,'ABIERTA',v_admin,v_base) RETURNING id INTO v_seccion;
    SELECT id INTO v_inscripcion FROM public.inscribir_estudiante(v_seccion,v_estudiante,v_admin);
    -- Solo la inscripcion NUEVA de esta demo recibe la fecha historica simulada.
    UPDATE public.inscripciones SET inscrito_en=v_base+INTERVAL '1 hour' WHERE id=v_inscripcion;
    INSERT INTO public.modulos(curso_id,nombre,descripcion,orden,estado,creado_por,creado_en,actualizado_en)
    VALUES(v_curso,'Consultas SQL','Datos simulados para integrar contenido, resultados y motor.',1,'PUBLICADO',v_admin,v_base,v_base)
    RETURNING id INTO v_modulo;

    FOR v_n IN 1..3 LOOP
        SELECT tema,finalidad INTO STRICT v_nombre_tema,v_finalidad
        FROM plantilla_seed_integracion WHERE tema_orden=v_n AND pregunta_orden=1;
        INSERT INTO public.temas(modulo_id,nombre,descripcion,orden,estado,creado_por,creado_en,actualizado_en)
        VALUES(v_modulo,v_nombre_tema,'Practica y evaluacion de '||v_nombre_tema||'.',v_n,'PUBLICADO',v_admin,v_base,v_base)
        RETURNING id INTO v_tema;
        -- SQL JOIN agrega una segunda actividad sin intentos para probar NULL y pendientes.
        FOR v_a IN 1..(CASE WHEN v_n=3 THEN 2 ELSE 1 END) LOOP
            v_titulo:='DEMO-SQL-007: '||v_nombre_tema||CASE
                WHEN v_n=3 AND v_a=2 THEN ' - evaluacion disponible'
                WHEN v_n=3 THEN ' - practica' ELSE ' - evaluacion' END;
            INSERT INTO public.actividades(seccion_id,tema_id,titulo,instrucciones,finalidad,
                max_intentos,duracion_minutos,disponible_desde,disponible_hasta,creado_por,creado_en,actualizado_en)
            VALUES(v_seccion,v_tema,v_titulo,
                'Responde las cuatro preguntas. En seleccion multiple marca todas las correctas y ninguna incorrecta.',
                CASE WHEN v_a=2 THEN 'EVALUACION' ELSE v_finalidad END,
                NULL,30,v_base,v_now+INTERVAL '1 year',v_admin,v_base,v_base)
            RETURNING id INTO v_actividad;
            FOR v_fila IN SELECT * FROM plantilla_seed_integracion WHERE tema_orden=v_n ORDER BY pregunta_orden LOOP
                INSERT INTO public.preguntas(actividad_id,enunciado,tipo,orden,puntaje_maximo)
                VALUES(v_actividad,v_fila.enunciado,v_fila.tipo,v_fila.pregunta_orden,10)
                RETURNING id INTO v_pregunta;
                INSERT INTO public.opciones_respuestas(pregunta_id,texto,orden,es_correcta)
                SELECT v_pregunta,o.valor->>'texto',o.orden::INTEGER,(o.valor->>'es_correcta')::BOOLEAN
                FROM jsonb_array_elements(v_fila.opciones) WITH ORDINALITY AS o(valor,orden);
            END LOOP;
            UPDATE public.actividades SET estado='PUBLICADO' WHERE id=v_actividad;
            IF v_a=2 THEN CONTINUE; END IF;

            FOR v_j IN 1..3 LOOP
                v_correctas:=CASE v_n
                    WHEN 1 THEN CASE WHEN v_j=1 THEN 3 ELSE 4 END
                    WHEN 2 THEN CASE WHEN v_j=1 THEN 2 ELSE 3 END
                    ELSE CASE WHEN v_j=1 THEN 0 ELSE 1 END END;
                v_intento:=public.iniciar_intento(v_actividad,v_inscripcion,v_estudiante);
                FOR v_respuesta IN
                    SELECT r.id,r.pregunta_id,p.orden FROM public.respuestas r
                    JOIN public.preguntas p ON p.id=r.pregunta_id
                    WHERE r.intento_id=v_intento ORDER BY p.orden
                LOOP
                    IF v_respuesta.orden<=v_correctas THEN
                        SELECT array_agg(o.id ORDER BY o.orden) INTO v_opciones
                        FROM public.opciones_respuestas o WHERE o.pregunta_id=v_respuesta.pregunta_id AND o.es_correcta;
                    ELSE
                        SELECT ARRAY[o.id] INTO v_opciones FROM public.opciones_respuestas o
                        WHERE o.pregunta_id=v_respuesta.pregunta_id AND NOT o.es_correcta ORDER BY o.orden LIMIT 1;
                    END IF;
                    PERFORM public.guardar_opciones_respuesta(v_respuesta.id,v_estudiante,v_opciones);
                END LOOP;
                PERFORM public.entregar_intento(v_intento,v_estudiante);
                v_estado:=public.calificar_intento(v_intento);
                IF v_estado.estado<>'CALIFICADO' OR v_estado.puntaje_obtenido<>v_correctas*10 THEN
                    RAISE EXCEPTION 'Calificacion inesperada en el seed para % intento %.',v_nombre_tema,v_j;
                END IF;

                IF v_j=1 THEN
                    -- Martes, miercoles y jueves de la semana anterior.
                    v_inicio:=v_semana-INTERVAL '7 days'+make_interval(days=>v_n,hours=>10);
                    v_duracion:=make_interval(mins=>10+v_n);
                ELSE
                    -- Seis intervalos separados dentro del tiempo ya transcurrido esta semana.
                    -- Nunca se crean intentos futuros, ni siquiera al cargar un lunes.
                    v_slot:=(v_n-1)*2+(v_j-1);
                    v_inicio:=v_semana+v_margen*(v_slot::DOUBLE PRECISION/8);
                    v_duracion:=LEAST(make_interval(mins=>10+v_n),v_margen/32);
                END IF;
                v_entrega:=v_inicio+v_duracion;
                v_calificacion:=v_entrega+INTERVAL '0.01 second';
                IF v_calificacion>v_ref THEN RAISE EXCEPTION 'Fecha simulada fuera de la referencia.'; END IF;
                -- Excepcion SOLO del seed administrativo sobre IDs recien creados.
                -- Primero el flujo real califico; luego se reubican fechas coherentes.
                -- No se deshabilitan triggers ni se cambian puntos/notas manualmente.
                UPDATE public.intentos SET iniciado_en=v_inicio,vence_en=v_inicio+INTERVAL '30 minutes',
                    entregado_en=v_entrega,calificado_en=v_calificacion WHERE id=v_intento;
                UPDATE public.respuestas SET creado_en=v_inicio,actualizado_en=v_calificacion,
                    calificado_en=v_calificacion WHERE intento_id=v_intento;
            END LOOP;
        END LOOP;
    END LOOP;
    IF (SELECT password_hash FROM public.usuarios WHERE id=v_estudiante) IS DISTINCT FROM v_hash THEN
        RAISE EXCEPTION 'No debe cambiar la credencial del estudiante.';
    END IF;
    RAISE NOTICE 'Seed creado: estudiante %, curso %, inscripcion %. Semana de referencia: % (America/Santo_Domingo).',
        v_estudiante,v_curso,v_inscripcion,v_semana;
END;
$seed$;

-- Resumen real actual: nuevos intentos posteriores pueden cambiar los promedios.
SELECT u.email,i.id AS inscripcion_id,t.id AS tema_id,t.nombre AS tema,a.id AS actividad_id,
       a.finalidad,COALESCE(ra.intentos_calificados,0) AS intentos_calificados,
       ra.promedio_porcentaje,ra.nota_academica_porcentaje
FROM public.cursos c
JOIN public.ediciones_curso e ON e.curso_id=c.id
JOIN public.secciones s ON s.edicion_id=e.id
JOIN public.inscripciones i ON i.seccion_id=s.id AND i.edicion_id=e.id
JOIN public.usuarios u ON u.id=i.estudiante_id
JOIN public.actividades a ON a.seccion_id=s.id
JOIN public.temas t ON t.id=a.tema_id
LEFT JOIN public.resultados_actividades ra ON ra.actividad_id=a.id AND ra.inscripcion_id=i.id
WHERE c.codigo='DEMO-SQL-007' AND lower(u.email)=(SELECT email FROM parametros_seed_integracion)
ORDER BY t.orden,a.id;

SELECT date_trunc('week',it.iniciado_en)::DATE AS semana_local,
       COUNT(*) AS intentos_calificados,
       ROUND(SUM(EXTRACT(EPOCH FROM (it.entregado_en-it.iniciado_en)))/60,2) AS minutos_transcurridos_simulados
FROM public.intentos it
JOIN public.inscripciones i ON i.id=it.inscripcion_id
JOIN public.usuarios u ON u.id=i.estudiante_id
JOIN public.ediciones_curso e ON e.id=i.edicion_id
JOIN public.cursos c ON c.id=e.curso_id
WHERE c.codigo='DEMO-SQL-007' AND lower(u.email)=(SELECT email FROM parametros_seed_integracion)
  AND it.estado='CALIFICADO'
GROUP BY date_trunc('week',it.iniciado_en)::DATE ORDER BY semana_local;
COMMIT;
