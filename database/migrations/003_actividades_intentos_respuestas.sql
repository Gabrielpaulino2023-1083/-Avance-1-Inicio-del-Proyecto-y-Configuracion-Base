-- Migración 003: actividades, intentos, respuestas y resultados.
-- Requisitos: migraciones 001 y 002 aplicadas; ejecutar como administrador.
-- Después aplicar security/001_roles_permisos.sql.

BEGIN;

SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE TABLE public.actividades (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    seccion_id INTEGER NOT NULL REFERENCES secciones(id) ON DELETE RESTRICT,
    tema_id INTEGER NOT NULL REFERENCES temas(id) ON DELETE RESTRICT,
    titulo TEXT NOT NULL CHECK (btrim(titulo) <> ''),
    instrucciones TEXT NOT NULL CHECK (btrim(instrucciones) <> ''),
    finalidad TEXT NOT NULL DEFAULT 'PRACTICA' CHECK (finalidad IN ('EVALUACION', 'PRACTICA')),
    metodo_calificacion TEXT NOT NULL DEFAULT 'PROMEDIO' CHECK (metodo_calificacion = 'PROMEDIO'),
    max_intentos INTEGER CHECK (max_intentos > 0),
    duracion_minutos INTEGER CHECK (duracion_minutos > 0),
    disponible_desde TIMESTAMPTZ NOT NULL,
    disponible_hasta TIMESTAMPTZ,
    estado VARCHAR(50) NOT NULL DEFAULT 'BORRADOR' CHECK (estado IN ('BORRADOR', 'PUBLICADO', 'ARCHIVADO')),
    creado_por INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_actividades_disponibilidad
        CHECK ( disponible_hasta IS NULL OR disponible_hasta > disponible_desde),

    CONSTRAINT ck_actividades_fechas
        CHECK (actualizado_en >= creado_en)
);


CREATE TABLE public.preguntas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE RESTRICT,
    enunciado TEXT NOT NULL CHECK (btrim(enunciado) <> ''),
    tipo TEXT NOT NULL DEFAULT 'SELECCION_UNICA' CHECK (tipo IN ('SELECCION_UNICA', 'SELECCION_MULTIPLE')),
    orden INTEGER NOT NULL CHECK (orden > 0),
    puntaje_maximo NUMERIC(10,2) NOT NULL CHECK (puntaje_maximo > 0 AND puntaje_maximo <> 'NaN'::NUMERIC),
    explicacion TEXT CHECK (btrim(explicacion) <> ''),

    CONSTRAINT uq_preguntas_actividad_orden
        UNIQUE (actividad_id, orden),

    CONSTRAINT uq_preguntas_id_actividad
        UNIQUE (id, actividad_id)
);


CREATE TABLE public.opciones_respuestas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pregunta_id INTEGER NOT NULL REFERENCES preguntas(id) ON DELETE RESTRICT,
    texto TEXT NOT NULL CHECK (btrim(texto) <> ''),
    orden INTEGER NOT NULL CHECK (orden > 0),
    es_correcta BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_opciones_pregunta_orden
        UNIQUE (pregunta_id, orden),

    CONSTRAINT uq_opciones_id_pregunta
        UNIQUE (id, pregunta_id)
);


CREATE TABLE public.intentos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE RESTRICT,
    inscripcion_id INTEGER NOT NULL REFERENCES inscripciones(id) ON DELETE RESTRICT,
    numero_intento INTEGER NOT NULL CHECK (numero_intento > 0),
    estado TEXT NOT NULL DEFAULT 'EN_CURSO' CHECK (estado IN ('EN_CURSO', 'ENTREGADO', 'CALIFICADO')),
    iniciado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    vence_en TIMESTAMPTZ,
    entregado_en TIMESTAMPTZ,
    motivo_entrega TEXT CHECK (motivo_entrega IN ('MANUAL', 'VENCIMIENTO')),
    calificado_en TIMESTAMPTZ,
    puntaje_obtenido NUMERIC(10,2) CHECK (puntaje_obtenido >= 0 AND puntaje_obtenido <> 'NaN'::NUMERIC),
    puntaje_maximo NUMERIC(10,2) NOT NULL CHECK (puntaje_maximo > 0 AND puntaje_maximo <> 'NaN'::NUMERIC),

    CONSTRAINT uq_intentos_actividad_inscripcion_numero
        UNIQUE (actividad_id, inscripcion_id, numero_intento),

    CONSTRAINT uq_intentos_id_actividad
        UNIQUE (id, actividad_id),

    CONSTRAINT ck_intentos_vencimiento
        CHECK ( vence_en IS NULL OR vence_en >= iniciado_en),

    CONSTRAINT ck_intentos_puntaje
        CHECK (puntaje_obtenido <= puntaje_maximo),

    CONSTRAINT ck_intentos_entrega_fecha
        CHECK (entregado_en IS NULL OR entregado_en >= iniciado_en),

    CONSTRAINT ck_intentos_calificacion_fecha
        CHECK (calificado_en IS NULL OR (entregado_en IS NOT NULL AND calificado_en >= entregado_en)),

    CONSTRAINT ck_intentos_estado_datos
        CHECK (
            (
                estado = 'EN_CURSO'
                AND entregado_en IS NULL
                AND motivo_entrega IS NULL
                AND calificado_en IS NULL
                AND puntaje_obtenido IS NULL
            )
            OR
            (
                estado = 'ENTREGADO'
                AND entregado_en IS NOT NULL
                AND motivo_entrega IS NOT NULL
                AND calificado_en IS NULL
                AND puntaje_obtenido IS NULL
            )
            OR
            (
                estado = 'CALIFICADO'
                AND entregado_en IS NOT NULL
                AND motivo_entrega IS NOT NULL
                AND calificado_en IS NOT NULL
                AND puntaje_obtenido IS NOT NULL
            )
        ),

    CONSTRAINT ck_intentos_entrega_vencimiento
        CHECK (
            motivo_entrega IS DISTINCT FROM 'VENCIMIENTO'
            OR (
                vence_en IS NOT NULL
                AND entregado_en IS NOT NULL
                AND entregado_en >= vence_en
            )
        )
);

