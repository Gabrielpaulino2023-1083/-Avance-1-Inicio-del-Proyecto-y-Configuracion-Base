# Backend

## Descripción

El Backend recibe las peticiones del Frontend, aplica la lógica del sistema y maneja los datos. Es una API REST desarrollada con Node.js y Express.js, siguiendo la arquitectura MVC, con PostgreSQL como base de datos.

Ubicación: `backend/`

## Estado actual

El backend tiene un servidor Express con autenticación conectada a PostgreSQL (registro, login con JWT, `/me` y control de acceso por roles), un CRUD de cursos para administradores, un CRUD de módulos y temas para administradores y docentes editores, y el aprendizaje del estudiante con datos reales: sus cursos, el contenido publicado, los intentos de actividades (iniciar, guardar, entregar y calificar en el servidor), resultados, progreso, actividad reciente, minutos por día y la recomendación del motor adaptativo (Python) por inscripción y tema. La API está documentada con OpenAPI y Swagger UI.

Los endpoints del Dashboard antiguo (`/api/students/:id` y `/progress`) también usan ya datos reales (`"simulado": false`); ver "Endpoints de estudiantes". Ya no queda ningún dato simulado en el backend.

## Tecnologías

- Node.js v24.11.1 y npm 11.6.2
- Express.js
- PostgreSQL 18, con la librería `pg`
- JWT (`jsonwebtoken`) y `bcryptjs`
- Zod para la validación de DTOs
- `dotenv`, `cors`, `helmet` y `express-rate-limit`
- OpenAPI 3 y Swagger UI (`swagger-ui-express`, `js-yaml`)
- Python y Pandas (motor adaptativo, invocado con `child_process`)

## Estructura

```
backend/
├── .env.example
├── .gitignore
├── README.md
├── package.json
└── src/
    ├── app.js
    ├── server.js
    ├── config/
    ├── controllers/
    ├── docs/
    ├── dtos/
    ├── errors/
    ├── middlewares/
    ├── models/
    ├── routes/
    └── services/
```

- `app.js`: arma la aplicación (seguridad, CORS, rutas, Swagger y errores). No abre el puerto.
- `server.js`: comprueba que los roles existan en la base y enciende el servidor.
- `config/`: `config.js`, `db.js`, `roles.js`, `permissions.js`, `checkRoles.js` y `swagger.js`.
- `controllers/`: reciben la petición y responden. Sin lógica de negocio.
- `dtos/`: validación de entrada (Zod) y forma de la salida.
- `errors/`: clase `AppError`, error con código HTTP.
- `middlewares/`: `authMiddleware.js` (token, roles y permisos), `studentAccess.js`, `validate.js`, `rateLimiters.js` y `errorHandler.js`.
- `models/`: consultas SQL y llamadas a funciones de PostgreSQL.
- `routes/`: definición de los endpoints.
- `services/`: lógica de negocio y `engineClient.js` (conexión con Python).
- `docs/`: `openapi.yaml`.

Flujo de una petición: ruta → middlewares (token, permisos, validación) → controller → service → model → PostgreSQL. Los errores se lanzan con `AppError` y se responden en `errorHandler.js`.

## Endpoints disponibles

| Método | Ruta | Descripción | Protegida |
|---|---|---|---|
| GET | `/api/health` | Comprueba que el backend funciona | No |
| POST | `/api/auth/register` | Registra un estudiante | No |
| POST | `/api/auth/login` | Inicia sesión y devuelve un token JWT | No |
| GET | `/api/auth/me` | Datos del usuario autenticado | Sí |
| GET | `/api/students/:id` | Resumen del estudiante | Sí |
| GET | `/api/students/:id/progress` | Progreso del estudiante | Sí |
| POST | `/api/students/:id/recommendation` | Recomendación del motor adaptativo | Sí |
| POST | `/api/cursos` | Crea un curso | Admin |
| GET | `/api/cursos` | Lista cursos | Admin |
| GET | `/api/cursos/:id` | Consulta un curso | Admin |
| PUT | `/api/cursos/:id` | Edita un curso | Admin |
| PATCH | `/api/cursos/:id/estado` | Activa o archiva un curso | Admin |
| GET | `/api/modulos` | Lista módulos de un curso | Admin / docente editor |
| POST | `/api/modulos` | Crea un módulo | Admin / docente editor |
| PUT | `/api/modulos/:id` | Edita un módulo | Admin / docente editor |
| PATCH | `/api/modulos/:id/estado` | Cambia el estado de un módulo | Admin / docente editor |
| DELETE | `/api/modulos/:id` | Elimina un módulo | Admin / docente editor |
| GET | `/api/modulos/:id/temas` | Lista temas de un módulo | Admin / docente editor |
| POST | `/api/modulos/:id/temas` | Crea un tema | Admin / docente editor |
| PUT | `/api/temas/:id` | Edita un tema | Admin / docente editor |
| PATCH | `/api/temas/:id/estado` | Cambia el estado de un tema | Admin / docente editor |
| DELETE | `/api/temas/:id` | Elimina un tema | Admin / docente editor |
| GET | `/api/cursos-administrables` | Cursos que el usuario puede gestionar (selector) | Admin / docente editor |
| GET | `/api/mis-cursos` | Inscripciones activas del estudiante | Estudiante |
| GET | `/api/mis-cursos/:cursoId/modulos` | Módulos publicados del curso | Estudiante |
| GET | `/api/mis-modulos/:moduloId/temas` | Temas publicados del módulo | Estudiante |
| GET | `/api/mis-inscripciones/:inscripcionId/temas/:temaId/actividades` | Actividades publicadas del tema | Estudiante |
| POST | `/api/mis-inscripciones/:inscripcionId/actividades/:actividadId/intentos` | Inicia un intento y devuelve el cuestionario | Estudiante |
| GET | `/api/mis-intentos/:intentoId/cuestionario` | Retoma un intento en curso | Estudiante |
| PUT | `/api/mis-respuestas/:respuestaId/opciones` | Guarda la selección de una pregunta | Estudiante |
| POST | `/api/mis-intentos/:intentoId/entrega` | Entrega el intento y lo califica | Estudiante |
| GET | `/api/mis-inscripciones/:inscripcionId/resultados` | Resultados por actividad | Estudiante |
| GET | `/api/mis-inscripciones/:inscripcionId/progreso` | Progreso por tema | Estudiante |
| GET | `/api/mis-inscripciones/:inscripcionId/actividad-reciente` | Últimos intentos | Estudiante |
| GET | `/api/mis-inscripciones/:inscripcionId/minutos` | Minutos por día | Estudiante |
| POST | `/api/mis-inscripciones/:inscripcionId/temas/:temaId/recomendacion` | Recomendación del motor por inscripción y tema | Estudiante |

