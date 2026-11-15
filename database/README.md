# Base de datos — Plataforma educativa

Estado documental: **13 de noviembre de 2026, BD-008-v1**.
Este paquete cierra el SQL del Avance 3: lectura del estudiante, seed de integración
y consultas para selector, dashboard y motor. Las migraciones 001–006 están en main.
La 007, el seed y la 008 se verificaron localmente. El paquete está listo para revisión y publicación mediante PR.

## Referencias para el equipo

| Documento | Uso |
|---|---|
| [Lectura del estudiante](docs/LECTURA_ESTUDIANTES_007.md) | Módulos, temas, actividades y cuestionarios |
| [Consultas de integración](docs/CONSULTAS_INTEGRACION_008.md) | Selector, resultados, progreso, minutos y motor |
| [Seed SQL](docs/SEED_INTEGRACION_RESULTADOS.md) | Datos y pasos para reproducir el escenario SQL JOIN |
| [Evidencia HTTP](test/RESULTADO_VALIDACION_SEED_INTEGRACION.md) | Validación local del seed y solicitud desde navegador |
| [Contrato de integración](docs/CONTRATO_INTEGRACION_BD.md) | Reglas, funciones, permisos, límites e instrucciones para agentes |
| [Diccionario de datos](docs/DICCIONARIO_DATOS_BD.md) | Tipos exactos, nulabilidad, defaults, restricciones y propuestas de serialización |
| [CRUD de módulos y temas](docs/CRUD_MODULOS_TEMAS_AVANCE_3.md) | Funciones de 006, permisos por curso y seed docente |
| [Evidencia de 006](test/RESULTADO_VALIDACION_006.md) | Regresiones, prueba del seed y límites |
| [CRUD de cursos](docs/CRUD_CURSOS_AVANCE_3.md) | Firmas SQL, estados, errores y ejemplos para Express |
| [Evidencia de 005](test/RESULTADO_VALIDACION_005.md) | Validación automatizada y verificaciones locales reportadas |

Las migraciones son la fuente del esquema. El contrato explica el comportamiento.
El diccionario SQL no sustituye los DTOs ni la especificación OpenAPI del backend.

## Qué existe

Tras aplicar 001–006 y seguridad: **17 tablas, 1 vista, 31 funciones propias y 9 triggers**,
sin contar extensiones ni objetos auxiliares de pruebas. Hay 22 funciones operativas,
seis funciones de trigger y tres auxiliares privadas.

- Usuarios, roles múltiples y asignaciones.
- Cursos, ediciones, secciones, docentes, editores e inscripciones.
- Módulos y temas.
- Actividades, preguntas de selección única/múltiple y opciones.
- Intentos, respuestas, entrega, calificación exacta y promedio de calificados.
- Inscripción autónoma/administrativa mediante función y control de cupos.
- Cursos: crear, listar, consultar, editar, activar y archivar mediante funciones.

008 deriva el progreso de las actividades publicadas/calificadas; no lo almacena en otra tabla.
No hay aún navegación, historial de recomendaciones ni cierre programado de intentos.
La vista de resultados por actividad no equivale a una nota final del curso.

## Estado y evidencia

| Elemento | Estado |
|---|---|
| Migraciones 001–004 | Publicadas en main; PR #7 integró 004 el 9 de noviembre |
| Migración 005, seed admin y documentación | Publicados en main mediante PR #9 |
| Migración 006 y seed docente | Publicados en main; instalación, login y CRUD HTTP docente comprobados localmente |
| 007 y seed SQL | Pruebas locales aprobadas |
| Recomendación SQL JOIN | HTTP 200 desde el navegador; métricas de tarjeta pendientes de corrección |
| 008 | Pruebas SQL aprobadas en PGlite y PostgreSQL local; integración HTTP pendiente |
| Instalación 001–005 y regresiones 003–005 | Ejecutadas sin errores inesperados en PostgreSQL embebido PGlite |
| 005 y pruebas en PostgreSQL local | Ejecución correcta confirmada por el responsable |
| Seed administrativo | Ejecución correcta confirmada por el responsable |
| Login y /api/auth/me de estudiante y administrador | Respuestas success=true con sus roles, compartidas por el responsable |
| Cuenta de conexión Express | Cambio reportado a plataforma_backend; verificar current_user desde el pool para evidencia directa |
| Endpoints HTTP y pantallas de cursos | Pendientes de integración y prueba conjunta |
| Instalación local desde cero de todo 001–005 | Prueba completada correctamente |