-- único intento abierto por actividad e inscripción.
CREATE UNIQUE INDEX uq_intentos_uno_en_curso
    ON intentos (actividad_id, inscripcion_id)
    WHERE estado = 'EN_CURSO';


CREATE TABLE public.respuestas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    intento_id INTEGER NOT NULL,
    pregunta_id INTEGER NOT NULL,

    -- Contexto para comprobar que intento y pregunta
    -- pertenecen a la misma actividad.
    actividad_id INTEGER NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    calificado_en TIMESTAMPTZ,
    puntaje_obtenido NUMERIC(10,2) CHECK (puntaje_obtenido >= 0 AND puntaje_obtenido <> 'NaN'::NUMERIC),

    CONSTRAINT uq_respuestas_intento_pregunta
        UNIQUE (intento_id, pregunta_id),

    CONSTRAINT uq_respuestas_id_pregunta
        UNIQUE (id, pregunta_id),

    CONSTRAINT fk_respuestas_intento_actividad
        FOREIGN KEY (intento_id, actividad_id)
        REFERENCES intentos(id, actividad_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_respuestas_pregunta_actividad
        FOREIGN KEY (pregunta_id, actividad_id)
        REFERENCES preguntas(id, actividad_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_respuestas_fechas
        CHECK (actualizado_en >= creado_en),

    CONSTRAINT ck_respuestas_calificacion
        CHECK (
            (
                calificado_en IS NULL
                AND puntaje_obtenido IS NULL
            )
            OR
            (
                calificado_en IS NOT NULL
                AND puntaje_obtenido IS NOT NULL
                AND calificado_en >= creado_en
            )
        )
);

CREATE TABLE public.respuesta_opciones (
    respuesta_id INTEGER NOT NULL,
    pregunta_id INTEGER NOT NULL,
    opcion_id INTEGER NOT NULL,

    CONSTRAINT pk_respuesta_opciones
        PRIMARY KEY (respuesta_id, opcion_id),

    CONSTRAINT fk_respuesta_opciones_respuesta
        FOREIGN KEY (respuesta_id, pregunta_id)
        REFERENCES respuestas(id, pregunta_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_respuesta_opciones_opcion
        FOREIGN KEY (opcion_id, pregunta_id)
        REFERENCES opciones_respuestas(id, pregunta_id)
        ON DELETE RESTRICT
);

--Funciones
--Funcion para validar que el tema y la sección de una actividad pertenezcan al mismo curso.
CREATE OR REPLACE FUNCTION public.validar_curso_actividad()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_curso_seccion INTEGER;
    v_curso_tema INTEGER;
BEGIN
    SELECT e.curso_id
    INTO v_curso_seccion
    FROM secciones s
    JOIN ediciones_curso e ON e.id = s.edicion_id
    WHERE s.id = NEW.seccion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La sección % no existe.',
            NEW.seccion_id;
    END IF;

    SELECT m.curso_id
    INTO v_curso_tema
    FROM temas t
    JOIN modulos m ON m.id = t.modulo_id
    WHERE t.id = NEW.tema_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El tema % no existe.',
            NEW.tema_id;
    END IF;

    IF v_curso_seccion <> v_curso_tema THEN
        RAISE EXCEPTION
            'La sección y el tema deben pertenecer al mismo curso.';
    END IF;

    RETURN NEW;
END;
$$;

-- Funcion para proteccion a los campos de curso_id
--y edicion_id de las tablas ediciones_curso, secciones, modulos y temas.
CREATE OR REPLACE FUNCTION public.impedir_cambio_padre_academico()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF (to_jsonb(NEW) -> TG_ARGV[0])
        IS DISTINCT FROM
        (to_jsonb(OLD) -> TG_ARGV[0]) THEN

        RAISE EXCEPTION
            'No se permite modificar %.% después de su creación.',
            TG_TABLE_NAME,
            TG_ARGV[0];
    END IF;

    RETURN NEW;
END;
$$;

--Funcion para proteger preguntas
CREATE OR REPLACE FUNCTION public.proteger_preguntas_actividad()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_actividad_id INTEGER;
    v_estado TEXT;
BEGIN
    -- Una pregunta no se traslada a otra actividad.
    IF TG_OP = 'UPDATE' THEN
        IF NEW.actividad_id IS DISTINCT FROM OLD.actividad_id THEN
            RAISE EXCEPTION
                'No se permite cambiar la actividad de una pregunta.';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        v_actividad_id := OLD.actividad_id;
    ELSE
        v_actividad_id := NEW.actividad_id;
    END IF;

    -- Bloquear la actividad mientras se comprueba y modifica.
    SELECT estado
    INTO v_estado
    FROM actividades
    WHERE id = v_actividad_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La actividad % no existe.',
            v_actividad_id;
    END IF;

    IF v_estado <> 'BORRADOR' THEN
        RAISE EXCEPTION
            'Solo se pueden editar preguntas de actividades en BORRADOR.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM intentos
        WHERE actividad_id = v_actividad_id
    ) THEN
        RAISE EXCEPTION
            'No se pueden editar preguntas de una actividad con intentos.';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

-- Funcion para proteger las opciones de las preguntas
CREATE OR REPLACE FUNCTION public.proteger_opciones_actividad()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_pregunta_id INTEGER;
    v_actividad_id INTEGER;
    v_estado TEXT;
BEGIN
    -- Una opción no se traslada a otra pregunta.
    IF TG_OP = 'UPDATE' THEN
        IF NEW.pregunta_id IS DISTINCT FROM OLD.pregunta_id THEN
            RAISE EXCEPTION
                'No se permite cambiar la pregunta de una opción.';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        v_pregunta_id := OLD.pregunta_id;
    ELSE
        v_pregunta_id := NEW.pregunta_id;
    END IF;

    SELECT a.id, a.estado
    INTO v_actividad_id, v_estado
    FROM preguntas p
    JOIN actividades a ON a.id = p.actividad_id
    WHERE p.id = v_pregunta_id
    FOR UPDATE OF a;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La pregunta % no existe.',
            v_pregunta_id;
    END IF;

    IF v_estado <> 'BORRADOR' THEN
        RAISE EXCEPTION
            'Solo se pueden editar opciones de actividades en BORRADOR.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM intentos
        WHERE actividad_id = v_actividad_id
    ) THEN
        RAISE EXCEPTION
            'No se pueden editar opciones de una actividad con intentos.';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

