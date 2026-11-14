BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE FUNCTION public.validar_lectura_estudiante(
    p_actor_id INTEGER, p_curso_id INTEGER, p_inscripcion_id INTEGER DEFAULT NULL
)
RETURNS VOID LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF p_actor_id IS NULL OR p_actor_id <= 0
       OR p_curso_id IS NULL OR p_curso_id <= 0
       OR (p_inscripcion_id IS NOT NULL AND p_inscripcion_id <= 0) THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Identificadores invalidos para la lectura.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios u
        JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
        JOIN public.roles r ON r.id=ur.rol_id AND r.codigo='ESTUDIANTE'
        WHERE u.id=p_actor_id AND u.activo
    ) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere cuenta y rol ESTUDIANTE activos.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.inscripciones i
        JOIN public.secciones s ON s.id=i.seccion_id AND s.edicion_id=i.edicion_id
        JOIN public.ediciones_curso e ON e.id=s.edicion_id
        JOIN public.cursos c ON c.id=e.curso_id
        WHERE i.estudiante_id=p_actor_id AND i.estado='ACTIVA'
          AND c.id=p_curso_id AND c.estado='ACTIVO'
          AND s.estado<>'CANCELADA' AND e.estado<>'CANCELADA'
          AND (p_inscripcion_id IS NULL OR i.id=p_inscripcion_id)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='No tiene una inscripcion activa autorizada para este contenido.';
    END IF;
END;
$$;

