\set ON_ERROR_STOP on
\encoding UTF8
\prompt 'Hash bcrypt del docente demo: ' docente_hash

-- Solo desarrollo. Ejecutar como postgres después de 006 y del seed inicial.
-- Crea un curso independiente. No reasigna ni modifica DEMO-003.
BEGIN;
SET LOCAL search_path=pg_catalog, public, pg_temp;
CREATE TEMP TABLE parametros_docente_demo(hash TEXT NOT NULL) ON COMMIT DROP;
INSERT INTO parametros_docente_demo VALUES(:'docente_hash');
\unset docente_hash
DO $$
DECLARE v_hash TEXT; v_admin INTEGER; v_rol INTEGER; v_docente INTEGER; v_curso INTEGER; v_modulo INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(3006,2026);
    SELECT hash INTO STRICT v_hash FROM parametros_docente_demo;
    IF v_hash !~ '^\$2[aby]\$10\$[./A-Za-z0-9]{53}$' THEN
        RAISE EXCEPTION 'Se requiere un hash bcrypt costo 10 generado con bcryptjs.';
    END IF;
    IF EXISTS(SELECT 1 FROM public.usuarios WHERE lower(email)='docente.demo@example.com')
       OR EXISTS(SELECT 1 FROM public.cursos WHERE codigo='DEMO-006') THEN
        RAISE EXCEPTION 'Ya existe la cuenta docente o el curso DEMO-006; no se sobrescriben.';
    END IF;
    SELECT u.id INTO v_admin FROM public.usuarios u
    JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
    JOIN public.roles r ON r.id=ur.rol_id
    WHERE u.activo AND r.codigo='ADMINISTRADOR'
    ORDER BY (u.email='administrador.demo@example.com') DESC,u.id LIMIT 1;
    IF v_admin IS NULL THEN RAISE EXCEPTION 'Falta un administrador activo; ejecutar el seed inicial.'; END IF;
    SELECT id INTO STRICT v_rol FROM public.roles WHERE codigo='DOCENTE';
    INSERT INTO public.usuarios(nombre,apellido,email,password_hash)
    VALUES('Docente','Demo Equipo','docente.demo@example.com',v_hash) RETURNING id INTO v_docente;
    INSERT INTO public.usuario_roles(usuario_id,rol_id,asignado_por) VALUES(v_docente,v_rol,v_admin);
    SELECT id INTO v_curso FROM public.crear_curso_admin(v_admin,'DEMO-006','Curso de gestion docente','Curso exclusivo para probar modulos, temas y autorizacion.');
    PERFORM public.cambiar_estado_curso_admin(v_admin,v_curso,'ACTIVO');
    INSERT INTO public.curso_editores(curso_id,usuario_id,asignado_por) VALUES(v_curso,v_docente,v_admin);
    SELECT id INTO v_modulo FROM public.crear_modulo(v_docente,v_curso,'Modulo de prueba','Contenido editable del curso demo.',1);
    PERFORM public.crear_tema(v_docente,v_modulo,'Tema de prueba','Tema sin actividades para probar el CRUD.',1);
    RAISE NOTICE 'Docente demo %, curso %, modulo % creados.',v_docente,v_curso,v_modulo;
END;
$$;
COMMIT;
SELECT u.id AS docente_id,u.email,r.codigo AS rol,c.id AS curso_id,c.codigo AS curso
FROM public.usuarios u JOIN public.usuario_roles ur ON ur.usuario_id=u.id AND ur.activo
JOIN public.roles r ON r.id=ur.rol_id
JOIN public.curso_editores ce ON ce.usuario_id=u.id AND ce.activo
JOIN public.cursos c ON c.id=ce.curso_id
WHERE u.email='docente.demo@example.com' AND c.codigo='DEMO-006';