### Contrato del login

Entrada: `{ "email": "ana@example.com", "password": "Clave1234" }`

Salida (200):

```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "user": { "id": 4, "nombre": "Ana", "apellido": "Lopez", "email": "ana@example.com", "rol": "ESTUDIANTE" }
}
```

### Formato de errores

Todas las respuestas incluyen `success`. Los errores traen `message`, y los de validación (400) traen además `details`:

```json
{
  "success": false,
  "message": "Datos inválidos",
  "details": [{ "campo": "password", "mensaje": "La contraseña debe tener al menos 8 caracteres" }]
}
```

Códigos: `400` datos inválidos, `401` credenciales o token inválidos, `403` sin permiso, `404` recurso inexistente, `409` conflicto, `413` cuerpo demasiado grande, `429` demasiados intentos, `500` error interno, `502` fallo del motor adaptativo (Python).

Las rutas protegidas requieren `Authorization: Bearer <token>`. El token dura 2 horas.

### `/api/auth/me`

Devuelve los datos actuales del usuario dueño del token, consultados en la base. Sirve para recuperar la sesión al recargar la página y detectar usuarios desactivados.

## Endpoints de estudiantes

Alimentan el Dashboard. El `:id` es el `user.id` que devuelve el login.

Reglas de acceso: un estudiante solo puede consultar su propio `:id`; un administrador, cualquiera; un docente, solo los estudiantes inscritos en secciones que tiene asignadas (`seccion_docentes`).

**`GET /api/students/:id`** (resumen). La respuesta incluye `datosReales` con los campos que ya salen de la base.

- **Reales:** nombre, apellido, email, rol, cursos activos y su lista, actividades pendientes, nota promedio y horas de estudio.
  - `actividadesPendientes`: actividades publicadas y vigentes de sus secciones sin intento entregado o calificado.
  - `notaPromedio`: promedio de evaluaciones calificadas (vista `resultados_actividades`). Es `null` si aún no hay ninguna.
  - `horasEstudio`: suma del tiempo entre inicio y entrega de sus intentos. Solo mide el tiempo dentro de las actividades.
  - `porcentajeCompletado`: promedio del progreso por tema (solo temas con actividades) en todas sus inscripciones activas; 0 si no hay temas con actividades.
  - `modulosFinalizados` y `modulosPendientes`: un módulo está finalizado cuando todos sus temas publicados están completados (tema completado = todas sus actividades con al menos un intento calificado).
  - La respuesta lleva `"simulado": false`.

**`GET /api/students/:id/progress`:** variaciones y recomendación, con datos reales (`"simulado": false`).

- Variaciones: últimos 7 días (hoy incluido) contra los 7 anteriores, en America/Santo_Domingo. `actividadesSemana` es la diferencia de intentos entregados; `horasSemana`, la de horas entre inicio y entrega; `notaPuntos`, la del promedio de puntaje de los intentos calificados; `cursosMes`, las inscripciones nuevas de los últimos 30 días.
- `porcentajeSemanal` es siempre `null`: la base solo guarda el progreso actual, no su historia. Para calcularlo habría que guardar capturas diarias.
- Las variaciones sin datos para comparar son `null` (no 0); el frontend debe mostrar un guion. Para `notaPuntos`, `actividadesSemana` y `horasSemana` se consideran los últimos 100 eventos de actividad reciente por inscripción.
- `recomendacion`: el motor la calcula sobre el tema más débil (menor promedio con intentos calificados) y devuelve `inscripcionId`, `temaId`, `tema`, `accion`, `dificultad`, `prioridad`, `descripcion` y `motivo`. `prioridad` no viene del motor: se deriva de la acción (`reinforce_topic` alta, `maintain_difficulty` media, `increase_difficulty` baja). Es `null` si no hay intentos calificados o si el motor falla (el error queda en la consola y el resto del progreso se entrega igual).

