\set ON_ERROR_STOP on
\encoding UTF8
-- Solo despues del cierre opcional; no aplica permisos por si misma.
BEGIN;
SET LOCAL ROLE plataforma_backend;
DO $$DECLARE u public.usuario_resumen_011;code TEXT;BEGIN
 IF has_any_column_privilege(current_user,'public.usuarios','INSERT') OR has_any_column_privilege(current_user,'public.usuario_roles','INSERT') THEN RAISE EXCEPTION 'El registro directo sigue habilitado; no se ejecuta esta prueba.'; END IF;
 u:=registrar_estudiante('Registro','Controlado','cierre011-'||txid_current()||'@example.com','$2b$10$'||repeat('A',53));
 IF u.rol_principal<>'ESTUDIANTE' OR to_jsonb(u)?'password_hash' THEN RAISE EXCEPTION 'Respuesta de registro no esperada.'; END IF;
 BEGIN INSERT INTO usuarios(nombre,apellido,email,password_hash) VALUES('No','Directo','no-directo@example.com','X');EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS code=RETURNED_SQLSTATE;END;
 IF code IS DISTINCT FROM '42501' THEN RAISE EXCEPTION 'INSERT directo no fue rechazado como se esperaba.'; END IF;
 RAISE NOTICE 'PRUEBAS CIERRE 011 COMPLETADAS: registro controlado sin INSERT directo.';
END;$$;
ROLLBACK;
