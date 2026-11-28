BEGIN;
SET LOCAL search_path=pg_catalog,public,pg_temp;

CREATE FUNCTION public.g010_contexto(p_actor INTEGER, p_seccion INTEGER, p_tema INTEGER, p_escritura BOOLEAN) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE c INTEGER; eid INTEGER; mid INTEGER; ce TEXT; ee TEXT; se TEXT; me TEXT; te TEXT; adm BOOLEAN;
BEGIN
IF p_actor IS NULL OR p_actor<=0 OR p_seccion IS NULL OR p_seccion<=0 OR p_tema IS NULL OR p_tema<=0 OR p_escritura IS NULL THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Actor, seccion y tema deben ser positivos.'; END IF;
IF current_setting('transaction_isolation')<>'read committed' THEN
 RAISE EXCEPTION USING ERRCODE='25000',MESSAGE='La gestion requiere READ COMMITTED.'; END IF;
SELECT e.curso_id,s.edicion_id INTO c,eid FROM public.secciones s JOIN public.ediciones_curso e ON e.id=s.edicion_id WHERE s.id=p_seccion;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Seccion no disponible.'; END IF;
SELECT estado INTO ce FROM public.cursos WHERE id=c FOR SHARE;
SELECT estado INTO ee FROM public.ediciones_curso WHERE id=eid FOR SHARE;
SELECT estado INTO se FROM public.secciones WHERE id=p_seccion FOR SHARE;
SELECT m.id INTO mid FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=p_tema AND m.curso_id=c;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Tema y seccion deben pertenecer al mismo curso.'; END IF;

SELECT estado INTO me FROM public.modulos WHERE id=mid FOR SHARE;
SELECT estado INTO te FROM public.temas WHERE id=p_tema FOR SHARE;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Tema no disponible.'; END IF;
PERFORM id FROM public.usuarios WHERE id=p_actor AND activo FOR SHARE;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Cuenta no autorizada.'; END IF;
PERFORM id FROM public.usuario_roles WHERE usuario_id=p_actor ORDER BY id FOR SHARE;
SELECT EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=p_actor AND ur.activo AND r.codigo='ADMINISTRADOR') INTO adm;
IF NOT adm THEN
 IF NOT EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=p_actor AND ur.activo AND r.codigo='DOCENTE') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Se requiere administrador o docente autorizado.'; END IF;
 PERFORM id FROM public.curso_editores WHERE usuario_id=p_actor AND curso_id=c AND activo FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='El docente no es editor activo del curso.'; END IF;
 PERFORM id FROM public.seccion_docentes WHERE usuario_id=p_actor AND seccion_id=p_seccion AND activo FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='El docente no esta asignado a la seccion.'; END IF;
END IF;
IF p_escritura AND (ce='ARCHIVADO' OR ee IN ('FINALIZADA','CANCELADA') OR se='CANCELADA' OR me='ARCHIVADO' OR te='ARCHIVADO') THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='El contexto no permite editar contenido.'; END IF;
END;
$fn$;

CREATE FUNCTION public.g010_actividad(p_actor INTEGER, p_id INTEGER, p_escritura BOOLEAN, p_borrador BOOLEAN) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE a public.actividades;
BEGIN
IF p_id IS NULL OR p_id<=0 THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Actividad invalida.'; END IF;
IF p_escritura THEN SELECT * INTO a FROM public.actividades WHERE id=p_id FOR UPDATE;
ELSE SELECT * INTO a FROM public.actividades WHERE id=p_id FOR SHARE; END IF;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Actividad no disponible.'; END IF;
PERFORM public.g010_contexto(p_actor,a.seccion_id,a.tema_id,p_escritura);
IF p_borrador AND (a.estado<>'BORRADOR' OR EXISTS(SELECT 1 FROM public.intentos WHERE actividad_id=a.id)) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Solo se edita un BORRADOR sin intentos.'; END IF;
IF p_escritura AND p_borrador THEN UPDATE public.actividades SET actualizado_en=clock_timestamp() WHERE id=a.id RETURNING * INTO a; END IF;
RETURN a;
END;
$fn$;