--Funcion para validar actividades antes de ser publicadas
CREATE OR REPLACE FUNCTION public.validar_publicacion_actividad()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_pregunta RECORD;
BEGIN
    IF NEW.estado <> 'PUBLICADO' THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM preguntas
        WHERE actividad_id = NEW.id
    ) THEN
        RAISE EXCEPTION
            'No se puede publicar una actividad sin preguntas.';
    END IF;

    FOR v_pregunta IN
        SELECT
            p.id,
            p.tipo,
            COUNT(o.id) AS total_opciones,
            COUNT(o.id) FILTER (
                WHERE o.es_correcta = TRUE
            ) AS opciones_correctas
        FROM preguntas p
        LEFT JOIN opciones_respuestas o
            ON o.pregunta_id = p.id
        WHERE p.actividad_id = NEW.id
        GROUP BY p.id, p.tipo
        ORDER BY p.id
    LOOP
        IF v_pregunta.total_opciones < 2 THEN
            RAISE EXCEPTION
                'La pregunta % debe tener al menos dos opciones.',
                v_pregunta.id;
        END IF;

        IF v_pregunta.tipo = 'SELECCION_UNICA'
           AND v_pregunta.opciones_correctas <> 1 THEN
            RAISE EXCEPTION
                'La pregunta % de selección única debe tener exactamente una opción correcta.',
                v_pregunta.id;
        END IF;

        IF v_pregunta.tipo = 'SELECCION_MULTIPLE'
           AND v_pregunta.opciones_correctas < 2 THEN
            RAISE EXCEPTION
                'La pregunta % de selección múltiple debe tener al menos dos opciones correctas.',
                v_pregunta.id;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;

