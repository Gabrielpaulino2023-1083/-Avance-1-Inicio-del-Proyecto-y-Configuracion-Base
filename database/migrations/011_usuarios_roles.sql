BEGIN;
SET LOCAL search_path=pg_catalog,public,pg_temp;
DO $$ BEGIN
 IF to_regprocedure('public.publicar_actividad(integer,integer)') IS NULL THEN
  RAISE EXCEPTION 'Aplicar 010 antes de 011.'; END IF;
 IF EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.activo AND r.codigo IN ('ESTUDIANTE','DOCENTE') GROUP BY ur.usuario_id HAVING count(*)>1) THEN
  RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Hay usuarios con ESTUDIANTE y DOCENTE activos. Revisarlos antes de instalar; no se corrigen automaticamente.'; END IF;
END; $$;
CREATE TYPE public.usuario_resumen_011 AS (
 id INTEGER,nombre VARCHAR(50),apellido VARCHAR(50),email TEXT,activo BOOLEAN,
 creado_en TIMESTAMPTZ,actualizado_en TIMESTAMPTZ,roles_activos TEXT[],rol_principal TEXT
);


CREATE FUNCTION public.g011_serializar() RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF current_setting('transaction_isolation')<>'read committed' THEN
 RAISE EXCEPTION USING ERRCODE='25000',MESSAGE='Usuarios y roles requieren READ COMMITTED.'; END IF;
PERFORM pg_advisory_xact_lock(11011,1);
END;
$fn$;


CREATE FUNCTION public.g011_serializar_sentencia() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_serializar(); RETURN NULL;
END;
$fn$;


CREATE FUNCTION public.g011_admin(p_actor INTEGER) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_actor IS NULL OR p_actor<=0 THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Actor invalido.'; END IF;
PERFORM id FROM public.usuarios WHERE id=p_actor AND activo FOR SHARE;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Se requiere administrador activo.'; END IF;
PERFORM ur.id FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=p_actor AND ur.activo AND r.codigo='ADMINISTRADOR' FOR SHARE OF ur;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Se requiere administrador activo.'; END IF;
END;
$fn$;


CREATE FUNCTION public.g011_objetivo(p_actor INTEGER, p_usuario INTEGER, p_solo_admin BOOLEAN) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_serializar();
IF p_actor IS NULL OR p_actor<=0 OR p_usuario IS NULL OR p_usuario<=0 THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Actor y usuario deben ser positivos.'; END IF;

PERFORM id FROM public.usuarios WHERE id IN (p_actor,p_usuario) ORDER BY id FOR NO KEY UPDATE;
IF p_solo_admin OR p_actor<>p_usuario THEN PERFORM public.g011_admin(p_actor);
ELSE
 IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_actor AND activo) OR NOT EXISTS(SELECT 1 FROM public.usuario_roles WHERE usuario_id=p_actor AND activo) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Cuenta sin acceso activo.'; END IF;
END IF;
IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_usuario) THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Usuario no disponible.'; END IF;
END;
$fn$;


CREATE FUNCTION public.g011_resumen(p_usuario INTEGER) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE v public.usuario_resumen_011;
BEGIN
SELECT u.id,u.nombre,u.apellido,u.email,u.activo,u.creado_en,u.actualizado_en,
 ARRAY(SELECT r.codigo::TEXT FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=u.id AND ur.activo ORDER BY CASE r.codigo WHEN 'ADMINISTRADOR' THEN 1 WHEN 'DOCENTE' THEN 2 ELSE 3 END),
 (SELECT r.codigo::TEXT FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=u.id AND ur.activo ORDER BY CASE r.codigo WHEN 'ADMINISTRADOR' THEN 1 WHEN 'DOCENTE' THEN 2 ELSE 3 END LIMIT 1)
 INTO v FROM public.usuarios u WHERE u.id=p_usuario;
RETURN v;
END;
$fn$;