Validación local confirmada: la migración 006, sus pruebas y el seed docente se ejecutaron correctamente en PostgreSQL local. El login y /api/auth/me de docente.demo@example.com devolvieron el resultado esperado con rol DOCENTE. El CRUD docente por HTTP se verificó con un curso autorizado; sigue pendiente el recorrido completo desde frontend con el selector real.

## Instalación

Requisitos: PostgreSQL en ejecución, psql y una cuenta administrativa para instalar.
Registrar `SELECT version();`. No se declara una versión mínima probada en múltiples versiones.
Ejecutar desde la raíz del repositorio y usar archivos UTF-8.

En una base nueva, conectarse como administrador y ejecutar en este orden:

```sql
\set ON_ERROR_STOP on
\encoding UTF8
SET search_path = public;
\i 'database/migrations/001_estructura_academica_inicial.sql'
\i 'database/migrations/002_modulos_temas.sql'
\i 'database/migrations/003_actividades_intentos_respuestas.sql'
\i 'database/security/001_roles_permisos.sql'
\i 'database/migrations/004_inscripcion_estudiantes.sql'
\i 'database/migrations/005_crud_cursos.sql'
\i 'database/migrations/006_crud_modulos_temas.sql'
\i 'database/migrations/007_lectura_contenido_estudiantes.sql'
\i 'database/migrations/008_consultas_integracion.sql'
```

004–008 requieren los roles del script de seguridad. No ejecutar todos los archivos de
migrations antes de seguridad. Las migraciones estructurales se aplican una sola vez por base.
No existe aún un ejecutor ni tabla de versiones: registrar los archivos aplicados por entorno.