--Funcion para proteger las actividades cuando ya tengan intentos
CREATE OR REPLACE FUNCTION public.proteger_actividad_con_intentos()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM intentos
        WHERE actividad_id = OLD.id
    ) THEN
        RETURN NEW;
    END IF;

    IF NEW.estado = 'BORRADOR' THEN
        RAISE EXCEPTION
            'Una actividad con intentos no puede volver a BORRADOR.';
    END IF;

    IF ROW(
        NEW.seccion_id,
        NEW.tema_id,
        NEW.titulo,
        NEW.instrucciones,
        NEW.finalidad,
        NEW.metodo_calificacion,
        NEW.max_intentos,
        NEW.duracion_minutos,
        NEW.disponible_desde,
        NEW.disponible_hasta,
        NEW.creado_por,
        NEW.creado_en
    ) IS DISTINCT FROM ROW(
        OLD.seccion_id,
        OLD.tema_id,
        OLD.titulo,
        OLD.instrucciones,
        OLD.finalidad,
        OLD.metodo_calificacion,
        OLD.max_intentos,
        OLD.duracion_minutos,
        OLD.disponible_desde,
        OLD.disponible_hasta,
        OLD.creado_por,
        OLD.creado_en
    ) THEN
        RAISE EXCEPTION
            'No se puede modificar la configuración de una actividad con intentos.';
    END IF;

    RETURN NEW;
END;
$$;

--Funcion para iniciar un intento de actividad
CREATE OR REPLACE FUNCTION public.iniciar_intento(
    p_actividad_id INTEGER,
    p_inscripcion_id INTEGER,
    p_estudiante_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_actividad actividades%ROWTYPE;
    v_inscripcion inscripciones%ROWTYPE;

    v_ahora TIMESTAMPTZ;
    v_vence_en TIMESTAMPTZ;

    v_cantidad_intentos BIGINT;
    v_ultimo_numero INTEGER;
    v_numero_intento INTEGER;

    v_total_preguntas BIGINT;
    v_puntaje_maximo NUMERIC;

    v_intento_id INTEGER;
    v_cuenta_activa BOOLEAN;
BEGIN
    IF p_actividad_id IS NULL
       OR p_inscripcion_id IS NULL
       OR p_estudiante_id IS NULL THEN
        RAISE EXCEPTION
            'Actividad, inscripción y estudiante son obligatorios.';
    END IF;

    SELECT *
    INTO v_actividad
    FROM actividades
    WHERE id = p_actividad_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La actividad no existe.';
    END IF;

    SELECT *
    INTO v_inscripcion
    FROM inscripciones
    WHERE id = p_inscripcion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La inscripción no existe.';
    END IF;

    IF v_inscripcion.estudiante_id <> p_estudiante_id THEN
        RAISE EXCEPTION
            'La inscripción no pertenece al estudiante.';
    END IF;

    SELECT activo
    INTO v_cuenta_activa
    FROM usuarios
    WHERE id = p_estudiante_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El estudiante no existe.';
    END IF;

    IF NOT v_cuenta_activa THEN
        RAISE EXCEPTION 'La cuenta del estudiante está inactiva.';
    END IF;

    PERFORM ur.id
    FROM usuario_roles ur
    JOIN roles r ON r.id = ur.rol_id
    WHERE ur.usuario_id = p_estudiante_id
      AND ur.activo = TRUE
      AND r.codigo = 'ESTUDIANTE'
    FOR SHARE OF ur;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El usuario no tiene el rol ESTUDIANTE activo.';
    END IF;

    IF v_inscripcion.estado <> 'ACTIVA' THEN
        RAISE EXCEPTION 'La inscripción no está activa.';
    END IF;

    IF v_inscripcion.seccion_id <> v_actividad.seccion_id THEN
        RAISE EXCEPTION
            'La inscripción no pertenece a la sección de la actividad.';
    END IF;

    IF v_actividad.estado <> 'PUBLICADO' THEN
        RAISE EXCEPTION
            'La actividad debe estar PUBLICADO para iniciar un intento.';
    END IF;

    v_ahora := clock_timestamp();

    IF v_ahora < v_actividad.disponible_desde THEN
        RAISE EXCEPTION
            'La actividad todavía no está disponible.';
    END IF;

    IF v_actividad.disponible_hasta IS NOT NULL
       AND v_ahora >= v_actividad.disponible_hasta THEN
        RAISE EXCEPTION
            'El período de disponibilidad de la actividad terminó.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM intentos
        WHERE actividad_id = p_actividad_id
          AND inscripcion_id = p_inscripcion_id
          AND estado = 'EN_CURSO'
    ) THEN
        RAISE EXCEPTION
            'Ya existe un intento EN_CURSO para esta actividad.';
    END IF;

    SELECT COUNT(*), COALESCE(MAX(numero_intento), 0)
    INTO v_cantidad_intentos, v_ultimo_numero
    FROM intentos
    WHERE actividad_id = p_actividad_id
      AND inscripcion_id = p_inscripcion_id;

    IF v_actividad.max_intentos IS NOT NULL
       AND v_cantidad_intentos >= v_actividad.max_intentos THEN
        RAISE EXCEPTION
            'El estudiante agotó el máximo de intentos.';
    END IF;

    v_numero_intento := v_ultimo_numero + 1;

    SELECT COUNT(*), SUM(puntaje_maximo)
    INTO v_total_preguntas, v_puntaje_maximo
    FROM preguntas
    WHERE actividad_id = p_actividad_id;

    IF v_total_preguntas = 0 THEN
        RAISE EXCEPTION
            'La actividad no tiene preguntas.';
    END IF;

    IF v_puntaje_maximo IS NULL
       OR v_puntaje_maximo = 'NaN'::NUMERIC
       OR v_puntaje_maximo <= 0
       OR v_puntaje_maximo > 99999999.99 THEN
        RAISE EXCEPTION
            'El puntaje total de la actividad no es válido.';
    END IF;

    v_vence_en := v_actividad.disponible_hasta;

    IF v_actividad.duracion_minutos IS NOT NULL THEN
        IF v_vence_en IS NULL THEN
            v_vence_en :=
                v_ahora
                + make_interval(
                    mins => v_actividad.duracion_minutos
                );
        ELSE
            v_vence_en := LEAST(
                v_vence_en,
                v_ahora
                + make_interval(
                    mins => v_actividad.duracion_minutos
                )
            );
        END IF;
    END IF;

    INSERT INTO intentos (
        actividad_id,
        inscripcion_id,
        numero_intento,
        estado,
        iniciado_en,
        vence_en,
        puntaje_maximo
    )
    VALUES (
        p_actividad_id,
        p_inscripcion_id,
        v_numero_intento,
        'EN_CURSO',
        v_ahora,
        v_vence_en,
        v_puntaje_maximo
    )
    RETURNING id INTO v_intento_id;

    INSERT INTO respuestas (
        intento_id,
        pregunta_id,
        actividad_id,
        creado_en,
        actualizado_en
    )
    SELECT
        v_intento_id,
        p.id,
        p_actividad_id,
        v_ahora,
        v_ahora
    FROM preguntas p
    WHERE p.actividad_id = p_actividad_id;

    RETURN v_intento_id;