**`POST /api/students/:id/recommendation`:** recibe `{ "topic": "nombre del tema" }`. Se mantiene por compatibilidad con el frontend actual; la ruta recomendada es la de inscripción y tema (ver "Aprendizaje del estudiante").

- Arma una interacción por cada intento calificado del estudiante en ese tema (por nombre) y la envía al motor adaptativo.
- Cada interacción: `score_percentage` (puntaje obtenido sobre máximo), `errors` (respuestas con puntaje 0), `attempts` (número de intento), `study_minutes` (entrega menos inicio), `repetitions` (`attempts - 1`) y `navigation_count` (0, porque no existe en la base).
- Responde `tema`, `accion`, `dificultad`, `recomendacion` y la evidencia `mastery` (promedio de puntaje), `errors` (total) y `attempts` (promedio).
- Si el estudiante no tiene intentos calificados en ese tema, responde `404`.

## Aprendizaje del estudiante (rol ESTUDIANTE)

Usa las funciones de lectura de la migración 007 (`listar_modulos_publicados_estudiante`, `listar_temas_publicados_estudiante`, `listar_actividades_publicadas_estudiante`, `obtener_cuestionario_estudiante`), las consultas de integración de la 008 (`listar_inscripciones_estudiante`, `listar_resultados_estudiante`, `listar_progreso_estudiante`, `listar_actividad_reciente_estudiante`, `listar_minutos_intentos_estudiante`, `listar_interacciones_motor_estudiante`) y las funciones de intentos de la 003 (`iniciar_intento`, `guardar_opciones_respuesta`, `entregar_intento`, `calificar_intento`). Respuesta: `{ "success": true, "data": ... }`.

Reglas comunes:

- El estudiante sale siempre del token, nunca de la URL ni del cuerpo. La base valida que la inscripción, el intento o la respuesta le pertenezcan; si no, responde `403`.
- Solo se muestra contenido `PUBLICADO` de cursos activos con inscripción activa del estudiante.
- Los valores `NULL` se conservan como `null`: una nota sin calificar nunca se convierte en 0.
- `pg` devuelve `BIGINT` y `NUMERIC` como texto; los DTOs los convierten a número.

**Flujo de un intento**

1. `GET /api/mis-cursos` devuelve las inscripciones; de ahí sale el `inscripcionId`.
2. `GET /api/mis-cursos/:cursoId/modulos`, `GET /api/mis-modulos/:moduloId/temas` y `GET /api/mis-inscripciones/:inscripcionId/temas/:temaId/actividades` recorren el contenido publicado.
3. `POST .../actividades/:actividadId/intentos` inicia el intento y lee el cuestionario en **una sola transacción**: si el cuestionario falla, el intento se revierte. Cada pregunta trae su `respuestaId` y las opciones solo con `id`, `texto` y `orden`. Nunca se envían `es_correcta` ni explicaciones.
4. `PUT /api/mis-respuestas/:respuestaId/opciones` recibe `{ "opciones": [ids] }` (máximo 50, enteros positivos) y reemplaza la selección anterior de esa pregunta; una lista vacía la borra. `GET /api/mis-intentos/:intentoId/cuestionario` retoma el intento con lo ya guardado y no consume otra oportunidad.
5. `POST /api/mis-intentos/:intentoId/entrega` ejecuta `entregar_intento` y, si quedó `ENTREGADO`, `calificar_intento`, en una misma transacción. La calificación es siempre del servidor: no existe ruta pública de calificación y el frontend no envía puntajes. Si el intento ya venció, `motivoEntrega` es `VENCIMIENTO`; repetir la entrega devuelve el resultado ya calculado.

**Resultados, progreso y actividad**

- `resultados`: una fila por actividad visible, incluidas las pendientes. Las prácticas tienen `notaAcademicaPorcentaje: null`. Para las evaluaciones se filtra `finalidad = EVALUACION`.
- `progreso`: una actividad cuenta como realizada si tiene al menos un intento calificado, sin nota mínima. Un tema sin actividades devuelve `progresoPorcentaje: null` y `completado: false`. Publicar nuevas actividades puede cambiar el progreso.
- `actividad-reciente`: un evento por intento entregado o calificado, del más reciente al más antiguo. `limite` de 1 a 100 (10 por defecto).
- `minutos`: `desde` y `hasta` (`AAAA-MM-DD`), intervalo semiabierto de máximo 366 días, agrupado por día local (America/Santo_Domingo). Es tiempo transcurrido entre inicio y entrega, no tiempo activo de estudio. Los días sin intentos no aparecen. El dominio por tema se calcula promediando `resultados` por `temaId`, y las variaciones semanales comparando dos rangos de `minutos`.