CREATE FUNCTION public.g011_datos(p_nombre TEXT, p_apellido TEXT, p_email TEXT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_nombre IS NULL OR btrim(p_nombre)='' OR length(btrim(p_nombre))>50 OR p_apellido IS NULL OR btrim(p_apellido)='' OR length(btrim(p_apellido))>50 OR p_email IS NULL OR length(btrim(p_email))>254 OR btrim(p_email)!~'^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Nombre, apellido o email invalidos.'; END IF;
END;
$fn$;


CREATE FUNCTION public.g011_hash(p_hash TEXT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_hash IS NULL OR p_hash !~ '^\$2[aby]\$(0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}$' THEN
 RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Se requiere un hash bcrypt valido generado en backend.'; END IF;
END;
$fn$;


CREATE FUNCTION public.g011_otro_admin(p_usuario INTEGER) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
RETURN EXISTS(SELECT 1 FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo JOIN public.roles r ON r.id=ur.rol_id AND r.codigo='ADMINISTRADOR' WHERE u.activo AND u.id<>p_usuario);
END;
$fn$;


CREATE FUNCTION public.g011_proteger_usuario() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF OLD.activo AND (TG_OP='DELETE' OR NOT NEW.activo) AND EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=OLD.id AND ur.activo AND r.codigo='ADMINISTRADOR') AND NOT public.g011_otro_admin(OLD.id) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Debe conservarse al menos un administrador activo.'; END IF;
IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END;
$fn$;


CREATE FUNCTION public.g011_proteger_rol() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE code TEXT;
BEGIN
IF TG_OP='UPDATE' AND (NEW.usuario_id IS DISTINCT FROM OLD.usuario_id OR NEW.rol_id IS DISTINCT FROM OLD.rol_id) THEN
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='No trasladar una asignacion de rol: desactivar y asignar.'; END IF;
IF TG_OP IN ('UPDATE','DELETE') THEN
 IF OLD.activo AND (TG_OP='DELETE' OR NOT NEW.activo) AND EXISTS(SELECT 1 FROM public.roles WHERE id=OLD.rol_id AND codigo='ADMINISTRADOR') AND EXISTS(SELECT 1 FROM public.usuarios WHERE id=OLD.usuario_id AND activo) AND NOT public.g011_otro_admin(OLD.usuario_id) THEN
  RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Debe conservarse al menos un administrador activo.'; END IF;
END IF;
IF TG_OP='DELETE' THEN RETURN OLD; END IF;
IF NEW.activo THEN
 SELECT codigo INTO code FROM public.roles WHERE id=NEW.rol_id;
 IF code IN ('ESTUDIANTE','DOCENTE') AND EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=NEW.usuario_id AND ur.activo AND r.codigo=CASE code WHEN 'ESTUDIANTE' THEN 'DOCENTE' ELSE 'ESTUDIANTE' END) THEN
  RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='ESTUDIANTE y DOCENTE no pueden estar activos simultaneamente.'; END IF;
END IF;
RETURN NEW;
END;
$fn$;


CREATE FUNCTION public.registrar_estudiante(p_nombre TEXT, p_apellido TEXT, p_email TEXT, p_hash TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE uid INTEGER; roleid INTEGER;
BEGIN
PERFORM public.g011_serializar();PERFORM public.g011_datos(p_nombre,p_apellido,p_email);PERFORM public.g011_hash(p_hash);
SELECT id INTO roleid FROM public.roles WHERE codigo='ESTUDIANTE';
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Falta catalogo ESTUDIANTE.'; END IF;
INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES(btrim(p_nombre),btrim(p_apellido),lower(btrim(p_email)),p_hash) RETURNING id INTO uid;
INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) VALUES(uid,roleid,uid);
RETURN public.g011_resumen(uid);
END;
$fn$;


CREATE FUNCTION public.crear_usuario_admin(p_actor INTEGER, p_nombre TEXT, p_apellido TEXT, p_email TEXT, p_hash TEXT, p_rol TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE uid INTEGER; roleid INTEGER;
BEGIN
PERFORM public.g011_serializar();PERFORM public.g011_admin(p_actor);PERFORM public.g011_datos(p_nombre,p_apellido,p_email);PERFORM public.g011_hash(p_hash);
IF p_rol IS NULL OR p_rol NOT IN ('ESTUDIANTE','DOCENTE','ADMINISTRADOR') THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Rol invalido.'; END IF;
SELECT id INTO roleid FROM public.roles WHERE codigo=p_rol;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Falta catalogo del rol.'; END IF;
INSERT INTO public.usuarios(nombre,apellido,email,password_hash) VALUES(btrim(p_nombre),btrim(p_apellido),lower(btrim(p_email)),p_hash) RETURNING id INTO uid;
INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) VALUES(uid,roleid,p_actor);
RETURN public.g011_resumen(uid);
END;
$fn$;


