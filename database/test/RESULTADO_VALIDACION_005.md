# Validación del paquete 005

Fecha: 2026-11-10.

Entorno: PostgreSQL embebido mediante PGlite. Se aplicaron los SQL originales de
main 001–004 y seguridad, seguidos de la nueva 005. Se eliminaron solo las órdenes
psql (`\set`, `\encoding`, `\prompt`) para ejecutarlos en este entorno.
Para el seed se sustituyó el parámetro psql por un hash bcryptjs costo 10 generado
durante la prueba. No se alteraron funciones ni permisos para hacer pasar los casos.

Resultado: instalación y pruebas sin excepciones inesperadas. Comparación bcrypt
correcta y rechazo de repetición del seed confirmado. Conteo: 17 funciones públicas.

```text
PASS migrations/001_estructura_academica_inicial.sql
PASS migrations/002_modulos_temas.sql
PASS migrations/003_actividades_intentos_respuestas.sql
PASS security/001_roles_permisos.sql
PASS migrations/004_inscripcion_estudiantes.sql
PASS migrations/005_crud_cursos.sql
PASS seeds/datos_prueba.sql
PASS seeds/datos_prueba_modulos_temas.sql
PASS test/pruebas_migracion_003.sql
PASS test/pruebas_migracion_004.sql
PASS test/pruebas_migracion_005.sql
PASS seed admin: unique role and bcrypt verification
PASS seed duplicate rejected
[ { funciones: 17 } ]
```

No demuestra autenticación TCP, ejecución del prompt de psql, concurrencia entre
conexiones, integración Express ni flujo visual. La ejecución local de 005 y sus pruebas fue confirmada posteriormente por el responsable, como se registra debajo. Falta guardar las evidencias HTTP del CRUD con el responsable del backend.

## Verificaciones locales reportadas por Jeison — 10 de noviembre

| Comprobación | Evidencia disponible | Resultado |
|---|---|---|
| Migración 005 y pruebas | Confirmación del responsable en conversación | Correctas |
| Seed administrador | Confirmación de salida esperada | Correcto |
| POST /api/auth/login administrador | Respuesta JSON compartida: success=true, rol ADMINISTRADOR | Correcto |
| GET /api/auth/me administrador | Respuesta JSON compartida con la misma cuenta | Correcto |
| POST /api/auth/login estudiante | Respuesta JSON compartida: success=true, rol ESTUDIANTE | Correcto |
| GET /api/auth/me estudiante | Respuesta JSON compartida con la misma cuenta | Correcto |

El responsable cambió DB_USER de postgres a plataforma_backend antes de repetir las pruebas.
Se indicó reiniciar el proceso; no se adjuntó una consulta current_user ejecutada por el pool.
No se incluyen tokens, contraseñas de infraestructura ni hashes. No fijar los IDs de las capturas.

Estas verificaciones demuestran autenticación. No prueban todavía endpoints de cursos,
concurrencia, navegación React ni integración del motor. La ejecución local completa de
001–005 desde cero no se deduce de aplicar 005 a una base existente.
