BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;

CREATE FUNCTION public.listar_cursos_administrables(p_actor_id integer)
RETURNS TABLE(curso_id integer, codigo text, nombre text, estado varchar(50), puede_editar_contenido boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_admin boolean; v_docente boolean;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor invalido.';
    END IF;
    SELECT coalesce(bool_or(r.codigo='ADMINISTRADOR'),false),
           coalesce(bool_or(r.codigo='DOCENTE'),false)
    INTO v_admin,v_docente
    FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
    JOIN public.roles r ON r.id=ur.rol_id
    WHERE u.id=p_actor_id AND u.activo;
    IF NOT (v_admin OR v_docente) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere administrador o docente activo.';
    END IF;
    RETURN QUERY SELECT c.id,c.codigo,c.nombre,c.estado,c.estado<>'ARCHIVADO'
    FROM public.cursos c WHERE v_admin OR EXISTS (
        SELECT 1 FROM public.curso_editores ce
        WHERE ce.curso_id=c.id AND ce.usuario_id=p_actor_id AND ce.activo
    ) ORDER BY c.nombre,c.id;
END;
$$;

CREATE FUNCTION public.listar_inscripciones_estudiante(p_actor_id integer)
RETURNS TABLE(inscripcion_id integer, curso_id integer, codigo text, curso text,
              edicion_id integer, seccion_id integer, seccion text)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor invalido.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
        JOIN public.roles r ON r.id=ur.rol_id AND r.codigo='ESTUDIANTE'
        WHERE u.id=p_actor_id AND u.activo
    ) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere cuenta y rol ESTUDIANTE activos.';
    END IF;
    RETURN QUERY
    SELECT i.id,c.id,c.codigo,c.nombre,e.id,s.id,s.codigo
    FROM public.inscripciones i JOIN public.secciones s ON s.id=i.seccion_id AND s.edicion_id=i.edicion_id
    JOIN public.ediciones_curso e ON e.id=s.edicion_id JOIN public.cursos c ON c.id=e.curso_id
    WHERE i.estudiante_id=p_actor_id AND i.estado='ACTIVA' AND c.estado='ACTIVO'
      AND s.estado<>'CANCELADA' AND e.estado<>'CANCELADA'
    ORDER BY c.nombre,i.id;
END;
$$;

CREATE FUNCTION public.validar_contexto_resultados(p_actor_id integer,p_inscripcion_id integer)
RETURNS integer LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_curso_id integer; v_seccion_id integer;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id<=0 OR p_inscripcion_id IS NULL OR p_inscripcion_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Actor o inscripcion invalidos.';
    END IF;
    SELECT e.curso_id,i.seccion_id INTO v_curso_id,v_seccion_id
    FROM public.inscripciones i JOIN public.ediciones_curso e ON e.id=i.edicion_id
    WHERE i.id=p_inscripcion_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Inscripcion no autorizada.';
    END IF;
    PERFORM public.validar_lectura_estudiante(p_actor_id,v_curso_id,p_inscripcion_id);
    RETURN v_seccion_id;
END;
$$;