CREATE FUNCTION public.listar_usuarios_admin(p_actor INTEGER, p_activo BOOLEAN DEFAULT NULL, p_rol TEXT DEFAULT NULL, p_busqueda TEXT DEFAULT NULL, p_limite INTEGER DEFAULT 50, p_desplazamiento INTEGER DEFAULT 0) RETURNS SETOF public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_admin(p_actor);
IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 OR p_desplazamiento IS NULL OR p_desplazamiento<0 OR (p_rol IS NOT NULL AND p_rol NOT IN ('ESTUDIANTE','DOCENTE','ADMINISTRADOR')) OR length(p_busqueda)>254 THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Filtro o paginacion invalidos.'; END IF;
RETURN QUERY SELECT v.* FROM public.usuarios u CROSS JOIN LATERAL public.g011_resumen(u.id) v WHERE (p_activo IS NULL OR u.activo=p_activo) AND (p_busqueda IS NULL OR strpos(lower(u.nombre||' '||u.apellido||' '||u.email),lower(btrim(p_busqueda)))>0) AND (p_rol IS NULL OR EXISTS(SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=u.id AND ur.activo AND r.codigo=p_rol)) ORDER BY u.id LIMIT p_limite OFFSET p_desplazamiento;
END;
$fn$;


CREATE FUNCTION public.obtener_usuario(p_actor INTEGER, p_usuario INTEGER) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
IF p_actor IS NULL OR p_actor<=0 OR p_usuario IS NULL OR p_usuario<=0 THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='IDs invalidos.'; END IF;
IF p_actor<>p_usuario THEN PERFORM public.g011_admin(p_actor);
ELSE
 PERFORM id FROM public.usuarios WHERE id=p_actor AND activo FOR SHARE;
 IF NOT FOUND OR NOT EXISTS(SELECT 1 FROM public.usuario_roles WHERE usuario_id=p_actor AND activo) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Cuenta sin acceso activo.'; END IF;
END IF;
IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_usuario) THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='Usuario no disponible.'; END IF;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.actualizar_usuario_admin(p_actor INTEGER, p_usuario INTEGER, p_nombre TEXT, p_apellido TEXT, p_email TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,TRUE);PERFORM public.g011_datos(p_nombre,p_apellido,p_email);
UPDATE public.usuarios SET nombre=btrim(p_nombre),apellido=btrim(p_apellido),email=lower(btrim(p_email)),actualizado_en=clock_timestamp() WHERE id=p_usuario;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.actualizar_mi_perfil(p_actor INTEGER, p_nombre TEXT, p_apellido TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE mail TEXT;
BEGIN
PERFORM public.g011_objetivo(p_actor,p_actor,FALSE);
SELECT email INTO mail FROM public.usuarios WHERE id=p_actor;
PERFORM public.g011_datos(p_nombre,p_apellido,mail);
UPDATE public.usuarios SET nombre=btrim(p_nombre),apellido=btrim(p_apellido),actualizado_en=clock_timestamp() WHERE id=p_actor;
RETURN public.g011_resumen(p_actor);
END;
$fn$;


CREATE FUNCTION public.cambiar_estado_usuario_admin(p_actor INTEGER, p_usuario INTEGER, p_activo BOOLEAN) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,TRUE);
IF p_activo IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Activo es obligatorio.'; END IF;
UPDATE public.usuarios SET activo=p_activo,actualizado_en=clock_timestamp() WHERE id=p_usuario AND activo IS DISTINCT FROM p_activo;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.asignar_rol_usuario(p_actor INTEGER, p_usuario INTEGER, p_rol TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE rid INTEGER;
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,TRUE);
IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_usuario AND activo) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Reactivar la cuenta antes de asignar roles.'; END IF;
IF p_rol IS NULL OR p_rol NOT IN ('ESTUDIANTE','DOCENTE','ADMINISTRADOR') THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Rol invalido.'; END IF;
SELECT id INTO rid FROM public.roles WHERE codigo=p_rol;
IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Rol no configurado.'; END IF;

INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) VALUES(p_usuario,rid,p_actor)
ON CONFLICT(usuario_id,rol_id) DO UPDATE SET activo=TRUE,asignado_por=p_actor,asignado_en=clock_timestamp(),desactivado_en=NULL WHERE NOT public.usuario_roles.activo;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.desactivar_rol_usuario(p_actor INTEGER, p_usuario INTEGER, p_rol TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
DECLARE rid INTEGER;
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,TRUE);
IF p_rol IS NULL OR p_rol NOT IN ('ESTUDIANTE','DOCENTE','ADMINISTRADOR') THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Rol invalido.'; END IF;
SELECT ur.id INTO rid FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id WHERE ur.usuario_id=p_usuario AND r.codigo=p_rol AND ur.activo;
IF NOT FOUND THEN RETURN public.g011_resumen(p_usuario); END IF;
IF p_rol='ESTUDIANTE' AND EXISTS(SELECT 1 FROM public.intentos it JOIN public.inscripciones i ON i.id=it.inscripcion_id WHERE i.estudiante_id=p_usuario AND it.estado='EN_CURSO') THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Entregar o cerrar intentos abiertos antes de desactivar ESTUDIANTE.'; END IF;
UPDATE public.usuario_roles SET activo=FALSE,desactivado_en=clock_timestamp() WHERE id=rid;
IF p_rol='DOCENTE' THEN
 UPDATE public.curso_editores SET activo=FALSE WHERE usuario_id=p_usuario AND activo;
 UPDATE public.seccion_docentes SET activo=FALSE WHERE usuario_id=p_usuario AND activo;
END IF;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.cambiar_rol_academico(p_actor INTEGER, p_usuario INTEGER, p_rol TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,TRUE);
IF p_rol IS NULL OR p_rol NOT IN ('ESTUDIANTE','DOCENTE') THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Rol academico debe ser ESTUDIANTE o DOCENTE.'; END IF;
IF NOT EXISTS(SELECT 1 FROM public.usuarios WHERE id=p_usuario AND activo) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Cuenta inactiva.'; END IF;
PERFORM public.desactivar_rol_usuario(p_actor,p_usuario,CASE p_rol WHEN 'ESTUDIANTE' THEN 'DOCENTE' ELSE 'ESTUDIANTE' END);
PERFORM public.asignar_rol_usuario(p_actor,p_usuario,p_rol);
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE FUNCTION public.actualizar_hash_usuario(p_actor INTEGER, p_usuario INTEGER, p_hash TEXT) RETURNS public.usuario_resumen_011
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp
AS $fn$
BEGIN
PERFORM public.g011_objetivo(p_actor,p_usuario,FALSE);PERFORM public.g011_hash(p_hash);
UPDATE public.usuarios SET password_hash=p_hash,actualizado_en=clock_timestamp() WHERE id=p_usuario;
RETURN public.g011_resumen(p_usuario);
END;
$fn$;


CREATE TRIGGER trg_g011_serializar_usuarios BEFORE INSERT OR UPDATE OR DELETE ON public.usuarios FOR EACH STATEMENT EXECUTE FUNCTION public.g011_serializar_sentencia();
CREATE TRIGGER trg_g011_serializar_roles BEFORE INSERT OR UPDATE OR DELETE ON public.usuario_roles FOR EACH STATEMENT EXECUTE FUNCTION public.g011_serializar_sentencia();
CREATE TRIGGER trg_g011_proteger_usuario BEFORE UPDATE OF activo OR DELETE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.g011_proteger_usuario();
CREATE TRIGGER trg_g011_proteger_rol BEFORE INSERT OR UPDATE OR DELETE ON public.usuario_roles FOR EACH ROW EXECUTE FUNCTION public.g011_proteger_rol();
GRANT SELECT ON public.usuarios,public.usuario_roles,public.roles,public.intentos,public.inscripciones,public.curso_editores,public.seccion_docentes TO plataforma_operaciones;
GRANT INSERT(nombre,apellido,email,password_hash) ON public.usuarios TO plataforma_operaciones;
GRANT UPDATE(nombre,apellido,email,password_hash,activo,actualizado_en) ON public.usuarios TO plataforma_operaciones;
GRANT INSERT(usuario_id,rol_id,asignado_por) ON public.usuario_roles TO plataforma_operaciones;
GRANT UPDATE(activo,asignado_por,asignado_en,desactivado_en) ON public.usuario_roles TO plataforma_operaciones;
GRANT UPDATE(activo) ON public.curso_editores,public.seccion_docentes TO plataforma_operaciones;
GRANT USAGE ON SEQUENCE public.usuarios_id_seq,public.usuario_roles_id_seq TO plataforma_operaciones;
GRANT USAGE ON TYPE public.usuario_resumen_011 TO plataforma_backend,plataforma_operaciones;
REVOKE UPDATE,DELETE ON public.usuarios,public.usuario_roles FROM plataforma_backend,PUBLIC;