**Recomendación por inscripción y tema:** `POST /api/mis-inscripciones/:inscripcionId/temas/:temaId/recomendacion` (sin cuerpo).

- Arma una interacción por cada intento calificado en ese tema y esa inscripción (consulta `listar_interacciones_motor_estudiante`) y la envía al motor. No mezcla temas con el mismo nombre de otros cursos o ediciones.
- Cada interacción: `score_percentage`, `errors` (respuestas con puntaje 0), `attempts` (número de intento), `repetitions` (`attempts - 1`), `navigation_count` (0, porque no existe en la base) y `study_minutes` (entrega menos inicio).
- Responde `inscripcionId`, `temaId`, `tema`, `accion`, `dificultad`, `recomendacion` y la evidencia `mastery` (promedio de puntaje), `errors` (total) y `attempts` (promedio).
- Sin intentos calificados en ese tema responde `404`; si falla el motor de Python, `502`.
- **`actividadSugerida`** (opcional, migración 009): `{ actividadId, titulo, dificultad, dificultadObjetivo, coincideNivel, esRepeticion, actividadReferenciaId }` o `null`. El backend llama a `listar_candidatas_actividad` (actor del token, inscripción y tema; la referencia es el último intento calificado del tema) y elige con `services/actividadSelector.js`, copia del selector de `database/docs/ejemplos/seleccion_actividad.cjs`. El ajuste del motor (`reduced`, `current`, `increased`) mueve el nivel objetivo (BAJA, MEDIA, ALTA) respecto de la referencia; se prefiere otra actividad antes de repetir la de referencia, luego el nivel más cercano al objetivo, con empate hacia el nivel menor y después el id menor.
- `actividadSugerida` es `null` si la referencia no tiene dificultad asignada, no hay candidatas (publicadas, disponibles, con intentos restantes y sin intento abierto) o la consulta falla; en esos casos el error queda en la consola (`[actividadSugerida]`) y el resto de la respuesta no cambia. Nunca inicia un intento: el frontend usa la ruta de iniciar intento con el `actividadId` recibido.
- Las actividades anteriores a la 009 quedan sin clasificar (`dificultad` NULL), por lo que no generan sugerencia. Para probarlo hay que aplicar `009_dificultad_candidatas.sql` y el seed `datos_prueba_dificultad_009.sql` (curso `DEMO-DIFICULTAD-009`).

Mapeo de errores de la base: `42501` → 403, `22023` → 400, `P0002` → 404, `55000` y `P0001` → 409, `23505` → 409, fechas inválidas (`22007`, `22008`) → 400. El texto interno de SQL nunca llega al cliente; los `P0001` (varias causas comparten el código: actividad no disponible, intento ya abierto, límite de intentos) se registran en la consola del servidor.

## CRUD de cursos (solo administrador)

Usa las funciones de PostgreSQL de la migración 005 (`crear_curso_admin`, `listar_cursos_admin`, `obtener_curso_admin`, `actualizar_curso_admin`, `cambiar_estado_curso_admin`). El actor sale siempre del token, nunca del body, y la base vuelve a validar que sea administrador activo. Respuesta: `{ "success": true, "data": ... }`.

- `POST /api/cursos`: crea el curso en estado `BORRADOR`. Body: `codigo`, `nombre`, `descripcion`.
- `GET /api/cursos`: filtros `estado`, `limite` (1 a 100) y `desplazamiento`.
- `PUT /api/cursos/:id`: reemplaza código, nombre y descripción (los tres son obligatorios). No se editan cursos archivados.
- `PATCH /api/cursos/:id/estado`: `ACTIVO` o `ARCHIVADO`. Transiciones: `BORRADOR` → `ACTIVO`; `BORRADOR` o `ACTIVO` → `ARCHIVADO`.

**Eliminar = archivar (baja lógica).** No hay borrado físico, para conservar el historial. Archivar se rechaza con `409` si el curso tiene ediciones planificadas, abiertas o en curso, y no hay reactivación de cursos archivados.

Mapeo de errores de la base: `42501` → 403, `22023` → 400, `P0002` → 404, `23505` → 409 (código duplicado), `55000` → 409 (estado incompatible).

## CRUD de módulos y temas

Usa las funciones de la migración 006 (`crear_modulo`, `listar_modulos_por_curso`, `obtener_modulo`, `actualizar_modulo`, `cambiar_estado_modulo`, `eliminar_modulo` y sus equivalentes de tema). Respuesta: `{ "success": true, "data": ... }`. El actor sale siempre del token.