END;
$$;

--Funcion para guardar las opciones seleccionadas de una respuesta
CREATE OR REPLACE FUNCTION public.guardar_opciones_respuesta(
    p_respuesta_id INTEGER,
    p_estudiante_id INTEGER,
    p_opciones INTEGER[]
)
RETURNS VOID
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_intento_id INTEGER;
    v_intento intentos%ROWTYPE;
    v_respuesta respuestas%ROWTYPE;

    v_estudiante_id INTEGER;
    v_tipo TEXT;

    v_cantidad INTEGER;
    v_distintas INTEGER;
    v_validas INTEGER;
BEGIN
    IF p_respuesta_id IS NULL
       OR p_estudiante_id IS NULL
       OR p_opciones IS NULL THEN
        RAISE EXCEPTION
            'Respuesta, estudiante y arreglo de opciones son obligatorios.';
    END IF;

    SELECT intento_id
    INTO v_intento_id
    FROM respuestas
    WHERE id = p_respuesta_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La respuesta no existe.';
    END IF;

    SELECT *
    INTO v_intento
    FROM intentos
    WHERE id = v_intento_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El intento no existe.';
    END IF;

    SELECT *
    INTO v_respuesta
    FROM respuestas
    WHERE id = p_respuesta_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La respuesta ya no existe.';
    END IF;

    IF v_respuesta.intento_id <> v_intento.id
       OR v_respuesta.actividad_id <> v_intento.actividad_id THEN
        RAISE EXCEPTION
            'El contexto de la respuesta cambió; repita la operación.';
    END IF;

    SELECT estudiante_id
    INTO v_estudiante_id
    FROM inscripciones
    WHERE id = v_intento.inscripcion_id;

    IF v_estudiante_id IS DISTINCT FROM p_estudiante_id THEN
        RAISE EXCEPTION
            'La respuesta no pertenece al estudiante.';
    END IF;

    PERFORM id
    FROM usuarios
    WHERE id = p_estudiante_id
      AND activo = TRUE
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La cuenta del estudiante no está activa.';
    END IF;

    PERFORM ur.id
    FROM usuario_roles ur
    JOIN roles r ON r.id = ur.rol_id
    WHERE ur.usuario_id = p_estudiante_id
      AND ur.activo = TRUE
      AND r.codigo = 'ESTUDIANTE'
    FOR SHARE OF ur;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El usuario no tiene el rol ESTUDIANTE activo.';
    END IF;

    IF v_intento.estado <> 'EN_CURSO' THEN
        RAISE EXCEPTION
            'Solo se pueden guardar opciones de un intento EN_CURSO.';
    END IF;

    IF v_respuesta.calificado_en IS NOT NULL THEN
        RAISE EXCEPTION
            'No se puede modificar una respuesta calificada.';
    END IF;

    SELECT tipo
    INTO v_tipo
    FROM preguntas
    WHERE id = v_respuesta.pregunta_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La pregunta no existe.';
    END IF;

    SELECT COUNT(*), COUNT(DISTINCT opcion_id)
    INTO v_cantidad, v_distintas
    FROM unnest(p_opciones) AS seleccion(opcion_id);

    IF v_cantidad <> v_distintas THEN
        RAISE EXCEPTION
            'Las opciones no pueden contener valores NULL ni repetidos.';
    END IF;

    IF v_tipo = 'SELECCION_UNICA'
       AND v_cantidad > 1 THEN
        RAISE EXCEPTION
            'Una pregunta de selección única admite como máximo una opción.';
    END IF;

    SELECT COUNT(*)
    INTO v_validas
    FROM opciones_respuestas
    WHERE pregunta_id = v_respuesta.pregunta_id
      AND id = ANY(p_opciones);

    IF v_validas <> v_cantidad THEN
        RAISE EXCEPTION
            'Todas las opciones deben pertenecer a la pregunta respondida.';
    END IF;

    IF v_intento.vence_en IS NOT NULL
       AND clock_timestamp() >= v_intento.vence_en THEN
        RAISE EXCEPTION
            'El intento venció; no se pueden guardar respuestas.';
    END IF;

    DELETE FROM respuesta_opciones
    WHERE respuesta_id = p_respuesta_id;

    INSERT INTO respuesta_opciones (
        respuesta_id,
        pregunta_id,
        opcion_id
    )
    SELECT
        p_respuesta_id,
        v_respuesta.pregunta_id,
        seleccion.opcion_id
    FROM unnest(p_opciones) AS seleccion(opcion_id);

    UPDATE respuestas
    SET actualizado_en = clock_timestamp()
    WHERE id = p_respuesta_id;