En la base de desarrollo ya validada hasta 007, aplicar solo 008:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/008_consultas_integracion.sql
```

No reinstalar migraciones que ya terminaron correctamente. Si un archivo falla, detenerse;
en una sesión interactiva con transacción abortada ejecutar ROLLBACK. Los archivos
anteriores confirmados siguen aplicados. No borrar la base habitual para validar:
crear una base independiente si se necesita repetir la instalación completa.

## Datos de prueba

| Archivo | Dependencia y propósito |
|---|---|
| seeds/datos_prueba.sql | Roles, usuarios ficticios, curso CALC-PRUEBA, ediciones, secciones e inscripción |
| seeds/datos_prueba_modulos_temas.sql | Depende del anterior; dos módulos y cuatro temas |
| seeds/datos_prueba_actividades_intentos.sql | Requiere administrador activo y rol ESTUDIANTE; crea demo autenticable y resultados |
| seeds/datos_prueba_docente.sql | Después de 006; requiere administrador y rol DOCENTE, crea curso DEMO-006 y editor |
| seeds/datos_prueba_integracion_resultados.sql | Después de 007, usa el estudiante demo existente y agrega DEMO-SQL-007; reejecución sin duplicados |
| seeds/datos_prueba_administrador.sql | Requiere administrador activo y rol ADMINISTRADOR; crea demo administrativa |

Ejecutar los seeds como administrador; solo el seed SQL ampliado es reejecutable sin cambios. No forman parte de las migraciones ni
deben ejecutarse automáticamente al iniciar Express. Los IDs se consultan; no se fijan.
Las cuentas iniciales con HASH_FICTICIO_NO_USAR no sirven para login.

Para generar hashes, desde backend con dependencias instaladas:

```powershell
node -e "console.log(require('bcryptjs').hashSync('DemoEquipo-2026!', 10))"
node -e "console.log(require('bcryptjs').hashSync('AdminDemo-2026!', 10))"
node -e "console.log(require('bcryptjs').hashSync('DocenteDemo-2026!', 10))"
```

Desde la raíz, solo para el seed todavía no cargado:

```powershell
chcp 65001
$env:PGCLIENTENCODING = 'UTF8'
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_actividades_intentos.sql
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_administrador.sql
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_docente.sql
```

Pegar el hash correspondiente cuando lo solicite cada archivo. No pegar todo el script
interactivamente: el prompt puede consumir líneas. No confundir el hash con la contraseña de postgres.

- Estudiante: estudiante.demo@example.com / DemoEquipo-2026!
- Administrador: administrador.demo@example.com / AdminDemo-2026!
- Docente: docente.demo@example.com / DocenteDemo-2026!

Estas contraseñas son públicas, exclusivas de desarrollo, y solo corresponden si se usaron
al generar los hashes. Los seeds no sobrescriben cuentas existentes ni son scripts de reinicio.
No crean una cuenta docente con login. No usar datos reales ni estos seeds en producción.

La demo académica crea DEMO-003, tres actividades con dos preguntas cada una: práctica con
promedio 50, evaluación con nota 100 y práctica sin intentos. Nuevos intentos cambian los
resultados. La disponibilidad dura un año desde la carga y los intentos 30 minutos.
Las actividades sin intentos no aparecen en resultados_actividades: usar LEFT JOIN para listados completos.

## Conexión de Express

Usar plataforma_backend, nunca postgres como conexión habitual. Definir la contraseña del rol
con `\password plataforma_backend` desde psql administrativo y configurar localmente
DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD y JWT_SECRET según los archivos de backend.
Reiniciar el proceso al cambiar .env. No compartir .env, tokens ni contraseñas de infraestructura.
Los roles SQL pertenecen al servidor; cada compañero debe configurar y aplicar el esquema en su entorno.

La cuenta administradora de la aplicación es un usuario de usuarios con rol ADMINISTRADOR.
No es una cuenta PostgreSQL ni un superusuario. Express pasa el actor tomado del JWT verificado;
la función comprueba cuenta y asignación activas. El frontend no puede elegir ese actor.

El registro público permanece ESTUDIANTE. Los roles existentes admiten múltiples asignaciones,
pero su política de alternancia estudiante/docente aún debe cerrarse. No conceder permisos
amplios ni usar postgres para resolver una operación faltante.

## Pruebas

Como postgres, sin una transacción abierta:

```sql
\set ON_ERROR_STOP on
\i 'database/test/pruebas_migracion_003.sql'
\i 'database/test/pruebas_migracion_004.sql'
\i 'database/test/pruebas_migracion_005.sql'
\i 'database/test/pruebas_migracion_006.sql'
```

003 y 004 deben ejecutarse con los fixtures/seeds que esperan sus archivos. 005 y 006 crean sus
propios fixtures y no depende de seeds. Las pruebas consolidadas revierten los cambios al
terminar; las secuencias pueden avanzar. Se conservan también pruebas_restricciones.sql,
pruebas_temas_modulos.sql y pruebas_permisos.sql; revisar sus instrucciones y errores esperados.
No confundir errores esperados de pruebas manuales con un fallo inesperado de la regresión.

006 debe imprimir `PRUEBAS 006 COMPLETADAS: todos los casos incluidos pasaron.` y ROLLBACK.
Si falla, conservar el error y corregir la causa antes de continuar. No deshabilitar triggers.

## Cierre e integración

- Publicar este paquete mediante PR; la prueba local de 008 ya pasó.
- Backend: conectar lecturas 007, operaciones de intentos de 003 y consultas de 008.
- Frontend: usar las métricas reales de recomendación, el selector de curso y los contratos HTTP.
- Fuera del avance: historial de recomendaciones, navegación, cierre de intentos abandonados y concurrencia.

## Cambios y mantenimiento

No reescribir migraciones ya adoptadas; usar cambios incrementales. Mantener SECURITY DEFINER,
propietario y search_path al modificar funciones. Preservar las restricciones y el historial.
Los textos dañados por codificación se repararon localmente: ese procedimiento excepcional
no forma parte del despliegue. Cambiar client_encoding no repara texto previamente dañado.

El merge no ejecuta SQL. Cada integrante aplica solo lo pendiente y prueba su entorno.

## Entrega 006 — alcance inmediato

La guía [CRUD_MODULOS_TEMAS_AVANCE_3.md](docs/CRUD_MODULOS_TEMAS_AVANCE_3.md) detalla las doce
funciones nuevas, SQLSTATE, tipos de retorno y ejemplos. El administrador opera sobre todos los
cursos y el docente solo con curso_editores activo. Borrado físico solo en borrador sin hijos;
23505 en orden repetido y 55000 en dependencias. Las escrituras en curso archivado se rechazan.

El frontend debe enviar el curso seleccionado, no fijar ID 1. El backend adapta total_temas
(BIGINT) a totalTemas y mantiene el actor del JWT. No se crearon endpoints ni pantallas.
Las pruebas SQL, el seed y el CRUD HTTP docente se verificaron. El recorrido desde frontend
con el curso seleccionado sigue pendiente. No repetir el seed docente ya cargado.