- **Módulos:** `GET /api/modulos?cursoId=`, `POST /api/modulos`, `PUT /api/modulos/:id`, `PATCH /api/modulos/:id/estado`, `DELETE /api/modulos/:id`. Cada módulo incluye `totalTemas`.
- **Temas:** `GET /api/modulos/:id/temas`, `POST /api/modulos/:id/temas`, `PUT /api/temas/:id`, `PATCH /api/temas/:id/estado`, `DELETE /api/temas/:id`.
- Campos: `nombre`, `descripcion`, `orden` (entero mayor que 0) y `estado` (`BORRADOR`, `PUBLICADO` o `ARCHIVADO`; por defecto `BORRADOR`). El módulo incluye `cursoId` y el tema `moduloId`.
- `GET /api/cursos-administrables` devuelve los cursos que el usuario puede gestionar (`listar_cursos_administrables`): el administrador, todos; el docente, solo donde es editor activo. Incluye `puedeEditarContenido` (falso en cursos archivados). Es el selector de curso del frontend, que debe enviar siempre el `cursoId` elegido.
- `cursoId` sigue siendo opcional al crear o listar módulos y, si falta, se usa el curso 1; el frontend nuevo debe enviarlo siempre.

Reglas de negocio (las valida la base de datos):

- El administrador opera sobre todos los cursos; el docente solo si es editor activo del curso (`curso_editores`). Cualquier otro rol, incluido el estudiante, recibe `403`, también para leer.
- `orden` repetido dentro del curso (módulos) o del módulo (temas) responde `409`.
- El borrado es físico y solo en estado `BORRADOR`; se rechaza con `409` si el módulo tiene temas o el tema tiene actividades.
- No se modifica contenido de un curso archivado (`409`).

Permisos nuevos: `content:read` y `content:write`. Nota técnica: `contentRoutes` se monta en `/api` después de Swagger en `app.js`; si se montara antes, pediría token para `/api/docs`.

## Conexión con el motor adaptativo

El motor está en `adaptive-engine/` (Python y Pandas, de Daniel). El backend lo invoca desde `src/services/engineClient.js`, función `runEngine(payload)`, con `child_process.spawn`: envía el JSON por entrada estándar y lee el JSON de la salida estándar (Node → Python → JSON → Node).

- Ejecuta `adaptive-engine/main.py --stdin`.
- Python se busca en `.venv` en la raíz del repositorio, o en la variable `PYTHON_EXECUTABLE`.
- Salida usada: `student_id`, `topic`, `action`, `difficulty`, `recommendation`.
- El motor exige al menos una interacción. Si Python no está disponible o falla, el endpoint responde `502` ("El motor de recomendación no está disponible"); el detalle queda en la consola del servidor con la etiqueta `[motor adaptativo]`. Toda llamada al motor pasa por `services/engineSafe.js`, que convierte cualquier fallo en ese `502`. Los errores propios del backend siguen siendo `500`.
- Requisitos: crear el entorno con `python -m venv .venv` e instalar con `.venv\Scripts\pip install -r adaptive-engine\requirements.txt` (pandas y scikit-learn). Sin `.venv` el error es `spawn ... python.exe ENOENT`.
- En Windows hay que definir `PYTHONUTF8=1` y `PYTHONIOENCODING=utf-8` en el `.env`: sin ellas, Python devuelve su salida en cp1252 y los acentos de la recomendación llegan dañados (`�`). El `spawn` hereda las variables del backend.

## Seguridad

- Cabeceras HTTP con `helmet`.
- Login y registro limitados a 10 peticiones por IP cada 15 minutos (`429`).
- JSON limitado a 100 KB (`413`).
- Contraseñas con bcrypt; los DTOs de salida nunca exponen el hash.
- Si un usuario tiene varios roles activos, se usa el de mayor jerarquía (ADMINISTRADOR > DOCENTE > ESTUDIANTE).
- Conexión a PostgreSQL con el rol limitado `plataforma_backend`, no con `postgres`.
- El cuestionario nunca incluye `es_correcta` ni explicaciones; el backend no puede leer `opciones_respuestas.es_correcta` y la calificación se hace solo en el servidor.
- En las rutas del estudiante, el usuario sale del token y la base valida la propiedad de la inscripción, el intento y la respuesta (otro estudiante recibe `403`).
- Los errores de la base se traducen a códigos HTTP sin exponer el texto interno de SQL.

## CORS y conexión con el frontend

El backend permite el origen definido en `CORS_ORIGIN` (por defecto `http://localhost:5173`). El frontend puede llamar directo a `http://localhost:3000` o usar el proxy de Vite.

## Documentación de la API (Swagger)

Con el servidor encendido: http://localhost:3000/api/docs (JSON en `/api/docs.json`). La especificación está en `backend/src/docs/openapi.yaml`; si se cambia un DTO o endpoint, se actualiza también ese archivo. El enum de roles se toma de `roles.js`.

## Roles y permisos

- Roles (`ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR`) definidos en `src/config/roles.js`; deben coincidir con `roles.codigo` en PostgreSQL y el servidor lo verifica al arrancar.
- Permisos por rol en `src/config/permissions.js` (incluye `courses:manage`, `content:read` y `content:write`).
- Rutas protegidas con `verifyToken` y `requireRole(...)` o `requirePermission('permiso')`.
- El registro público siempre crea usuarios `ESTUDIANTE`, para evitar escalada de privilegios.
- El token guarda `id` y `rol`; si el rol cambia, el token anterior conserva el valor hasta que expire.

