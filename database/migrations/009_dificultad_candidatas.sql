-- Propuesta de BD para revision de backend y motor. Aplicar despues de 008.
-- No cambia firmas 001-008, rutas HTTP, notas ni el contrato del motor.
BEGIN;
SET LOCAL search_path=pg_catalog, public, pg_temp;

-- NULL = sin clasificar. No asignar un nivel ficticio al contenido existente.
ALTER TABLE public.actividades ADD COLUMN dificultad TEXT;
ALTER TABLE public.actividades ADD CONSTRAINT ck_actividades_dificultad
    CHECK (dificultad IN ('BAJA','MEDIA','ALTA'));
COMMENT ON COLUMN public.actividades.dificultad IS
    'Nivel pedagogico absoluto BAJA/MEDIA/ALTA; NULL significa sin clasificar. No es una accion del motor.';

CREATE FUNCTION public.proteger_dificultad_actividad()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path=pg_catalog, public, pg_temp
AS $$
BEGIN
    IF NEW.dificultad IS DISTINCT FROM OLD.dificultad
       AND OLD.dificultad IS NOT NULL
       AND EXISTS(SELECT 1 FROM public.intentos it WHERE it.actividad_id=OLD.id) THEN
        RAISE EXCEPTION USING ERRCODE='55000',
            MESSAGE='No se puede reclasificar una actividad con intentos; crear otra actividad.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_proteger_dificultad_actividad
BEFORE UPDATE OF dificultad ON public.actividades
FOR EACH ROW EXECUTE FUNCTION public.proteger_dificultad_actividad();

-- Una fila por candidata; la referencia se repite para el adaptador del backend.
-- No ordena por accion del motor: la politica de seleccion esta en el ejemplo JS.
CREATE FUNCTION public.listar_candidatas_actividad(
    p_actor_id INTEGER,p_inscripcion_id INTEGER,p_tema_id INTEGER,
    p_actividad_referencia_id INTEGER DEFAULT NULL
)
RETURNS TABLE(
    actividad_id INTEGER,tema_id INTEGER,seccion_id INTEGER,titulo TEXT,
    dificultad TEXT,intentos_iniciados BIGINT,max_intentos INTEGER,
    intentos_restantes BIGINT,disponible_desde TIMESTAMPTZ,disponible_hasta TIMESTAMPTZ,
    actividad_referencia_id INTEGER,dificultad_referencia TEXT,es_repeticion BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path=pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion INTEGER; v_curso INTEGER; v_ref INTEGER; v_dificultad TEXT;
BEGIN
    IF p_tema_id IS NULL OR p_tema_id<=0
       OR (p_actividad_referencia_id IS NOT NULL AND p_actividad_referencia_id<=0) THEN
        RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Tema o actividad de referencia invalidos.';
    END IF;
    v_seccion:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    SELECT e.curso_id INTO v_curso FROM public.inscripciones i
    JOIN public.ediciones_curso e ON e.id=i.edicion_id WHERE i.id=p_inscripcion_id;
    IF NOT EXISTS (
        SELECT 1 FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id
        WHERE t.id=p_tema_id AND t.estado='PUBLICADO' AND m.estado='PUBLICADO' AND m.curso_id=v_curso
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Tema no disponible en la inscripcion.';
    END IF;

    -- Sin referencia explicita, usar el ULTIMO intento calificado, no el ultimo
    -- con dificultad conocida. Si esa referencia no tiene nivel no inventar otro.
    IF p_actividad_referencia_id IS NULL THEN
        SELECT a.id,a.dificultad INTO v_ref,v_dificultad
        FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
        WHERE it.inscripcion_id=p_inscripcion_id AND it.estado='CALIFICADO'
          AND a.tema_id=p_tema_id AND a.seccion_id=v_seccion
        ORDER BY it.calificado_en DESC,it.id DESC LIMIT 1;
        IF NOT FOUND THEN RETURN; END IF;
    ELSE
        SELECT a.id,a.dificultad INTO v_ref,v_dificultad FROM public.actividades a
        WHERE a.id=p_actividad_referencia_id AND a.tema_id=p_tema_id AND a.seccion_id=v_seccion
          AND EXISTS(SELECT 1 FROM public.intentos it WHERE it.actividad_id=a.id
                     AND it.inscripcion_id=p_inscripcion_id AND it.estado='CALIFICADO');
        IF NOT FOUND THEN
            RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Referencia sin intento calificado propio en este contexto.';
        END IF;
    END IF;
    IF v_dificultad IS NULL THEN RETURN; END IF;

    RETURN QUERY
    SELECT a.id,a.tema_id,a.seccion_id,a.titulo,a.dificultad,n.cantidad,a.max_intentos,
           CASE WHEN a.max_intentos IS NULL THEN NULL::BIGINT
                ELSE a.max_intentos::BIGINT-n.cantidad END,
           a.disponible_desde,a.disponible_hasta,v_ref,v_dificultad,a.id=v_ref
    FROM public.actividades a
    CROSS JOIN LATERAL (
        SELECT count(*) AS cantidad,
               count(*) FILTER (WHERE it.estado='EN_CURSO') AS abiertos
        FROM public.intentos it WHERE it.actividad_id=a.id AND it.inscripcion_id=p_inscripcion_id
    ) n
    WHERE a.seccion_id=v_seccion AND a.tema_id=p_tema_id AND a.estado='PUBLICADO'
      AND a.dificultad IS NOT NULL
      AND a.disponible_desde<=statement_timestamp()
      AND (a.disponible_hasta IS NULL OR statement_timestamp()<a.disponible_hasta)
      AND n.abiertos=0
      AND (a.max_intentos IS NULL OR n.cantidad<a.max_intentos)
    ORDER BY a.id;
END;
$$;

-- No se amplian escrituras directas del backend ni se habilita es_correcta.
GRANT SELECT(dificultad) ON public.actividades TO plataforma_operaciones;
ALTER FUNCTION public.listar_candidatas_actividad(INTEGER,INTEGER,INTEGER,INTEGER)
    OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_candidatas_actividad(INTEGER,INTEGER,INTEGER,INTEGER)
    FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_candidatas_actividad(INTEGER,INTEGER,INTEGER,INTEGER)
    TO plataforma_backend;
REVOKE ALL ON FUNCTION public.proteger_dificultad_actividad() FROM PUBLIC,plataforma_backend;
COMMIT;