CREATE FUNCTION public.g010_padre(p_actor INTEGER, p_id INTEGER, p_opcion BOOLEAN, p_escritura BOOLEAN) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE aid INTEGER;
BEGIN
IF p_id IS NULL OR p_id<=0 OR p_opcion IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Identificador de contenido invalido.'; END IF;
IF p_opcion THEN SELECT p.actividad_id INTO aid FROM public.opciones_respuestas o JOIN public.preguntas p ON p.id=o.pregunta_id WHERE o.id=p_id;
ELSE SELECT actividad_id INTO aid FROM public.preguntas WHERE id=p_id; END IF;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Contenido no disponible.'; END IF;
PERFORM public.g010_actividad(p_actor,aid,p_escritura,p_escritura);

IF (p_opcion AND NOT EXISTS(SELECT 1 FROM public.opciones_respuestas WHERE id=p_id)) OR (NOT p_opcion AND NOT EXISTS(SELECT 1 FROM public.preguntas WHERE id=p_id)) THEN
 RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Contenido eliminado concurrentemente.'; END IF;
RETURN aid;
END;
$fn$;

CREATE FUNCTION public.g010_datos(p_titulo TEXT, p_instrucciones TEXT, p_finalidad TEXT, p_dificultad TEXT, p_max_intentos INTEGER, p_duracion_minutos INTEGER, p_desde TIMESTAMPTZ, p_hasta TIMESTAMPTZ) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_titulo IS NULL OR btrim(p_titulo)='' OR p_instrucciones IS NULL OR btrim(p_instrucciones)='' OR p_finalidad IS NULL OR p_finalidad NOT IN ('PRACTICA','EVALUACION') OR (p_dificultad IS NOT NULL AND p_dificultad NOT IN ('BAJA','MEDIA','ALTA')) OR (p_max_intentos IS NOT NULL AND p_max_intentos<=0) OR (p_duracion_minutos IS NOT NULL AND p_duracion_minutos<=0) OR p_desde IS NULL OR NOT isfinite(p_desde) OR (p_hasta IS NOT NULL AND (NOT isfinite(p_hasta) OR p_hasta<=p_desde)) THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Configuracion de actividad invalida.'; END IF;
END;
$fn$;

CREATE FUNCTION public.crear_actividad(p_actor INTEGER, p_seccion INTEGER, p_tema INTEGER, p_titulo TEXT, p_instrucciones TEXT, p_finalidad TEXT, p_dificultad TEXT, p_max_intentos INTEGER, p_duracion_minutos INTEGER, p_desde TIMESTAMPTZ, p_hasta TIMESTAMPTZ) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE a public.actividades;
BEGIN
PERFORM public.g010_contexto(p_actor,p_seccion,p_tema,TRUE);
PERFORM public.g010_datos(p_titulo,p_instrucciones,p_finalidad,p_dificultad,p_max_intentos,p_duracion_minutos,p_desde,p_hasta);
INSERT INTO public.actividades(seccion_id,tema_id,titulo,instrucciones,finalidad,dificultad,max_intentos,duracion_minutos,disponible_desde,disponible_hasta,creado_por)
VALUES(p_seccion,p_tema,btrim(p_titulo),btrim(p_instrucciones),p_finalidad,p_dificultad,p_max_intentos,p_duracion_minutos,p_desde,p_hasta,p_actor) RETURNING * INTO a;
RETURN a;
END;
$fn$;

CREATE FUNCTION public.listar_actividades_gestion(p_actor INTEGER, p_seccion INTEGER, p_tema INTEGER) RETURNS SETOF public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_contexto(p_actor,p_seccion,p_tema,FALSE);
RETURN QUERY SELECT a.* FROM public.actividades a WHERE a.seccion_id=p_seccion AND a.tema_id=p_tema ORDER BY a.id;
END;
$fn$;

CREATE FUNCTION public.obtener_actividad_gestion(p_actor INTEGER, p_actividad INTEGER) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
RETURN public.g010_actividad(p_actor,p_actividad,FALSE,FALSE);
END;
$fn$;