## Configuración

Variables en `backend/.env` (no se sube a GitHub; el ejemplo está en `.env.example`): `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET` y `CORS_ORIGIN`. `PYTHONUTF8=1` y `PYTHONIOENCODING=utf-8` (necesarias en Windows para los acentos del motor). Opcional: `PYTHON_EXECUTABLE`. `DB_USER` debe ser `plataforma_backend`. Sin `JWT_SECRET` el servidor no arranca.

## Base de datos

PostgreSQL con la base `motor_adaptativo`, elaborada por el compañero de base de datos (carpeta `database/`):

- Se aplican en orden: `001`, `002`, `003`, `security/001_roles_permisos.sql`, `004` (inscripciones), `005` (CRUD de cursos), `006` (CRUD de módulos y temas), `007` (lectura de contenido y cuestionarios del estudiante) y `008` (consultas de integración: selector docente, inscripciones, resultados, progreso, actividad reciente, minutos y motor). El seed inicial es obligatorio porque inserta los roles.
- 17 tablas y la vista `resultados_actividades`. La escritura de intentos, inscripciones, cursos, módulos y temas se hace solo mediante funciones.
- Los usuarios del seed inicial tienen hash ficticio y no inician sesión. Para probar: `POST /api/auth/register`, o las cuentas demo: administrador (`datos_prueba_administrador.sql`), estudiante (`datos_prueba_actividades_intentos.sql`) y docente (`datos_prueba_docente.sql`), que piden un hash bcrypt generado con bcryptjs.
- El seed `datos_prueba_actividades_intentos.sql` crea al estudiante demo con el curso `DEMO-003` (práctica con promedio 50, evaluación con nota 100 y una práctica sin intentos).
- El seed `datos_prueba_integracion_resultados.sql` (no pide hash; usa al estudiante demo) agrega el curso `DEMO-SQL-007`: tres temas (SQL SELECT, SQL WHERE y SQL JOIN), cuatro actividades y nueve intentos calificados repartidos en dos semanas, con promedios 91.67, 66.67 y 16.67. Sirve para probar resultados, progreso, minutos y las tres acciones del motor.
- Las migraciones 007 y 008 y los seeds con `\prompt` deben ejecutarse con `psql` (pgAdmin no entiende esos comandos). Cada migración se aplica una sola vez; las pruebas (`database/test/pruebas_migracion_007.sql`, `pruebas_migracion_008.sql` y `pruebas_seed_integracion_resultados.sql`) revierten sus cambios.
- Roles de PostgreSQL: `plataforma_backend` (conexión de Express, escritura solo por funciones) y `plataforma_operaciones` (interno).
- El registro crea el usuario y su rol en una sola transacción.

## Trabajo realizado

**Entorno y estructura**
- Se verificó el entorno, se clonó el repositorio y se creó la estructura MVC.

**Servidor y API**
- Servidor Express, scripts, `app.js`/`server.js` separados, `GET /api/health`, registro, login y `/me` con bcrypt y JWT.
- Endpoints de estudiantes (resumen, progreso y recomendación) para el Dashboard, con CORS.
- Resumen con datos reales: actividades pendientes, nota promedio y horas de estudio.
- Recomendación con interacciones armadas desde intentos calificados y conexión con el motor de Python.
- CRUD de cursos para administradores y CRUD de módulos y temas para administradores y docentes editores, sobre funciones de la base de datos.
- Selector de cursos gestionables para administrador y docente.
- Aprendizaje del estudiante: cursos, módulos, temas y actividades publicados, inicio de intento con cuestionario sin respuestas correctas, guardado de respuestas, retomar intento, entrega con calificación en el servidor, resultados, progreso, actividad reciente y minutos por día.
- Recomendación por inscripción y tema con interacciones reales y evidencia (`mastery`, `errors`, `attempts`), conectada al motor de Python.

**Calidad y seguridad**
- DTOs con Zod, errores centralizados, control de acceso por roles y permisos, docente limitado a sus secciones.
- `helmet`, límite de intentos de login, límite de tamaño del JSON y prioridad de roles.
- Conexión a PostgreSQL con el rol limitado `plataforma_backend`.

**Base de datos**
- Se instaló PostgreSQL 18 y se aplicaron las migraciones 001 a 008, la seguridad y los seeds (administrador, docente, estudiante demo y el curso SQL de integración). Las pruebas de 007, 008 y del seed terminaron correctamente.

**Documentación**
- OpenAPI 3 y Swagger UI con todos los endpoints, README y este documento.

## Evidencia con datos reales

Se probó el backend con Swagger y PostgreSQL local, conectado con el rol `plataforma_backend`:

