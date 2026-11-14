# Validación de lectura de estudiantes — 007

Fecha: 13 de noviembre de 2026.

## Fuente revisada

- Repositorio: Gabrielpaulino2023-1083/-Avance-1-Inicio-del-Proyecto-y-Configuracion-Base.
- main: `80815b2e47b4b397ad990967b66fce5a52b7a71a` (migraciones hasta 006).
- Backend: `16984a5305d5fd5ab0a1847a974492c04b29da8a`.
- Migración y pruebas 007 preparadas como archivos nuevos, sin publicar ni modificar el remoto.

## Entorno y resultados de esta revisión

Motor embebido PostgreSQL 18.6, PGlite 0.5.16. Es ejecución de SQL/PLpgSQL,
no simulación de las respuestas. No es el servidor PostgreSQL de Windows del equipo.
Para ejecutarlo en este entorno se omitieron únicamente las directivas de psql
(`\\set`, `\\encoding`); las sentencias SQL de los archivos se ejecutaron sin cambios.

| Comprobación | Resultado |
|---|---|
| Instalación limpia de 001–003, security/001, 004–007 | Correcta |
| pruebas_migracion_007.sql | 72 comprobaciones aprobadas |
| Segunda ejecución del mismo archivo 007 | Aprobada |
| Ausencia de usuarios residuales tras ROLLBACK | Verificada |
| Regresión pruebas_migracion_003.sql | Aprobada, con sus seeds previos |
| Regresión pruebas_migracion_004.sql | Aprobada |
| Regresión pruebas_migracion_005.sql | Aprobada |
| Regresión pruebas_migracion_006.sql | Aprobada |

Para 003 se cargaron `datos_prueba.sql` y `datos_prueba_modulos_temas.sql`,
requeridos por esa prueba. 007 no necesita seeds. No se cargó ni modificó ningún
usuario demo real del equipo ni su contraseña.

## Resultado local

El responsable ejecutó 007 en PostgreSQL local y confirmó sus 72 comprobaciones. El seed SQL
también validó la lectura como plataforma_backend. Queda integrar las cuatro lecturas en las
rutas y pantallas; la prueba SQL no sustituye una prueba HTTP ni de concurrencia.