CREATE FUNCTION public.listar_modulos_publicados_estudiante(p_actor_id INTEGER,p_curso_id INTEGER)
RETURNS TABLE (
    id INTEGER,curso_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,
    estado VARCHAR(50),actualizado_en TIMESTAMPTZ,total_temas BIGINT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    PERFORM public.validar_lectura_estudiante(p_actor_id,p_curso_id);
    RETURN QUERY
    SELECT m.id,m.curso_id,m.nombre,m.descripcion,m.orden,m.estado,m.actualizado_en,
        (SELECT COUNT(*) FROM public.temas t WHERE t.modulo_id=m.id AND t.estado='PUBLICADO')
    FROM public.modulos m
    WHERE m.curso_id=p_curso_id AND m.estado='PUBLICADO'
    ORDER BY m.orden,m.id;
END;
$$;

CREATE FUNCTION public.listar_temas_publicados_estudiante(p_actor_id INTEGER,p_modulo_id INTEGER)
RETURNS TABLE (
    id INTEGER,modulo_id INTEGER,nombre TEXT,descripcion TEXT,orden INTEGER,
    estado VARCHAR(50),actualizado_en TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso_id INTEGER;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 OR p_modulo_id IS NULL OR p_modulo_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor y modulo deben ser identificadores positivos.';
    END IF;
    SELECT m.curso_id INTO v_curso_id FROM public.modulos m
    WHERE m.id=p_modulo_id AND m.estado='PUBLICADO';
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='Modulo no disponible.';
    END IF;
    PERFORM public.validar_lectura_estudiante(p_actor_id,v_curso_id);
    RETURN QUERY
    SELECT t.id,t.modulo_id,t.nombre,t.descripcion,t.orden,t.estado,t.actualizado_en
    FROM public.temas t WHERE t.modulo_id=p_modulo_id AND t.estado='PUBLICADO'
    ORDER BY t.orden,t.id;
END;
$$;

CREATE FUNCTION public.listar_actividades_publicadas_estudiante(
    p_actor_id INTEGER,p_inscripcion_id INTEGER,p_tema_id INTEGER
)
RETURNS TABLE (
    id INTEGER,seccion_id INTEGER,tema_id INTEGER,titulo TEXT,finalidad TEXT,
    metodo_calificacion TEXT,max_intentos INTEGER,duracion_minutos INTEGER,
    disponible_desde TIMESTAMPTZ,disponible_hasta TIMESTAMPTZ,
    estado VARCHAR(50),disponible_ahora BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso_id INTEGER;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 OR p_inscripcion_id IS NULL OR p_inscripcion_id<=0
       OR p_tema_id IS NULL OR p_tema_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor, inscripcion y tema deben ser identificadores positivos.';
    END IF;
    SELECT m.curso_id INTO v_curso_id
    FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id
    WHERE t.id=p_tema_id AND t.estado='PUBLICADO' AND m.estado='PUBLICADO';
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='Tema no disponible.';
    END IF;
    PERFORM public.validar_lectura_estudiante(p_actor_id,v_curso_id,p_inscripcion_id);
    RETURN QUERY
    SELECT a.id,a.seccion_id,a.tema_id,a.titulo,a.finalidad,a.metodo_calificacion,
        a.max_intentos,a.duracion_minutos,a.disponible_desde,a.disponible_hasta,a.estado,
        (statement_timestamp()>=a.disponible_desde
         AND (a.disponible_hasta IS NULL OR statement_timestamp()<a.disponible_hasta))
    FROM public.actividades a JOIN public.inscripciones i ON i.seccion_id=a.seccion_id
    WHERE i.id=p_inscripcion_id AND a.tema_id=p_tema_id AND a.estado='PUBLICADO'
    ORDER BY a.disponible_desde,a.id;
END;
$$;

CREATE FUNCTION public.obtener_cuestionario_estudiante(p_actor_id INTEGER,p_intento_id INTEGER)
RETURNS TABLE (
    intento_id INTEGER,actividad_id INTEGER,instrucciones TEXT,vence_en TIMESTAMPTZ,
    pregunta_id INTEGER,respuesta_id INTEGER,enunciado TEXT,tipo TEXT,orden INTEGER,
    puntaje_maximo NUMERIC(10,2),opciones JSONB,opciones_seleccionadas INTEGER[]
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_contexto RECORD;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 OR p_intento_id IS NULL OR p_intento_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor e intento deben ser identificadores positivos.';
    END IF;
    SELECT it.id,it.actividad_id,it.inscripcion_id,it.estado,it.vence_en,
           i.estudiante_id,i.seccion_id AS seccion_inscripcion,
           a.seccion_id,a.estado AS estado_actividad,a.disponible_desde,a.disponible_hasta,
           t.estado AS estado_tema,m.estado AS estado_modulo,m.curso_id
    INTO v_contexto
    FROM public.intentos it JOIN public.inscripciones i ON i.id=it.inscripcion_id
    JOIN public.actividades a ON a.id=it.actividad_id
    JOIN public.temas t ON t.id=a.tema_id JOIN public.modulos m ON m.id=t.modulo_id
    WHERE it.id=p_intento_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='Intento no disponible.';
    END IF;
    IF v_contexto.estudiante_id<>p_actor_id
       OR v_contexto.seccion_id<>v_contexto.seccion_inscripcion THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='El intento no pertenece al contexto autorizado.';
    END IF;
    PERFORM public.validar_lectura_estudiante(p_actor_id,v_contexto.curso_id,v_contexto.inscripcion_id);
    IF v_contexto.estado_actividad<>'PUBLICADO' OR v_contexto.estado_tema<>'PUBLICADO'
       OR v_contexto.estado_modulo<>'PUBLICADO' THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='Contenido no disponible.';
    END IF;
    IF v_contexto.estado<>'EN_CURSO'
       OR statement_timestamp()<v_contexto.disponible_desde
       OR (v_contexto.disponible_hasta IS NOT NULL AND statement_timestamp()>=v_contexto.disponible_hasta)
       OR (v_contexto.vence_en IS NOT NULL AND statement_timestamp()>=v_contexto.vence_en) THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='El cuestionario requiere un intento en curso y dentro de su plazo.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.preguntas p WHERE p.actividad_id=v_contexto.actividad_id)
       OR EXISTS (
           SELECT 1 FROM public.preguntas p WHERE p.actividad_id=v_contexto.actividad_id
           AND NOT EXISTS (SELECT 1 FROM public.respuestas r
               WHERE r.intento_id=p_intento_id AND r.pregunta_id=p.id AND r.actividad_id=p.actividad_id)
       ) THEN
        RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='El intento no tiene un cuestionario completo; revisar su creacion.';
    END IF;
    RETURN QUERY
    SELECT it.id,a.id,a.instrucciones,it.vence_en,p.id,r.id,p.enunciado,p.tipo,p.orden,p.puntaje_maximo,
        COALESCE((SELECT jsonb_agg(jsonb_build_object('id',o.id,'texto',o.texto,'orden',o.orden)
                                    ORDER BY o.orden,o.id)
                  FROM public.opciones_respuestas o WHERE o.pregunta_id=p.id),'[]'::JSONB),
        ARRAY(SELECT ro.opcion_id FROM public.respuesta_opciones ro
              JOIN public.opciones_respuestas o ON o.id=ro.opcion_id AND o.pregunta_id=p.id
              WHERE ro.respuesta_id=r.id ORDER BY o.orden,o.id)
    FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
    JOIN public.preguntas p ON p.actividad_id=a.id
    JOIN public.respuestas r ON r.intento_id=it.id AND r.pregunta_id=p.id AND r.actividad_id=a.id
    WHERE it.id=p_intento_id ORDER BY p.orden,p.id;
END;
$$;

GRANT SELECT ON public.usuarios,public.usuario_roles,public.roles,public.cursos,
    public.ediciones_curso,public.secciones,public.inscripciones,public.modulos,
    public.temas,public.actividades,public.intentos,public.preguntas,public.respuestas,
    public.opciones_respuestas,public.respuesta_opciones TO plataforma_operaciones;

ALTER FUNCTION public.validar_lectura_estudiante(INTEGER,INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.validar_lectura_estudiante(INTEGER,INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.listar_modulos_publicados_estudiante(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_modulos_publicados_estudiante(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_modulos_publicados_estudiante(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.listar_temas_publicados_estudiante(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_temas_publicados_estudiante(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_temas_publicados_estudiante(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.listar_actividades_publicadas_estudiante(INTEGER,INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_actividades_publicadas_estudiante(INTEGER,INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.listar_actividades_publicadas_estudiante(INTEGER,INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_cuestionario_estudiante(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_cuestionario_estudiante(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;
GRANT EXECUTE ON FUNCTION public.obtener_cuestionario_estudiante(INTEGER,INTEGER) TO plataforma_backend;

COMMIT;