END;
$$;

--Funcion para entrega de intentos de actividades
CREATE OR REPLACE FUNCTION public.entregar_intento(
    p_intento_id INTEGER,
    p_estudiante_id INTEGER
)
RETURNS intentos
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_intento intentos%ROWTYPE;
    v_estudiante_id INTEGER;
    v_ahora TIMESTAMPTZ;
    v_motivo TEXT;
BEGIN
    IF p_intento_id IS NULL
       OR p_estudiante_id IS NULL THEN
        RAISE EXCEPTION
            'Intento y estudiante son obligatorios.';
    END IF;

    SELECT *
    INTO v_intento
    FROM intentos
    WHERE id = p_intento_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El intento no existe.';
    END IF;

    SELECT estudiante_id
    INTO v_estudiante_id
    FROM inscripciones
    WHERE id = v_intento.inscripcion_id;

    IF v_estudiante_id IS DISTINCT FROM p_estudiante_id THEN
        RAISE EXCEPTION
            'El intento no pertenece al estudiante.';
    END IF;

    PERFORM id
    FROM usuarios
    WHERE id = p_estudiante_id
      AND activo = TRUE
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La cuenta del estudiante no está activa.';
    END IF;

    PERFORM ur.id
    FROM usuario_roles ur
    JOIN roles r ON r.id = ur.rol_id
    WHERE ur.usuario_id = p_estudiante_id
      AND ur.activo = TRUE
      AND r.codigo = 'ESTUDIANTE'
    FOR SHARE OF ur;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El usuario no tiene el rol ESTUDIANTE activo.';
    END IF;

    IF v_intento.estado IN ('ENTREGADO', 'CALIFICADO') THEN
        RETURN v_intento;
    END IF;

    IF v_intento.estado <> 'EN_CURSO' THEN
        RAISE EXCEPTION
            'El estado del intento no permite entregarlo.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM preguntas p
        WHERE p.actividad_id = v_intento.actividad_id
          AND NOT EXISTS (
              SELECT 1
              FROM respuestas r
              WHERE r.intento_id = v_intento.id
                AND r.pregunta_id = p.id
          )
    ) THEN
        RAISE EXCEPTION
            'El intento tiene preguntas sin registro de respuesta.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM respuestas
        WHERE intento_id = v_intento.id
          AND (
              calificado_en IS NOT NULL
              OR puntaje_obtenido IS NOT NULL
          )
    ) THEN
        RAISE EXCEPTION
            'Un intento EN_CURSO no debe tener respuestas calificadas.';
    END IF;

    v_ahora := clock_timestamp();

    IF v_intento.vence_en IS NOT NULL
       AND v_ahora >= v_intento.vence_en THEN
        v_motivo := 'VENCIMIENTO';
    ELSE
        v_motivo := 'MANUAL';
    END IF;

    UPDATE intentos
    SET estado = 'ENTREGADO',
        entregado_en = v_ahora,
        motivo_entrega = v_motivo
    WHERE id = v_intento.id
    RETURNING * INTO v_intento;

    RETURN v_intento;