- **Crear:** `POST /api/cursos` y `POST /api/modulos` insertan filas en `cursos` y `modulos`; `POST /api/modulos/:id/temas` inserta en `temas`. En todas, `creado_por` es el id del administrador del token (no del body).
- **Leer:** `GET /api/cursos`, `GET /api/modulos?cursoId=1` y `GET /api/modulos/:id/temas` devuelven los datos de la base, con `totalTemas` calculado.
- **Actualizar:** `PUT` y `PATCH .../estado` cambian la fila y actualizan `actualizado_en` (verificado en pgAdmin).
- **Eliminar:** `DELETE /api/temas/:id` y `DELETE /api/modulos/:id` borran la fila solo en `BORRADOR` y sin hijos; en cursos, eliminar es archivar.
- **Reglas rechazadas por la base:** orden repetido (409), borrar un módulo con temas (409), archivar un curso con ediciones abiertas (409) y usar el token de un estudiante (403).

Aprendizaje del estudiante (estudiante demo, `estudiante.demo@example.com`, contra PostgreSQL local):

- **Selector docente:** el docente demo recibe solo `DEMO-006` con `puedeEditarContenido: true`.
- **Contenido:** `GET /api/mis-cursos` devuelve las inscripciones 6 (`DEMO-003`) y 7 (`DEMO-SQL-007`); el módulo "Consultas SQL" trae `totalTemas: 3` y sus temas SQL SELECT, WHERE y JOIN. Antes el estudiante recibía 403.
- **Resultados y progreso (inscripción 7):** 91.67, 66.67 y 16.67; la evaluación de SQL JOIN sin intentos devuelve `null` en promedio y nota. Progreso de 100 %, 100 % y 50 %.
- **Actividad y minutos:** `limite=3` devuelve exactamente 3 eventos; la semana del 2 al 9 de noviembre suma 3 intentos y 36 minutos, y la del 9 al 16, 6 intentos y 72 minutos.
- **Intento completo (actividad 10):** el inicio devuelve el cuestionario sin `es_correcta`; se guardan las selecciones, se retoma el cuestionario con lo guardado y la entrega responde `CALIFICADO` con 20/20 y 100 %. Un intento vencido se entrega con `motivoEntrega: VENCIMIENTO` y 0/20.
- **Seguridad:** otra estudiante (Ana) recibe `403` al leer el cuestionario ajeno; una inscripción ajena responde `403` y una fecha inválida, `400`.
- **Recomendación (inscripción 7):** SQL JOIN → `reinforce_topic` (`mastery` 16.67, `errors` 10, `attempts` 2); SQL SELECT → `increase_difficulty` (91.67); SQL WHERE → `maintain_difficulty` (66.67). Coincide con la validación del compañero de base de datos.

## Flujos para probar

1. **Administrador (cursos):** login con `administrador.demo@example.com` → crear curso → consultar → editar → activar → archivar → repetir el código (409) → archivar `CALC-PRUEBA` (409).
2. **Administrador o docente (contenido):** crear módulo → editar → cambiar estado → crear tema → intentar eliminar el módulo con tema (409) → eliminar el tema → eliminar el módulo.
3. **Estudiante (resumen):** registro → login → `GET /api/students/:id` → `POST /api/students/:id/recommendation` (404 si no tiene intentos calificados en ese tema) → cualquier ruta de cursos o contenido (403).
4. **Estudiante (aprendizaje):** login con `estudiante.demo@example.com` → `GET /api/mis-cursos` → módulos y temas → actividades → iniciar intento → guardar opciones → retomar cuestionario → entregar (queda calificado) → resultados, progreso y minutos → `POST .../temas/15/recomendacion` en la inscripción 7 (`reinforce_topic`). Con el token de otro estudiante, el mismo intento responde 403.
5. **Docente:** login con `docente.demo@example.com` → `GET /api/cursos-administrables` (solo `DEMO-006`) → administrar módulos de ese curso.

## Problemas resueltos

