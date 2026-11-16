# Validación 006

Fecha: 11 de noviembre de 2026. Entorno: PostgreSQL 18.6 embebido, PGlite 0.5.16.
Instalación 001–006 y seguridad desde cero. 001–004/seguridad coinciden con main; para 005
se utilizó el archivo actual de main (su única diferencia con el paquete anterior es un comentario).
Se ejecutaron las regresiones 003, 004, 005 y 006. Para los archivos psql se retiraron únicamente
metacomandos y se sustituyó el parámetro del seed por un hash bcryptjs costo 10 generado durante la prueba.

Resultados:

- Rol limitado sin escrituras directas sobre módulos/temas ni acceso a auxiliares.
- Administrador y docente editor pueden crear y consultar; estudiante rechazado en las 12 operaciones.
- Docente rechazado en otro curso y al desactivar cuenta, rol o asignación de editor.
- Valores inválidos rechazados; orden duplicado 23505; mismo orden en distinto padre permitido.
- Edición/estados conservan autoría; estado repetido conserva fecha; sin cascada de estados.
- Módulo con tema y tema con actividad rechazados con 55000; publicado no se elimina.
- Borrado de borradores sin dependencias correcto; total_temas se actualiza al consultar.
- Cursos archivados no admiten escritura; sí consulta autorizada.
- Seed docente: hash verificable, único rol DOCENTE, editor de DEMO-006 y lectura con plataforma_backend.
- Reejecución del seed rechazada sin sobrescribir. Aislamiento REPEATABLE READ rechazado con 25000.
- Conteo final: 31 funciones propias. No se cambiaron tablas ni triggers.

```text
PASS avance3/database/migrations/001_estructura_academica_inicial.sql
PASS avance3/database/migrations/002_modulos_temas.sql
PASS avance3/database/migrations/003_actividades_intentos_respuestas.sql
PASS avance3/database/security/001_roles_permisos.sql
PASS avance3/database/migrations/004_inscripcion_estudiantes.sql
PASS /tmp/avance6-test/005_main.sql
PASS avance6/database/migrations/006_crud_modulos_temas.sql
PASS avance3/database/seeds/datos_prueba.sql
PASS avance3/database/seeds/datos_prueba_modulos_temas.sql
PASS avance3/database/test/pruebas_migracion_003.sql
PASS avance3/database/test/pruebas_migracion_004.sql
PASS avance3/database/test/pruebas_migracion_005.sql
PASS avance6/database/test/pruebas_migracion_006.sql
PASS seed docente: bcrypt, unico rol DOCENTE, editor activo y lectura mediante plataforma_backend
PASS seed duplicate rejected
PASS REPEATABLE READ rejected with 25000
[ { funciones: 31 } ]
[
  {
    version: 'PostgreSQL 18.6 (PGlite 0.5.16) on wasm32-unknown-emscripten, compiled by emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 6.0.13 (e13ee988ce3d87a738dd8f3661d02223308c412a), 32-bit'
  }
]
```
