# Base de datos — Plataforma educativa

Estado documental: **10 de noviembre de 2026, BD-005-v1**.
PostgreSQL almacena identidad, organización académica, inscripciones, actividades y resultados.
El bloque nuevo de este PR es el CRUD administrativo de cursos con baja lógica y una cuenta
administradora de pruebas. Backend, frontend y motor continúan su integración por separado.

## Referencias para el equipo

| Documento | Uso |
|---|---|
| [Contrato de integración](docs/CONTRATO_INTEGRACION_BD.md) | Reglas, funciones, permisos, límites e instrucciones para agentes |
| [Diccionario de datos](docs/DICCIONARIO_DATOS_BD.md) | Tipos exactos, nulabilidad, defaults, restricciones y propuestas de serialización |
| [CRUD de cursos](docs/CRUD_CURSOS_AVANCE_3.md) | Firmas SQL, estados, errores y ejemplos para Express |
| [Evidencia de 005](test/RESULTADO_VALIDACION_005.md) | Validación automatizada y verificaciones locales reportadas |

Las migraciones son la fuente del esquema. El contrato explica el comportamiento.
El diccionario SQL no sustituye los DTOs ni la especificación OpenAPI del backend.

## Qué existe

Tras aplicar 001–005 y seguridad: **17 tablas, 1 vista, 17 funciones propias y 9 triggers**,
sin contar extensiones ni objetos auxiliares de pruebas. Hay diez funciones operativas,
seis funciones de trigger y una auxiliar administrativa privada.

- Usuarios, roles múltiples y asignaciones.
- Cursos, ediciones, secciones, docentes, editores e inscripciones.
- Módulos y temas.
- Actividades, preguntas de selección única/múltiple y opciones.
- Intentos, respuestas, entrega, calificación exacta y promedio de calificados.
- Inscripción autónoma/administrativa mediante función y control de cupos.
- Cursos: crear, listar, consultar, editar, activar y archivar mediante funciones.

No existe aún progreso/finalización, tabla de contenidos, navegación, historial de
recomendaciones ni cierre programado de intentos. No confundir la vista de resultados
con una nota final del curso o con progreso. Estos elementos quedan fuera del PR de 005.

## Estado y evidencia

| Elemento | Estado |
|---|---|
| Migraciones 001–004 | Publicadas en main; PR #7 integró 004 el 9 de noviembre |
| Migración 005, seed admin y documentación | Preparados para revisión/PR |
| Instalación 001–005 y regresiones 003–005 | Ejecutadas sin errores inesperados en PostgreSQL embebido PGlite |
| 005 y pruebas en PostgreSQL local | Ejecución correcta confirmada por el responsable |
| Seed administrativo | Ejecución correcta confirmada por el responsable |
| Login y /api/auth/me de estudiante y administrador | Respuestas success=true con sus roles, compartidas por el responsable |
| Cuenta de conexión Express | Cambio reportado a plataforma_backend; verificar current_user desde el pool para evidencia directa |
| Endpoints HTTP y pantallas de cursos | Pendientes de integración y prueba conjunta |
| Instalación local desde cero de todo 001–005 | Pendiente de evidencia conjunta; no se deduce de instalar 005 sobre una base existente |

La evidencia local es reportada por Jeison. Las pruebas SQL no demuestran rutas HTTP,
concurrencia entre conexiones ni integración con el motor.

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
```

004 y 005 requieren los roles del script de seguridad. No ejecutar todos los archivos de
migrations antes de seguridad. Las migraciones estructurales se aplican una sola vez por base.
No existe aún un ejecutor ni tabla de versiones: registrar los archivos aplicados por entorno.

En una base con 001–004 y seguridad, ejecutar solo:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/005_crud_cursos.sql
```

No reinstalar la 005 que ya terminó correctamente. Si un archivo falla, detenerse;
en una sesión interactiva con transacción abortada ejecutar ROLLBACK. Los archivos
anteriores confirmados siguen aplicados. No borrar la base habitual para validar:
crear una base independiente si se necesita repetir la instalación completa.

## Datos de prueba

| Archivo | Dependencia y propósito |
|---|---|
| seeds/datos_prueba.sql | Roles, usuarios ficticios, curso CALC-PRUEBA, ediciones, secciones e inscripción |
| seeds/datos_prueba_modulos_temas.sql | Depende del anterior; dos módulos y cuatro temas |
| seeds/datos_prueba_actividades_intentos.sql | Requiere administrador activo y rol ESTUDIANTE; crea demo autenticable y resultados |
| seeds/datos_prueba_administrador.sql | Requiere administrador activo y rol ADMINISTRADOR; crea demo administrativa |

Ejecutar los seeds como administrador una sola vez. No forman parte de las migraciones ni
deben ejecutarse automáticamente al iniciar Express. Los IDs se consultan; no se fijan.
Las cuentas iniciales con HASH_FICTICIO_NO_USAR no sirven para login.

Para generar hashes, desde backend con dependencias instaladas:

```powershell
node -e "console.log(require('bcryptjs').hashSync('DemoEquipo-2026!', 10))"
node -e "console.log(require('bcryptjs').hashSync('AdminDemo-2026!', 10))"
```

Desde la raíz, solo para el seed todavía no cargado:

```powershell
chcp 65001
$env:PGCLIENTENCODING = 'UTF8'
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_actividades_intentos.sql
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_administrador.sql
```

Pegar el hash correspondiente cuando lo solicite cada archivo. No pegar todo el script
interactivamente: el prompt puede consumir líneas. No confundir el hash con la contraseña de postgres.

- Estudiante: estudiante.demo@example.com / DemoEquipo-2026!
- Administrador: administrador.demo@example.com / AdminDemo-2026!

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
```

003 y 004 deben ejecutarse con los fixtures/seeds que esperan sus archivos. 005 crea sus
propios fixtures y no depende de seeds. Las pruebas consolidadas revierten los cambios al
terminar; las secuencias pueden avanzar. Se conservan también pruebas_restricciones.sql,
pruebas_temas_modulos.sql y pruebas_permisos.sql; revisar sus instrucciones y errores esperados.
No confundir errores esperados de pruebas manuales con un fallo inesperado de la regresión.

005 debe imprimir `PRUEBAS 005 COMPLETADAS: todos los casos incluidos pasaron.` y ROLLBACK.
Si falla, conservar el error y corregir la causa antes de continuar. No deshabilitar triggers.

## Pendientes inmediatos y posteriores

Para el PR: revisión de diff, publicación de los archivos y revisión por el equipo.
Para el flujo de cursos: endpoints, formularios, prueba de rechazo al estudiante y capturas.
Para la asignación semanal de BD: cerrar métricas/consultas del motor y consolidar evidencia.

Después del avance: administración de otras entidades, progreso/finalización, operaciones
sobre inscripciones, cierre de intentos abandonados y pruebas de concurrencia. El contrato
mantiene las reglas y decisiones pendientes. No añadir tablas especulativas para desbloquear la API.

## Cambios y mantenimiento

No reescribir migraciones ya adoptadas; usar cambios incrementales. Mantener SECURITY DEFINER,
propietario y search_path al modificar funciones. Preservar las restricciones y el historial.
Los textos dañados por codificación se repararon localmente: ese procedimiento excepcional
no forma parte del despliegue. Cambiar client_encoding no repara texto previamente dañado.

El merge no ejecuta SQL. Cada integrante aplica solo lo pendiente y prueba su entorno.