CREATE FUNCTION public.listar_resultados_estudiante(p_actor_id integer,p_inscripcion_id integer)
RETURNS TABLE(actividad_id integer, tema_id integer, modulo_id integer, titulo text, finalidad text,
              intentos_calificados bigint, promedio_porcentaje numeric,
              nota_academica_porcentaje numeric, ultima_calificacion_en timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion_id integer;
BEGIN
    v_seccion_id:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    RETURN QUERY
    SELECT a.id,t.id,m.id,a.titulo,a.finalidad,coalesce(ra.intentos_calificados,0),
           ra.promedio_porcentaje,ra.nota_academica_porcentaje,
           (SELECT max(it.calificado_en) FROM public.intentos it
            WHERE it.inscripcion_id=p_inscripcion_id AND it.actividad_id=a.id)
    FROM public.actividades a JOIN public.temas t ON t.id=a.tema_id
    JOIN public.modulos m ON m.id=t.modulo_id
    LEFT JOIN public.resultados_actividades ra ON ra.actividad_id=a.id AND ra.inscripcion_id=p_inscripcion_id
    WHERE a.seccion_id=v_seccion_id AND (
        (a.estado='PUBLICADO' AND t.estado='PUBLICADO' AND m.estado='PUBLICADO')
        OR (coalesce(ra.intentos_calificados,0)>0 AND a.estado='ARCHIVADO')
    ) ORDER BY m.orden,t.orden,a.id;
END;
$$;

CREATE FUNCTION public.listar_actividad_reciente_estudiante(
    p_actor_id integer,p_inscripcion_id integer,p_limite integer DEFAULT 10
)
RETURNS TABLE(intento_id integer, actividad_id integer, tema_id integer, titulo text,
              estado text, ocurrido_en timestamptz, puntaje_porcentaje numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion_id integer;
BEGIN
    IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 100 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='El limite debe estar entre 1 y 100.';
    END IF;
    v_seccion_id:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    RETURN QUERY
    SELECT it.id,a.id,a.tema_id,a.titulo,it.estado,coalesce(it.calificado_en,it.entregado_en),
           round(it.puntaje_obtenido*100.0/nullif(it.puntaje_maximo,0),2)
    FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
    WHERE it.inscripcion_id=p_inscripcion_id AND a.seccion_id=v_seccion_id
      AND it.estado IN ('ENTREGADO','CALIFICADO')
    ORDER BY coalesce(it.calificado_en,it.entregado_en) DESC,it.id DESC LIMIT p_limite;
END;
$$;

CREATE FUNCTION public.listar_progreso_estudiante(p_actor_id integer,p_inscripcion_id integer)
RETURNS TABLE(tema_id integer, modulo_id integer, actividades_publicadas bigint,
              actividades_calificadas bigint, progreso_porcentaje numeric, completado boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion_id integer;
BEGIN
    v_seccion_id:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    RETURN QUERY
    SELECT t.id,m.id,count(a.id),count(a.id) FILTER (WHERE ra.intentos_calificados>0),
           round(count(a.id) FILTER (WHERE ra.intentos_calificados>0)*100.0/nullif(count(a.id),0),2),
           count(a.id)>0 AND count(a.id)=count(a.id) FILTER (WHERE ra.intentos_calificados>0)
    FROM public.inscripciones i JOIN public.ediciones_curso e ON e.id=i.edicion_id
    JOIN public.modulos m ON m.curso_id=e.curso_id AND m.estado='PUBLICADO'
    JOIN public.temas t ON t.modulo_id=m.id AND t.estado='PUBLICADO'
    LEFT JOIN public.actividades a ON a.tema_id=t.id AND a.seccion_id=v_seccion_id AND a.estado='PUBLICADO'
    LEFT JOIN public.resultados_actividades ra ON ra.actividad_id=a.id AND ra.inscripcion_id=i.id
    WHERE i.id=p_inscripcion_id
    GROUP BY m.id,t.id ORDER BY m.orden,t.orden,t.id;
END;
$$;

CREATE FUNCTION public.listar_minutos_intentos_estudiante(
    p_actor_id integer,p_inscripcion_id integer,p_desde date,p_hasta_exclusiva date
)
RETURNS TABLE(dia_local date, intentos_entregados bigint, minutos_transcurridos numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion_id integer;
BEGIN
    IF p_desde IS NULL OR p_hasta_exclusiva IS NULL
       OR NOT isfinite(p_desde) OR NOT isfinite(p_hasta_exclusiva)
       OR p_hasta_exclusiva<=p_desde OR p_hasta_exclusiva-p_desde>366 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Rango de fechas invalido; maximo 366 dias.';
    END IF;
    v_seccion_id:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    RETURN QUERY
    SELECT (it.iniciado_en AT TIME ZONE 'America/Santo_Domingo')::date,count(*),
           round(sum(extract(epoch FROM (it.entregado_en-it.iniciado_en)))/60,2)
    FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
    WHERE it.inscripcion_id=p_inscripcion_id AND a.seccion_id=v_seccion_id
      AND it.estado IN ('ENTREGADO','CALIFICADO')
      AND it.iniciado_en >= p_desde::timestamp AT TIME ZONE 'America/Santo_Domingo'
      AND it.iniciado_en < p_hasta_exclusiva::timestamp AT TIME ZONE 'America/Santo_Domingo'
    GROUP BY 1 ORDER BY 1;
END;
$$;

CREATE FUNCTION public.listar_interacciones_motor_estudiante(
    p_actor_id integer,p_inscripcion_id integer,p_tema_id integer
)
RETURNS TABLE(tema text, score_percentage numeric, errors bigint, attempts integer,
              repetitions integer, navigation_count integer, study_minutes numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE v_seccion_id integer; v_curso_id integer;
BEGIN
    IF p_tema_id IS NULL OR p_tema_id<=0 THEN
        RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tema invalido.';
    END IF;
    v_seccion_id:=public.validar_contexto_resultados(p_actor_id,p_inscripcion_id);
    SELECT e.curso_id INTO v_curso_id FROM public.inscripciones i
    JOIN public.ediciones_curso e ON e.id=i.edicion_id WHERE i.id=p_inscripcion_id;
    IF NOT EXISTS (
        SELECT 1 FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id
        WHERE t.id=p_tema_id AND m.curso_id=v_curso_id
          AND t.estado='PUBLICADO' AND m.estado='PUBLICADO'
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='Tema no disponible en el contexto solicitado.';
    END IF;
    RETURN QUERY
    SELECT t.nombre,round(it.puntaje_obtenido*100.0/nullif(it.puntaje_maximo,0),2),
           (SELECT count(*) FROM public.respuestas r WHERE r.intento_id=it.id AND r.puntaje_obtenido=0),
           it.numero_intento,it.numero_intento-1,0,
           round(extract(epoch FROM (it.entregado_en-it.iniciado_en))/60,2)
    FROM public.intentos it JOIN public.actividades a ON a.id=it.actividad_id
    JOIN public.temas t ON t.id=a.tema_id
    WHERE it.inscripcion_id=p_inscripcion_id AND a.seccion_id=v_seccion_id
      AND a.tema_id=p_tema_id AND it.estado='CALIFICADO'
    ORDER BY it.id;
END;
$$;

GRANT SELECT ON public.resultados_actividades TO plataforma_operaciones;
ALTER FUNCTION public.validar_contexto_resultados(integer,integer) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.validar_contexto_resultados(integer,integer) FROM PUBLIC, plataforma_backend;

DO $$
DECLARE firma text;
BEGIN
    FOREACH firma IN ARRAY ARRAY[
        'listar_cursos_administrables(integer)',
        'listar_inscripciones_estudiante(integer)',
        'listar_resultados_estudiante(integer,integer)',
        'listar_actividad_reciente_estudiante(integer,integer,integer)',
        'listar_progreso_estudiante(integer,integer)',
        'listar_minutos_intentos_estudiante(integer,integer,date,date)',
        'listar_interacciones_motor_estudiante(integer,integer,integer)'
    ] LOOP
        EXECUTE format('ALTER FUNCTION public.%s OWNER TO plataforma_operaciones',firma);
        EXECUTE format('REVOKE ALL ON FUNCTION public.%s FROM PUBLIC',firma);
        EXECUTE format('GRANT EXECUTE ON FUNCTION public.%s TO plataforma_backend',firma);
    END LOOP;
END;
$$;
COMMIT;