ALTER FUNCTION public.g011_serializar() OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_serializar() FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_serializar_sentencia() OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_serializar_sentencia() FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_admin(INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_admin(INTEGER) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_objetivo(INTEGER,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_objetivo(INTEGER,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_resumen(INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_resumen(INTEGER) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_datos(TEXT,TEXT,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_datos(TEXT,TEXT,TEXT) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_hash(TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_hash(TEXT) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_otro_admin(INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_otro_admin(INTEGER) FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_proteger_usuario() OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_proteger_usuario() FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.g011_proteger_rol() OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.g011_proteger_rol() FROM PUBLIC,plataforma_backend;

ALTER FUNCTION public.registrar_estudiante(TEXT,TEXT,TEXT,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.registrar_estudiante(TEXT,TEXT,TEXT,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.registrar_estudiante(TEXT,TEXT,TEXT,TEXT) TO plataforma_backend;

ALTER FUNCTION public.crear_usuario_admin(INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.crear_usuario_admin(INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.crear_usuario_admin(INTEGER,TEXT,TEXT,TEXT,TEXT,TEXT) TO plataforma_backend;

ALTER FUNCTION public.listar_usuarios_admin(INTEGER,BOOLEAN,TEXT,TEXT,INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.listar_usuarios_admin(INTEGER,BOOLEAN,TEXT,TEXT,INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.listar_usuarios_admin(INTEGER,BOOLEAN,TEXT,TEXT,INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.obtener_usuario(INTEGER,INTEGER) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.obtener_usuario(INTEGER,INTEGER) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.obtener_usuario(INTEGER,INTEGER) TO plataforma_backend;

ALTER FUNCTION public.actualizar_usuario_admin(INTEGER,INTEGER,TEXT,TEXT,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_usuario_admin(INTEGER,INTEGER,TEXT,TEXT,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_usuario_admin(INTEGER,INTEGER,TEXT,TEXT,TEXT) TO plataforma_backend;

ALTER FUNCTION public.actualizar_mi_perfil(INTEGER,TEXT,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_mi_perfil(INTEGER,TEXT,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_mi_perfil(INTEGER,TEXT,TEXT) TO plataforma_backend;

ALTER FUNCTION public.cambiar_estado_usuario_admin(INTEGER,INTEGER,BOOLEAN) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_estado_usuario_admin(INTEGER,INTEGER,BOOLEAN) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.cambiar_estado_usuario_admin(INTEGER,INTEGER,BOOLEAN) TO plataforma_backend;

ALTER FUNCTION public.asignar_rol_usuario(INTEGER,INTEGER,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.asignar_rol_usuario(INTEGER,INTEGER,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.asignar_rol_usuario(INTEGER,INTEGER,TEXT) TO plataforma_backend;

ALTER FUNCTION public.desactivar_rol_usuario(INTEGER,INTEGER,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.desactivar_rol_usuario(INTEGER,INTEGER,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.desactivar_rol_usuario(INTEGER,INTEGER,TEXT) TO plataforma_backend;

ALTER FUNCTION public.cambiar_rol_academico(INTEGER,INTEGER,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.cambiar_rol_academico(INTEGER,INTEGER,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.cambiar_rol_academico(INTEGER,INTEGER,TEXT) TO plataforma_backend;

ALTER FUNCTION public.actualizar_hash_usuario(INTEGER,INTEGER,TEXT) OWNER TO plataforma_operaciones;
REVOKE ALL ON FUNCTION public.actualizar_hash_usuario(INTEGER,INTEGER,TEXT) FROM PUBLIC,plataforma_backend;

GRANT EXECUTE ON FUNCTION public.actualizar_hash_usuario(INTEGER,INTEGER,TEXT) TO plataforma_backend;

COMMIT;