END;
$$;

--Funcion para calificar un intento de actividad
CREATE OR REPLACE FUNCTION public.calificar_intento(
    p_intento_id INTEGER
)
RETURNS intentos
LANGUAGE plpgsql
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_intento intentos%ROWTYPE;
    v_pregunta RECORD;

    v_correctas BIGINT;
    v_seleccionadas BIGINT;
    v_aciertos BIGINT;

    v_puntaje NUMERIC(10,2);
    v_total NUMERIC;
    v_maximo_actual NUMERIC;
    v_ahora TIMESTAMPTZ;
BEGIN
    IF p_intento_id IS NULL THEN
        RAISE EXCEPTION
            'El identificador del intento es obligatorio.';
    END IF;

    SELECT *
    INTO v_intento
    FROM intentos
    WHERE id = p_intento_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El intento no existe.';
    END IF;

    IF v_intento.estado = 'CALIFICADO' THEN
        RETURN v_intento;
    END IF;

    IF v_intento.estado <> 'ENTREGADO' THEN
        RAISE EXCEPTION
            'Solo se pueden calificar intentos ENTREGADOS.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM preguntas
        WHERE actividad_id = v_intento.actividad_id
    ) THEN
        RAISE EXCEPTION
            'La actividad no tiene preguntas.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM preguntas p
        WHERE p.actividad_id = v_intento.actividad_id
          AND NOT EXISTS (
              SELECT 1
              FROM respuestas r
              WHERE r.intento_id = v_intento.id
                AND r.pregunta_id = p.id
          )
    ) THEN
        RAISE EXCEPTION
            'El intento tiene preguntas sin registro de respuesta.';
    END IF;

    SELECT SUM(puntaje_maximo)
    INTO v_maximo_actual
    FROM preguntas
    WHERE actividad_id = v_intento.actividad_id;

    IF v_maximo_actual IS DISTINCT FROM v_intento.puntaje_maximo THEN
        RAISE EXCEPTION
            'El puntaje máximo de la actividad no coincide con el del intento.';
    END IF;

    v_total := 0;
    v_ahora := clock_timestamp();

    FOR v_pregunta IN
        SELECT
            p.id AS pregunta_id,
            p.tipo,
            p.puntaje_maximo,
            r.id AS respuesta_id
        FROM preguntas p
        JOIN respuestas r
            ON r.pregunta_id = p.id
           AND r.intento_id = v_intento.id
        WHERE p.actividad_id = v_intento.actividad_id
        ORDER BY p.orden
    LOOP
        SELECT COUNT(*)
        INTO v_correctas
        FROM opciones_respuestas
        WHERE pregunta_id = v_pregunta.pregunta_id
          AND es_correcta = TRUE;

        IF v_pregunta.tipo = 'SELECCION_UNICA'
           AND v_correctas <> 1 THEN
            RAISE EXCEPTION
                'La pregunta % tiene una configuración de respuestas correctas inválida.',
                v_pregunta.pregunta_id;
        END IF;

        IF v_pregunta.tipo = 'SELECCION_MULTIPLE'
           AND v_correctas < 2 THEN
            RAISE EXCEPTION
                'La pregunta % tiene una configuración de respuestas correctas inválida.',
                v_pregunta.pregunta_id;
        END IF;

        SELECT
            COUNT(*),
            COUNT(*) FILTER (WHERE o.es_correcta = TRUE)
        INTO v_seleccionadas, v_aciertos
        FROM respuesta_opciones ro
        JOIN opciones_respuestas o ON o.id = ro.opcion_id
        WHERE ro.respuesta_id = v_pregunta.respuesta_id;

        IF v_pregunta.tipo = 'SELECCION_UNICA'
           AND v_seleccionadas > 1 THEN
            RAISE EXCEPTION
                'La respuesta % tiene varias opciones para una pregunta de selección única.',
                v_pregunta.respuesta_id;
        END IF;

        IF v_seleccionadas = v_correctas
           AND v_aciertos = v_correctas THEN
            v_puntaje := v_pregunta.puntaje_maximo;
        ELSE
            v_puntaje := 0;
        END IF;

        UPDATE respuestas
        SET puntaje_obtenido = v_puntaje,
            calificado_en = v_ahora,
            actualizado_en = v_ahora
        WHERE id = v_pregunta.respuesta_id;

        v_total := v_total + v_puntaje;
    END LOOP;

    UPDATE intentos
    SET estado = 'CALIFICADO',
        puntaje_obtenido = v_total,
        calificado_en = v_ahora
    WHERE id = v_intento.id
    RETURNING * INTO v_intento;

    RETURN v_intento;
END;
$$;

