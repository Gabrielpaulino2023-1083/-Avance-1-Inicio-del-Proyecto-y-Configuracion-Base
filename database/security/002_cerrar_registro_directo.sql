\set ON_ERROR_STOP on
\encoding UTF8
\if :{?registro_backend_migrado}
\else
 \set registro_backend_migrado 'false'
\endif

BEGIN;
SELECT set_config('g011.registro_backend_migrado',:'registro_backend_migrado',true);
DO $$BEGIN
 IF current_setting('g011.registro_backend_migrado')<>'true' THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='Migrar primero userModel.create a registrar_estudiante y confirmar registro_backend_migrado=true.'; END IF;
 IF to_regprocedure('public.registrar_estudiante(text,text,text,text)') IS NULL THEN RAISE EXCEPTION 'Aplicar 011 antes.'; END IF;
END;$$;
REVOKE INSERT ON public.usuarios,public.usuario_roles FROM plataforma_backend,PUBLIC;
REVOKE INSERT(nombre,apellido,email,password_hash) ON public.usuarios FROM plataforma_backend,PUBLIC;
REVOKE INSERT(usuario_id,rol_id,asignado_por) ON public.usuario_roles FROM plataforma_backend,PUBLIC;
DO $$BEGIN
 IF has_any_column_privilege('plataforma_backend','public.usuarios','INSERT') OR has_any_column_privilege('plataforma_backend','public.usuario_roles','INSERT') THEN RAISE EXCEPTION 'Quedan INSERT heredados o manuales; revisar sus origenes. No se amplio el rol.';END IF;
END;$$;
COMMIT;