CREATE FUNCTION public.actualizar_actividad(p_actor INTEGER, p_actividad INTEGER, p_titulo TEXT, p_instrucciones TEXT, p_finalidad TEXT, p_dificultad TEXT, p_max_intentos INTEGER, p_duracion_minutos INTEGER, p_desde TIMESTAMPTZ, p_hasta TIMESTAMPTZ) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE a public.actividades;
BEGIN
a:=public.g010_actividad(p_actor,p_actividad,TRUE,TRUE);
PERFORM public.g010_datos(p_titulo,p_instrucciones,p_finalidad,p_dificultad,p_max_intentos,p_duracion_minutos,p_desde,p_hasta);
UPDATE public.actividades SET titulo=btrim(p_titulo),instrucciones=btrim(p_instrucciones),finalidad=p_finalidad,dificultad=p_dificultad,max_intentos=p_max_intentos,duracion_minutos=p_duracion_minutos,disponible_desde=p_desde,disponible_hasta=p_hasta,actualizado_en=clock_timestamp() WHERE id=a.id RETURNING * INTO a;
RETURN a;
END;
$fn$;

CREATE FUNCTION public.publicar_actividad(p_actor INTEGER, p_actividad INTEGER) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE a public.actividades; n BIGINT; total NUMERIC; me TEXT; te TEXT;
BEGIN
a:=public.g010_actividad(p_actor,p_actividad,TRUE,FALSE);
IF a.dificultad IS NULL THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Clasificar dificultad antes de publicar.'; END IF;
SELECT m.estado,t.estado INTO me,te FROM public.temas t JOIN public.modulos m ON m.id=t.modulo_id WHERE t.id=a.tema_id;
IF me<>'PUBLICADO' OR te<>'PUBLICADO' THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Modulo y tema deben estar PUBLICADOS.'; END IF;
IF a.disponible_hasta IS NOT NULL AND a.disponible_hasta<=clock_timestamp() THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='La disponibilidad ya termino.'; END IF;
SELECT count(*),sum(puntaje_maximo) INTO n,total FROM public.preguntas WHERE actividad_id=a.id;
IF n=0 OR total IS NULL OR total='NaN'::numeric OR total<=0 OR total>99999999.99 OR EXISTS(
 SELECT 1 FROM public.preguntas p LEFT JOIN public.opciones_respuestas o ON o.pregunta_id=p.id WHERE p.actividad_id=a.id GROUP BY p.id,p.tipo
 HAVING count(o.id)<2 OR (p.tipo='SELECCION_UNICA' AND count(o.id) FILTER(WHERE o.es_correcta)<>1) OR (p.tipo='SELECCION_MULTIPLE' AND count(o.id) FILTER(WHERE o.es_correcta)<2)) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Cuestionario o puntaje total no valido para publicar.'; END IF;

UPDATE public.actividades SET estado='PUBLICADO',actualizado_en=clock_timestamp() WHERE id=a.id RETURNING * INTO a;
RETURN a;
END;
$fn$;

CREATE FUNCTION public.cambiar_estado_actividad(p_actor INTEGER, p_actividad INTEGER, p_estado TEXT) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE a public.actividades;
BEGIN
IF p_estado IS NULL OR p_estado NOT IN ('BORRADOR','PUBLICADO','ARCHIVADO') THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Estado invalido.'; END IF;
IF p_estado='PUBLICADO' THEN RETURN public.publicar_actividad(p_actor,p_actividad); END IF;
a:=public.g010_actividad(p_actor,p_actividad,TRUE,FALSE);
IF a.estado=p_estado THEN RETURN a; END IF;
IF p_estado='BORRADOR' AND EXISTS(SELECT 1 FROM public.intentos WHERE actividad_id=a.id) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Conservar historial: no volver a BORRADOR.'; END IF;
IF p_estado='ARCHIVADO' AND EXISTS(SELECT 1 FROM public.intentos WHERE actividad_id=a.id AND estado='EN_CURSO') THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Entregar o cerrar intentos abiertos antes de archivar.'; END IF;
UPDATE public.actividades SET estado=p_estado,actualizado_en=clock_timestamp() WHERE id=a.id RETURNING * INTO a;
RETURN a;
END;
$fn$;

CREATE FUNCTION public.eliminar_actividad(p_actor INTEGER, p_actividad INTEGER) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_actividad(p_actor,p_actividad,TRUE,TRUE);
DELETE FROM public.opciones_respuestas o USING public.preguntas p WHERE o.pregunta_id=p.id AND p.actividad_id=p_actividad;
DELETE FROM public.preguntas WHERE actividad_id=p_actividad;
DELETE FROM public.actividades WHERE id=p_actividad;
RETURN p_actividad;
END;
$fn$;

