\set ON_ERROR_STOP on
-- Ejecutar como postgres después de 005. No depende de seeds.
-- Los fixtures y cambios se revierten. Las secuencias pueden avanzar.
BEGIN;
SET LOCAL search_path = pg_catalog, public, pg_temp;
CREATE TEMP TABLE contexto_005 (admin_id INTEGER, estudiante_id INTEGER, inactivo_id INTEGER, curso_id INTEGER);
INSERT INTO public.roles(codigo, nombre) VALUES ('ADMINISTRADOR', 'Administrador'), ('ESTUDIANTE', 'Estudiante')
ON CONFLICT (codigo) DO NOTHING;
DO $$
DECLARE a INTEGER; e INTEGER; d INTEGER;
BEGIN
    INSERT INTO public.usuarios(nombre, apellido, email, password_hash)
    VALUES ('Admin', 'Prueba 005', 'admin-005-' || txid_current() || '@example.com', 'HASH_FICTICIO_NO_USAR') RETURNING id INTO a;
    INSERT INTO public.usuarios(nombre, apellido, email, password_hash)
    VALUES ('Estudiante', 'Prueba 005', 'est-005-' || txid_current() || '@example.com', 'HASH_FICTICIO_NO_USAR') RETURNING id INTO e;
    INSERT INTO public.usuarios(nombre, apellido, email, password_hash, activo)
    VALUES ('Admin', 'Inactivo', 'inactivo-005-' || txid_current() || '@example.com', 'HASH_FICTICIO_NO_USAR', FALSE) RETURNING id INTO d;
    INSERT INTO public.usuario_roles(usuario_id, rol_id, asignado_por)
    SELECT a, id, a FROM public.roles WHERE codigo = 'ADMINISTRADOR';
    INSERT INTO public.usuario_roles(usuario_id, rol_id, asignado_por)
    SELECT d, id, a FROM public.roles WHERE codigo = 'ADMINISTRADOR';
    INSERT INTO public.usuario_roles(usuario_id, rol_id, asignado_por)
    SELECT e, id, a FROM public.roles WHERE codigo = 'ESTUDIANTE';
    INSERT INTO contexto_005 VALUES(a, e, d, NULL);
END;
$$;
GRANT SELECT, UPDATE ON contexto_005 TO plataforma_backend;
SET LOCAL ROLE plataforma_backend;

DO $$
DECLARE c RECORD; x public.cursos; y public.cursos; n BIGINT; code TEXT := 'TEST-005-' || txid_current();
BEGIN
    SELECT * INTO c FROM contexto_005;
    IF has_any_column_privilege(current_user, 'public.cursos', 'INSERT')
       OR has_any_column_privilege(current_user, 'public.cursos', 'UPDATE')
       OR has_table_privilege(current_user, 'public.cursos', 'DELETE') THEN
        RAISE EXCEPTION 'FALLO: escrituras directas concedidas al backend.';
    END IF;
    BEGIN
        DELETE FROM public.cursos WHERE FALSE;
        RAISE EXCEPTION 'FALLO: DELETE directo permitido.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM public.validar_administrador_cursos(c.admin_id);
        RAISE EXCEPTION 'FALLO: funcion auxiliar expuesta.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    RAISE NOTICE 'OK 1: permisos restringidos y funcion auxiliar privada.';
    BEGIN
        PERFORM public.crear_curso_admin(c.estudiante_id, code, 'Curso', 'Descripcion');
        RAISE EXCEPTION 'FALLO: estudiante autorizado.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM public.crear_curso_admin(c.inactivo_id, code, 'Curso', 'Descripcion');
        RAISE EXCEPTION 'FALLO: cuenta inactiva autorizada.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM public.crear_curso_admin(NULL, code, 'Curso', 'Descripcion');
        RAISE EXCEPTION 'FALLO: actor NULL autorizado.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    x := public.crear_curso_admin(c.admin_id, ' ' || code || ' ', ' Curso 005 ', ' Descripcion ');
    IF x.estado <> 'BORRADOR' OR x.codigo <> code OR x.creado_por <> c.admin_id THEN
        RAISE EXCEPTION 'FALLO: datos de creacion incorrectos.';
    END IF;
    UPDATE contexto_005 SET curso_id = x.id;
    RAISE NOTICE 'OK 2: autorizacion y creacion en BORRADOR.';
    BEGIN
        PERFORM public.crear_curso_admin(c.admin_id, code, 'Duplicado', 'Descripcion');
        RAISE EXCEPTION 'FALLO: codigo duplicado permitido.';
    EXCEPTION WHEN unique_violation THEN NULL; END;
    BEGIN
        PERFORM public.crear_curso_admin(c.admin_id, 'OTRO', '  ', 'Descripcion');
        RAISE EXCEPTION 'FALLO: nombre vacio permitido.';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    BEGIN
        PERFORM public.crear_curso_admin(c.admin_id, 'OTRO', 'Curso', NULL);
        RAISE EXCEPTION 'FALLO: descripcion NULL permitida.';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    y := public.obtener_curso_admin(c.admin_id, x.id);
    IF y.id <> x.id THEN RAISE EXCEPTION 'FALLO: lectura incorrecta.'; END IF;
    SELECT COUNT(*) INTO n FROM public.listar_cursos_admin(c.admin_id, 'BORRADOR', 100, 0) WHERE id = x.id;
    IF n <> 1 THEN RAISE EXCEPTION 'FALLO: listado no incluye curso nuevo.'; END IF;
    BEGIN
        PERFORM public.listar_cursos_admin(c.admin_id, NULL, 101, 0);
        RAISE EXCEPTION 'FALLO: limite invalido permitido.';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    BEGIN
        PERFORM public.obtener_curso_admin(c.estudiante_id, x.id);
        RAISE EXCEPTION 'FALLO: lectura administrativa permitida a estudiante.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM public.obtener_curso_admin(c.admin_id, NULL);
        RAISE EXCEPTION 'FALLO: curso inexistente no rechazado.';
    EXCEPTION WHEN no_data_found THEN NULL; END;
    RAISE NOTICE 'OK 3: restricciones, consultas y paginacion.';
    y := public.actualizar_curso_admin(c.admin_id, x.id, code, 'Editado', 'Descripcion editada');
    IF y.nombre <> 'Editado' OR y.creado_por <> x.creado_por OR y.creado_en <> x.creado_en
       OR y.actualizado_en < x.actualizado_en THEN RAISE EXCEPTION 'FALLO: actualizacion incorrecta.'; END IF;
    BEGIN
        PERFORM public.actualizar_curso_admin(c.estudiante_id, x.id, code, 'No autorizado', 'Descripcion');
        RAISE EXCEPTION 'FALLO: edicion no autorizada.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    y := public.cambiar_estado_curso_admin(c.admin_id, x.id, 'ACTIVO');
    IF y.estado <> 'ACTIVO' THEN RAISE EXCEPTION 'FALLO: activacion.'; END IF;
    x := public.cambiar_estado_curso_admin(c.admin_id, x.id, 'ACTIVO');
    IF x.actualizado_en <> y.actualizado_en THEN RAISE EXCEPTION 'FALLO: repeticion altera fecha.'; END IF;
    BEGIN
        PERFORM public.cambiar_estado_curso_admin(c.admin_id, x.id, 'BORRADOR');
        RAISE EXCEPTION 'FALLO: destino invalido permitido.';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    RAISE NOTICE 'OK 4: edicion, activacion y repeticion.';