--TRIGGERS
--TRIGGER para ejecutar la funcion validar_curso_actividad
CREATE TRIGGER trg_validar_curso_actividad
BEFORE INSERT OR UPDATE OF seccion_id, tema_id
ON actividades
FOR EACH ROW
EXECUTE FUNCTION validar_curso_actividad();

--TRIGGERS para ejecutar la funcion impedir_cambio_padre_academico
CREATE TRIGGER trg_ediciones_curso_padre_inmutable
BEFORE UPDATE OF curso_id ON ediciones_curso
FOR EACH ROW
EXECUTE FUNCTION impedir_cambio_padre_academico('curso_id');

CREATE TRIGGER trg_secciones_padre_inmutable
BEFORE UPDATE OF edicion_id ON secciones
FOR EACH ROW
EXECUTE FUNCTION impedir_cambio_padre_academico('edicion_id');

CREATE TRIGGER trg_modulos_padre_inmutable
BEFORE UPDATE OF curso_id ON modulos
FOR EACH ROW
EXECUTE FUNCTION impedir_cambio_padre_academico('curso_id');

CREATE TRIGGER trg_temas_padre_inmutable
BEFORE UPDATE OF modulo_id ON temas
FOR EACH ROW
EXECUTE FUNCTION impedir_cambio_padre_academico('modulo_id');

--TRIGGER para ejecutar la funcion proteger preguntas
CREATE TRIGGER trg_proteger_preguntas_actividad
BEFORE INSERT OR UPDATE OR DELETE
ON preguntas
FOR EACH ROW
EXECUTE FUNCTION proteger_preguntas_actividad();

--TRIGGER para ejecutar la funcion proteger opciones de preguntas
CREATE TRIGGER trg_proteger_opciones_actividad
BEFORE INSERT OR UPDATE OR DELETE
ON opciones_respuestas
FOR EACH ROW
EXECUTE FUNCTION proteger_opciones_actividad();

--TRIGGER para ejecutar la funcion validar_publicacion_actividad
CREATE TRIGGER trg_validar_publicacion_actividad
BEFORE INSERT OR UPDATE OF estado
ON actividades
FOR EACH ROW
EXECUTE FUNCTION validar_publicacion_actividad();

--TRIGGER para ejecutar la funcion proteger_actividad_con_intentos
CREATE TRIGGER trg_proteger_actividad_con_intentos
BEFORE UPDATE
ON actividades
FOR EACH ROW
EXECUTE FUNCTION proteger_actividad_con_intentos();

--Vista de calificaciones de actividad
CREATE OR REPLACE VIEW public.resultados_actividades AS
SELECT
    a.id AS actividad_id,
    a.titulo,
    a.seccion_id,
    a.tema_id,
    a.finalidad,
    a.metodo_calificacion,

    i.id AS inscripcion_id,
    i.estudiante_id,

    COUNT(*) AS intentos_iniciados,

    COUNT(*) FILTER (
        WHERE it.estado = 'EN_CURSO'
    ) AS intentos_en_curso,

    COUNT(*) FILTER (
        WHERE it.estado = 'ENTREGADO'
    ) AS intentos_pendientes_calificacion,

    COUNT(*) FILTER (
        WHERE it.estado = 'CALIFICADO'
    ) AS intentos_calificados,

    ROUND(
        AVG(
            it.puntaje_obtenido * 100.0
            / it.puntaje_maximo
        ) FILTER (
            WHERE it.estado = 'CALIFICADO'
        ),
        2
    ) AS promedio_porcentaje,

    CASE
        WHEN a.finalidad = 'EVALUACION' THEN
            ROUND(
                AVG(
                    it.puntaje_obtenido * 100.0
                    / it.puntaje_maximo
                ) FILTER (
                    WHERE it.estado = 'CALIFICADO'
                ),
                2
            )
        ELSE NULL
    END AS nota_academica_porcentaje

FROM intentos it
JOIN actividades a ON a.id = it.actividad_id
JOIN inscripciones i ON i.id = it.inscripcion_id

GROUP BY
    a.id,
    a.titulo,
    a.seccion_id,
    a.tema_id,
    a.finalidad,
    a.metodo_calificacion,
    i.id,
    i.estudiante_id;


-- Hasta aplicar el script de seguridad, las operaciones no se ofrecen a PUBLIC.
-- El administrador que instala conserva sus permisos como propietario.
REVOKE ALL ON FUNCTION public.iniciar_intento(INTEGER, INTEGER, INTEGER)
FROM PUBLIC;
REVOKE ALL ON FUNCTION public.guardar_opciones_respuesta(INTEGER, INTEGER, INTEGER[])
FROM PUBLIC;
REVOKE ALL ON FUNCTION public.entregar_intento(INTEGER, INTEGER)
FROM PUBLIC;
REVOKE ALL ON FUNCTION public.calificar_intento(INTEGER)
FROM PUBLIC;

COMMIT;