CREATE FUNCTION public.g010_pregunta_datos(p_enunciado TEXT, p_tipo TEXT, p_orden INTEGER, p_puntaje NUMERIC, p_explicacion TEXT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_enunciado IS NULL OR btrim(p_enunciado)='' OR p_tipo IS NULL OR p_tipo NOT IN ('SELECCION_UNICA','SELECCION_MULTIPLE') OR p_orden IS NULL OR p_orden<=0 OR p_puntaje IS NULL OR p_puntaje='NaN'::numeric OR p_puntaje<=0 OR p_puntaje>99999999.99 OR round(p_puntaje,2)<=0 OR (p_explicacion IS NOT NULL AND btrim(p_explicacion)='') THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Datos de pregunta invalidos.'; END IF;
END;
$fn$;

CREATE FUNCTION public.crear_pregunta(p_actor INTEGER, p_actividad INTEGER, p_enunciado TEXT, p_tipo TEXT, p_orden INTEGER, p_puntaje NUMERIC, p_explicacion TEXT) RETURNS public.preguntas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE q public.preguntas;
BEGIN
PERFORM public.g010_actividad(p_actor,p_actividad,TRUE,TRUE);
PERFORM public.g010_pregunta_datos(p_enunciado,p_tipo,p_orden,p_puntaje,p_explicacion);
INSERT INTO public.preguntas(actividad_id,enunciado,tipo,orden,puntaje_maximo,explicacion) VALUES(p_actividad,btrim(p_enunciado),p_tipo,p_orden,round(p_puntaje,2),CASE WHEN p_explicacion IS NULL THEN NULL ELSE btrim(p_explicacion) END) RETURNING * INTO q;
RETURN q;
END;
$fn$;

CREATE FUNCTION public.listar_preguntas_gestion(p_actor INTEGER, p_actividad INTEGER) RETURNS SETOF public.preguntas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_actividad(p_actor,p_actividad,FALSE,FALSE);
RETURN QUERY SELECT p.* FROM public.preguntas p WHERE actividad_id=p_actividad ORDER BY orden,id;
END;
$fn$;

CREATE FUNCTION public.obtener_pregunta_gestion(p_actor INTEGER, p_pregunta INTEGER) RETURNS public.preguntas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE q public.preguntas;
BEGIN
PERFORM public.g010_padre(p_actor,p_pregunta,FALSE,FALSE);
SELECT * INTO q FROM public.preguntas WHERE id=p_pregunta; RETURN q;
END;
$fn$;

CREATE FUNCTION public.actualizar_pregunta(p_actor INTEGER, p_pregunta INTEGER, p_enunciado TEXT, p_tipo TEXT, p_orden INTEGER, p_puntaje NUMERIC, p_explicacion TEXT) RETURNS public.preguntas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE q public.preguntas;
BEGIN
PERFORM public.g010_padre(p_actor,p_pregunta,FALSE,TRUE);
PERFORM public.g010_pregunta_datos(p_enunciado,p_tipo,p_orden,p_puntaje,p_explicacion);
UPDATE public.preguntas SET enunciado=btrim(p_enunciado),tipo=p_tipo,orden=p_orden,puntaje_maximo=round(p_puntaje,2),explicacion=CASE WHEN p_explicacion IS NULL THEN NULL ELSE btrim(p_explicacion) END WHERE id=p_pregunta RETURNING * INTO q;
RETURN q;
END;
$fn$;

CREATE FUNCTION public.eliminar_pregunta(p_actor INTEGER, p_pregunta INTEGER) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_padre(p_actor,p_pregunta,FALSE,TRUE);
DELETE FROM public.opciones_respuestas WHERE pregunta_id=p_pregunta;
DELETE FROM public.preguntas WHERE id=p_pregunta;
RETURN p_pregunta;
END;
$fn$;

CREATE FUNCTION public.g010_opcion_datos(p_texto TEXT, p_orden INTEGER, p_correcta BOOLEAN) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_texto IS NULL OR btrim(p_texto)='' OR p_orden IS NULL OR p_orden<=0 OR p_correcta IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Datos de opcion invalidos.'; END IF;
END;
$fn$;

CREATE FUNCTION public.crear_opcion_respuesta(p_actor INTEGER, p_pregunta INTEGER, p_texto TEXT, p_orden INTEGER, p_correcta BOOLEAN) RETURNS public.opciones_respuestas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE o public.opciones_respuestas;
BEGIN
PERFORM public.g010_padre(p_actor,p_pregunta,FALSE,TRUE);
PERFORM public.g010_opcion_datos(p_texto,p_orden,p_correcta);
INSERT INTO public.opciones_respuestas(pregunta_id,texto,orden,es_correcta) VALUES(p_pregunta,btrim(p_texto),p_orden,p_correcta) RETURNING * INTO o; RETURN o;
END;
$fn$;

CREATE FUNCTION public.listar_opciones_gestion(p_actor INTEGER, p_pregunta INTEGER) RETURNS SETOF public.opciones_respuestas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_padre(p_actor,p_pregunta,FALSE,FALSE);
RETURN QUERY SELECT o.* FROM public.opciones_respuestas o WHERE pregunta_id=p_pregunta ORDER BY orden,id;
END;
$fn$;

CREATE FUNCTION public.obtener_opcion_gestion(p_actor INTEGER, p_opcion INTEGER) RETURNS public.opciones_respuestas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE o public.opciones_respuestas;
BEGIN
PERFORM public.g010_padre(p_actor,p_opcion,TRUE,FALSE);
SELECT * INTO o FROM public.opciones_respuestas WHERE id=p_opcion; RETURN o;
END;
$fn$;

CREATE FUNCTION public.actualizar_opcion_respuesta(p_actor INTEGER, p_opcion INTEGER, p_texto TEXT, p_orden INTEGER, p_correcta BOOLEAN) RETURNS public.opciones_respuestas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE o public.opciones_respuestas;
BEGIN
PERFORM public.g010_padre(p_actor,p_opcion,TRUE,TRUE);
PERFORM public.g010_opcion_datos(p_texto,p_orden,p_correcta);
UPDATE public.opciones_respuestas SET texto=btrim(p_texto),orden=p_orden,es_correcta=p_correcta WHERE id=p_opcion RETURNING * INTO o; RETURN o;
END;
$fn$;

CREATE FUNCTION public.eliminar_opcion_respuesta(p_actor INTEGER, p_opcion INTEGER) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g010_padre(p_actor,p_opcion,TRUE,TRUE);
DELETE FROM public.opciones_respuestas WHERE id=p_opcion;
RETURN p_opcion;
END;
$fn$;

CREATE FUNCTION public.reordenar_preguntas(p_actor INTEGER, p_padre INTEGER, p_ids INTEGER[]) RETURNS SETOF public.preguntas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE n BIGINT; m INTEGER;
BEGIN
PERFORM public.g010_actividad(p_actor,p_padre,TRUE,TRUE);
IF p_ids IS NULL OR coalesce(array_ndims(p_ids),1)<>1 OR EXISTS(SELECT 1 FROM unnest(p_ids) x WHERE x IS NULL) OR (SELECT count(*) FROM unnest(p_ids))<>(SELECT count(DISTINCT x) FROM unnest(p_ids) x) THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Permutacion invalida.'; END IF;
SELECT count(*),coalesce(max(orden),0) INTO n,m FROM public.preguntas WHERE actividad_id=p_padre;
IF n<>cardinality(p_ids) OR EXISTS(SELECT 1 FROM unnest(p_ids) x WHERE NOT EXISTS(SELECT 1 FROM public.preguntas WHERE id=x AND actividad_id=p_padre)) OR m::BIGINT+n>2147483647 THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Enviar todos los IDs del padre sin repetidos; orden temporal fuera de rango.'; END IF;
UPDATE public.preguntas t SET orden=(m+u.n)::INTEGER FROM unnest(p_ids) WITH ORDINALITY u(id,n) WHERE t.id=u.id;
UPDATE public.preguntas t SET orden=u.n::INTEGER FROM unnest(p_ids) WITH ORDINALITY u(id,n) WHERE t.id=u.id;
RETURN QUERY SELECT t.* FROM public.preguntas t WHERE actividad_id=p_padre ORDER BY orden,id;
END;
$fn$;

CREATE FUNCTION public.reordenar_opciones(p_actor INTEGER, p_padre INTEGER, p_ids INTEGER[]) RETURNS SETOF public.opciones_respuestas
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE n BIGINT; m INTEGER;
BEGIN
PERFORM public.g010_padre(p_actor,p_padre,FALSE,TRUE);
IF p_ids IS NULL OR coalesce(array_ndims(p_ids),1)<>1 OR EXISTS(SELECT 1 FROM unnest(p_ids) x WHERE x IS NULL) OR (SELECT count(*) FROM unnest(p_ids))<>(SELECT count(DISTINCT x) FROM unnest(p_ids) x) THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Permutacion invalida.'; END IF;
SELECT count(*),coalesce(max(orden),0) INTO n,m FROM public.opciones_respuestas WHERE pregunta_id=p_padre;
IF n<>cardinality(p_ids) OR EXISTS(SELECT 1 FROM unnest(p_ids) x WHERE NOT EXISTS(SELECT 1 FROM public.opciones_respuestas WHERE id=x AND pregunta_id=p_padre)) OR m::BIGINT+n>2147483647 THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Enviar todos los IDs del padre sin repetidos; orden temporal fuera de rango.'; END IF;
UPDATE public.opciones_respuestas t SET orden=(m+u.n)::INTEGER FROM unnest(p_ids) WITH ORDINALITY u(id,n) WHERE t.id=u.id;
UPDATE public.opciones_respuestas t SET orden=u.n::INTEGER FROM unnest(p_ids) WITH ORDINALITY u(id,n) WHERE t.id=u.id;
RETURN QUERY SELECT t.* FROM public.opciones_respuestas t WHERE pregunta_id=p_padre ORDER BY orden,id;
END;
$fn$;

CREATE FUNCTION public.duplicar_actividad(p_actor INTEGER, p_origen INTEGER, p_seccion INTEGER, p_tema INTEGER, p_titulo TEXT, p_desde TIMESTAMPTZ, p_hasta TIMESTAMPTZ) RETURNS public.actividades
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE src public.actividades; dst public.actividades; q RECORD; qid INTEGER;
BEGIN
src:=public.g010_actividad(p_actor,p_origen,FALSE,FALSE);
dst:=public.crear_actividad(p_actor,p_seccion,p_tema,p_titulo,src.instrucciones,src.finalidad,src.dificultad,src.max_intentos,src.duracion_minutos,p_desde,p_hasta);
FOR q IN SELECT * FROM public.preguntas WHERE actividad_id=src.id ORDER BY orden,id LOOP
 INSERT INTO public.preguntas(actividad_id,enunciado,tipo,orden,puntaje_maximo,explicacion) VALUES(dst.id,q.enunciado,q.tipo,q.orden,q.puntaje_maximo,q.explicacion) RETURNING id INTO qid;
 INSERT INTO public.opciones_respuestas(pregunta_id,texto,orden,es_correcta) SELECT qid,texto,orden,es_correcta FROM public.opciones_respuestas WHERE pregunta_id=q.id ORDER BY orden,id;
END LOOP;
RETURN dst;
END;
$fn$;

CREATE FUNCTION public.g010_proteger_borrado() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF OLD.estado<>'BORRADOR' OR EXISTS(SELECT 1 FROM public.intentos WHERE actividad_id=OLD.id) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Solo se elimina un BORRADOR sin intentos.'; END IF; RETURN OLD;
END;
$fn$;

CREATE TRIGGER trg_g010_proteger_borrado BEFORE DELETE ON public.actividades FOR EACH ROW EXECUTE FUNCTION public.g010_proteger_borrado();

GRANT SELECT ON public.cursos,public.ediciones_curso,public.secciones,public.modulos,public.temas,public.curso_editores,public.seccion_docentes,public.actividades,public.preguntas,public.opciones_respuestas TO plataforma_operaciones;
GRANT UPDATE(id) ON public.cursos,public.ediciones_curso,public.secciones,public.modulos,public.temas,public.curso_editores,public.seccion_docentes TO plataforma_operaciones;
GRANT INSERT(seccion_id,tema_id,titulo,instrucciones,finalidad,dificultad,max_intentos,duracion_minutos,disponible_desde,disponible_hasta,creado_por) ON public.actividades TO plataforma_operaciones;
GRANT UPDATE(titulo,instrucciones,finalidad,dificultad,max_intentos,duracion_minutos,disponible_desde,disponible_hasta,estado,actualizado_en) ON public.actividades TO plataforma_operaciones;
GRANT INSERT(actividad_id,enunciado,tipo,orden,puntaje_maximo,explicacion), UPDATE(enunciado,tipo,orden,puntaje_maximo,explicacion) ON public.preguntas TO plataforma_operaciones;
GRANT INSERT(pregunta_id,texto,orden,es_correcta), UPDATE(texto,orden,es_correcta) ON public.opciones_respuestas TO plataforma_operaciones;
GRANT DELETE ON public.actividades,public.preguntas,public.opciones_respuestas TO plataforma_operaciones;
GRANT USAGE ON SEQUENCE public.actividades_id_seq,public.preguntas_id_seq,public.opciones_respuestas_id_seq TO plataforma_operaciones;
REVOKE INSERT,UPDATE,DELETE ON public.actividades,public.preguntas,public.opciones_respuestas FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g010_contexto(INTEGER,INTEGER,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_contexto(INTEGER,INTEGER,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g010_actividad(INTEGER,INTEGER,BOOLEAN,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_actividad(INTEGER,INTEGER,BOOLEAN,BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g010_padre(INTEGER,INTEGER,BOOLEAN,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_padre(INTEGER,INTEGER,BOOLEAN,BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g010_datos(TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_datos(TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.crear_actividad(INTEGER,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_actividad(INTEGER,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.crear_actividad(INTEGER,INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) TO plataforma_backend;

ALTER FUNCTION public.listar_actividades_gestion(INTEGER,INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_actividades_gestion(INTEGER,INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.listar_actividades_gestion(INTEGER,INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_actividad_gestion(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_actividad_gestion(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.obtener_actividad_gestion(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_actividad(INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_actividad(INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_actividad(INTEGER,INTEGER,TEXT,TEXT,TEXT,TEXT,INTEGER,INTEGER,TIMESTAMPTZ,TIMESTAMPTZ) TO plataforma_backend;

ALTER FUNCTION public.publicar_actividad(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.publicar_actividad(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.publicar_actividad(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.cambiar_estado_actividad(INTEGER,INTEGER,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_estado_actividad(INTEGER,INTEGER,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.cambiar_estado_actividad(INTEGER,INTEGER,TEXT) TO plataforma_backend;

ALTER FUNCTION public.eliminar_actividad(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.eliminar_actividad(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.eliminar_actividad(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.g010_pregunta_datos(TEXT,TEXT,INTEGER,NUMERIC,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_pregunta_datos(TEXT,TEXT,INTEGER,NUMERIC,TEXT) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.crear_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.crear_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) TO plataforma_backend;

ALTER FUNCTION public.listar_preguntas_gestion(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_preguntas_gestion(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.listar_preguntas_gestion(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_pregunta_gestion(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_pregunta_gestion(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.obtener_pregunta_gestion(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_pregunta(INTEGER,INTEGER,TEXT,TEXT,INTEGER,NUMERIC,TEXT) TO plataforma_backend;

ALTER FUNCTION public.eliminar_pregunta(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.eliminar_pregunta(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.eliminar_pregunta(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.g010_opcion_datos(TEXT,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_opcion_datos(TEXT,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.crear_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.crear_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) TO plataforma_backend;

ALTER FUNCTION public.listar_opciones_gestion(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_opciones_gestion(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.listar_opciones_gestion(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_opcion_gestion(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_opcion_gestion(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.obtener_opcion_gestion(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_opcion_respuesta(INTEGER,INTEGER,TEXT,INTEGER,BOOLEAN) TO plataforma_backend;

ALTER FUNCTION public.eliminar_opcion_respuesta(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.eliminar_opcion_respuesta(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.eliminar_opcion_respuesta(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.reordenar_preguntas(INTEGER,INTEGER,INTEGER[]) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.reordenar_preguntas(INTEGER,INTEGER,INTEGER[]) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.reordenar_preguntas(INTEGER,INTEGER,INTEGER[]) TO plataforma_backend;

ALTER FUNCTION public.reordenar_opciones(INTEGER,INTEGER,INTEGER[]) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.reordenar_opciones(INTEGER,INTEGER,INTEGER[]) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.reordenar_opciones(INTEGER,INTEGER,INTEGER[]) TO plataforma_backend;

ALTER FUNCTION public.duplicar_actividad(INTEGER,INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMPTZ,TIMESTAMPTZ) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.duplicar_actividad(INTEGER,INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMPTZ,TIMESTAMPTZ) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.duplicar_actividad(INTEGER,INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMPTZ,TIMESTAMPTZ) TO plataforma_backend;

ALTER FUNCTION public.g010_proteger_borrado() OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g010_proteger_borrado() FROM PUBLIC,plataforma_backend;

COMMIT;