END;
$$;

RESET ROLE;
INSERT INTO public.ediciones_curso(curso_id, codigo, nombre, fecha_inicio, fecha_fin, creado_por)
SELECT curso_id, 'ED-005', 'Edicion de prueba', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 year', admin_id
FROM contexto_005;
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE c RECORD;
BEGIN
    SELECT * INTO c FROM contexto_005;
    BEGIN
        PERFORM public.cambiar_estado_curso_admin(c.admin_id, c.curso_id, 'ARCHIVADO');
        RAISE EXCEPTION 'FALLO: archivado con edicion pendiente permitido.';
    EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
    RAISE NOTICE 'OK 5: archivado con edicion PLANIFICADA rechazado.';
END;
$$;
RESET ROLE;
UPDATE public.ediciones_curso SET estado = 'CANCELADA' WHERE curso_id = (SELECT curso_id FROM contexto_005);
SET LOCAL ROLE plataforma_backend;
DO $$
DECLARE c RECORD; x public.cursos;
BEGIN
    SELECT * INTO c FROM contexto_005;
    x := public.cambiar_estado_curso_admin(c.admin_id, c.curso_id, 'ARCHIVADO');
    IF x.estado <> 'ARCHIVADO' THEN RAISE EXCEPTION 'FALLO: archivado.'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.ediciones_curso WHERE curso_id = x.id) THEN
        RAISE EXCEPTION 'FALLO: historial eliminado.';
    END IF;
    BEGIN
        PERFORM public.actualizar_curso_admin(c.admin_id, x.id, x.codigo, 'Cambio', 'Descripcion');
        RAISE EXCEPTION 'FALLO: archivado editable.';
    EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
    BEGIN
        PERFORM public.cambiar_estado_curso_admin(c.admin_id, x.id, 'ACTIVO');
        RAISE EXCEPTION 'FALLO: reactivacion permitida.';
    EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
    RAISE NOTICE 'OK 6: baja logica, historial conservado y bloqueos posteriores.';
END;
$$;
RESET ROLE;
UPDATE public.usuario_roles SET activo = FALSE, desactivado_en = clock_timestamp()
WHERE usuario_id = (SELECT admin_id FROM contexto_005);
SET LOCAL ROLE plataforma_backend;
DO $$
BEGIN
    BEGIN
        PERFORM public.listar_cursos_admin((SELECT admin_id FROM contexto_005));
        RAISE EXCEPTION 'FALLO: asignacion administrativa inactiva autorizada.';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    RAISE NOTICE 'OK 7: rol desactivado rechazado.';
    RAISE NOTICE 'PRUEBAS 005 COMPLETADAS: todos los casos incluidos pasaron.';
END;
$$;
ROLLBACK;