- **Credenciales del seed inválidas:** los usuarios iniciales tienen hash ficticio y no inician sesión. Se creó el registro público (siempre rol `ESTUDIANTE`) y se usan cuentas demo con hash bcrypt generado con bcryptjs.
- **Escalada de privilegios:** el registro no acepta `rol` y el actor de las operaciones administrativas sale siempre del token, nunca del body.
- **Conexión con `postgres`:** se cambió al rol limitado `plataforma_backend`, que solo escribe mediante funciones de la base de datos. Se verificó con login, registro y los CRUD.
- **Roles con `LIMIT 1`:** si un usuario tenía varios roles activos, el login tomaba uno al azar. Se ordena por jerarquía (ADMINISTRADOR > DOCENTE > ESTUDIANTE).
- **Docente veía a cualquier estudiante:** `studentAccess.js` lo limita a los estudiantes de sus secciones.
- **Fuerza bruta en el login:** se agregó `express-rate-limit` (10 intentos por IP cada 15 minutos).
- **Recomendación con error 500:** el backend enviaba `interactions: []` y el motor lo rechazaba. Ahora arma las interacciones desde los intentos calificados del tema y responde 404 si no hay.
- **Contrato con el frontend:** el frontend esperaba rutas y campos distintos; se adaptaron `/api/modulos` y `/api/temas`, el formato `{ success, data }` y `cursoId` opcional.
- **Swagger pedía token:** `contentRoutes` se montaba en `/api` antes que Swagger y capturaba `/api/docs`; se movió después.
- **Errores YAML y archivos faltantes:** errores de sangría en `openapi.yaml` y `Cannot find module` corregidos.
- **Errores de la base:** los códigos SQLSTATE de las funciones (`42501`, `22023`, `P0002`, `23505`, `55000`) se traducen a 403, 400, 404 y 409 con mensajes claros.
- **Estudiantes sin acceso al contenido (403):** las funciones de 006 solo permiten leer a administrador o docente editor. Se agregaron las rutas `/api/mis-*` sobre la lectura de estudiante de la migración 007.
- **Temas con el mismo nombre:** la recomendación por nombre podía mezclar cursos o ediciones. La ruta nueva usa `inscripcionId` y `temaId`.
- **Selector de curso con ID fijo:** el frontend usaba el curso 1. Se agregó `GET /api/cursos-administrables`.
- **Motor sin Python (`spawn ... ENOENT`):** faltaba el entorno `.venv`; se documentó su creación e instalación de requisitos.
- **Acentos dañados en la recomendación:** Python en Windows escribía en cp1252 y Node leía UTF-8. Se resolvió con `PYTHONUTF8=1` y `PYTHONIOENCODING=utf-8` en el `.env`, sin tocar el código del motor.
- **Conflictos de Git:** se resolvió el conflicto de `main.py` coordinando con Daniel, y se trabaja en una rama con Pull Request.

## Observaciones técnicas

- El backend no escribe directamente en `cursos`, `modulos`, `temas`, `intentos` ni `inscripciones`: usa funciones `SECURITY DEFINER` que validan cuenta, rol y reglas. La base vuelve a validar al administrador o docente editor aunque el token tenga un rol antiguo.
- El token guarda `id` y `rol`; si el rol cambia, el token anterior lo conserva hasta que expire (2 horas).
- Los estudiantes no leen contenido por `/api/modulos` y `/api/temas` (la base exige administrador o docente editor, incluso para leer); usan las rutas `/api/mis-*`, que se apoyan en la migración 007.
- `cursoId` sigue siendo opcional y por defecto 1 en `/api/modulos`, por compatibilidad. El docente demo es editor del curso `DEMO-006`, por lo que debe enviar su `cursoId`, que obtiene de `GET /api/cursos-administrables`.
- Un intento vencido que siga abierto bloquea iniciar otro hasta que se entregue (la entrega lo cierra con motivo `VENCIMIENTO`). No hay cierre automático de intentos abandonados.
- Calificar (`calificar_intento`) solo se ejecuta dentro de la entrega, después de que `entregar_intento` comprobó que el intento es del estudiante del token.
- Los minutos son tiempo transcurrido entre inicio y entrega (incluye pausas), no tiempo activo.
- Cambiar el rol de un usuario o la política de roles múltiples (estudiante y docente a la vez) sigue pendiente de acuerdo del equipo: con varios roles el token usa el de mayor jerarquía, y las rutas `/api/mis-*` exigen el rol `ESTUDIANTE` en el token.
- `porcentajeSemanal` de `/api/students/:id/progress` es `null` hasta que exista historial de progreso.
- La recomendación calcula `repetitions` como `attempts - 1` y envía `navigation_count = 0`, porque la base no registra navegación; esto debe confirmarse con el responsable del motor.
- `horasEstudio` mide solo el tiempo entre inicio y entrega de los intentos, no el tiempo real de estudio.
- `/api/students/:id` y `/progress` dejaron de ser simulados: calculan lo mismo que `/api/mis-*`, agregado por estudiante. Son más costosos (una consulta por inscripción), por lo que conviene que el frontend use `/api/mis-*` cuando necesite detalle.
- Si Python no está disponible, la recomendación responde 502. En `/api/students/:id/progress` el fallo no se propaga: `recomendacion` queda en `null` y el resto del progreso se entrega.
- El motor es un sistema de reglas, no un modelo de aprendizaje automático.

## Integración prevista

Frontend → Backend / API → Base de datos → Motor adaptativo → Recomendaciones y adaptación.

## Próximos pasos

- Que el frontend use la recomendación por `inscripcionId` y `temaId` (después se retira la ruta por nombre) y muestre un guion cuando una variación llegue en `null`.
- Endpoint de inscripción con la función `inscribir_estudiante` (falta una consulta de secciones abiertas para que el estudiante elija).
- Guardar capturas diarias del progreso si se quiere calcular `porcentajeSemanal`.
- Eliminar el valor por defecto `cursoId = 1` de `/api/modulos` cuando el frontend envíe siempre el curso.
- Confirmar con Daniel `repetitions` y `navigation_count`.
- Mantener `openapi.yaml` actualizado con cada endpoint nuevo.