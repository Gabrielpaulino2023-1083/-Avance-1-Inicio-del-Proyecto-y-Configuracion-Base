# Backend

## Descripción

El Backend recibe las peticiones del Frontend, aplica la lógica del sistema y maneja los datos. Es una API REST desarrollada con Node.js y Express.js, siguiendo la arquitectura MVC, con PostgreSQL como base de datos.

Ubicación: `backend/`

## Estado actual

El backend tiene un servidor Express con autenticación conectada a PostgreSQL (registro, login con JWT, `/me` y control de acceso por roles), endpoints del Dashboard del estudiante, un CRUD de cursos para administradores, un CRUD de módulos y temas para administradores y docentes editores, y la conexión con el motor adaptativo (Python). La API está documentada con OpenAPI y Swagger UI.

Parte de los datos del Dashboard ya sale de la base de datos y parte sigue simulada (ver "Endpoints de estudiantes").

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

Códigos: `400` datos inválidos, `401` credenciales o token inválidos, `403` sin permiso, `404` recurso inexistente, `409` conflicto, `413` cuerpo demasiado grande, `429` demasiados intentos, `500` error interno.

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
- **Simulados** (`"simulado": true`): porcentaje completado, módulos finalizados y pendientes. Esperan que el grupo defina qué significa "completado".

**`GET /api/students/:id/progress`:** variaciones y recomendación. Todavía simulado (`"simulado": true`).

**`POST /api/students/:id/recommendation`:** recibe `{ "topic": "nombre del tema" }`.

- Arma una interacción por cada intento calificado del estudiante en ese tema (por nombre) y la envía al motor adaptativo.
- Cada interacción: `score_percentage` (puntaje obtenido sobre máximo), `errors` (respuestas con puntaje 0), `attempts` (número de intento), `study_minutes` (entrega menos inicio), `repetitions` (`attempts - 1`) y `navigation_count` (0, porque no existe en la base).
- Responde `tema`, `accion`, `dificultad`, `recomendacion` y la evidencia `mastery` (promedio de puntaje), `errors` (total) y `attempts` (promedio).
- Si el estudiante no tiene intentos calificados en ese tema, responde `404`.

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
- `cursoId` es opcional al crear o listar módulos; por defecto es 1, porque el frontend actual trabaja con un solo curso.

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
- El motor exige al menos una interacción. Si Python no está disponible o falla, el endpoint responde error `500`.

## Seguridad

- Cabeceras HTTP con `helmet`.
- Login y registro limitados a 10 peticiones por IP cada 15 minutos (`429`).
- JSON limitado a 100 KB (`413`).
- Contraseñas con bcrypt; los DTOs de salida nunca exponen el hash.
- Si un usuario tiene varios roles activos, se usa el de mayor jerarquía (ADMINISTRADOR > DOCENTE > ESTUDIANTE).
- Conexión a PostgreSQL con el rol limitado `plataforma_backend`, no con `postgres`.

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

Variables en `backend/.env` (no se sube a GitHub; el ejemplo está en `.env.example`): `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET` y `CORS_ORIGIN`. Opcional: `PYTHON_EXECUTABLE`. `DB_USER` debe ser `plataforma_backend`. Sin `JWT_SECRET` el servidor no arranca.

## Base de datos

PostgreSQL con la base `motor_adaptativo`, elaborada por el compañero de base de datos (carpeta `database/`):

- Se aplican en orden: `001`, `002`, `003`, `security/001_roles_permisos.sql`, `004` (inscripciones), `005` (CRUD de cursos) y `006` (CRUD de módulos y temas). El seed inicial es obligatorio porque inserta los roles.
- 17 tablas y la vista `resultados_actividades`. La escritura de intentos, inscripciones, cursos, módulos y temas se hace solo mediante funciones.
- Los usuarios del seed inicial tienen hash ficticio y no inician sesión. Para probar: `POST /api/auth/register`, o las cuentas demo: administrador (`datos_prueba_administrador.sql`) y docente (`datos_prueba_docente.sql`), que piden un hash bcrypt generado con bcryptjs.
- El seed `datos_prueba_actividades_intentos.sql` crea un estudiante con intentos calificados para probar el resumen y la recomendación.
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

**Calidad y seguridad**
- DTOs con Zod, errores centralizados, control de acceso por roles y permisos, docente limitado a sus secciones.
- `helmet`, límite de intentos de login, límite de tamaño del JSON y prioridad de roles.
- Conexión a PostgreSQL con el rol limitado `plataforma_backend`.

**Base de datos**
- Se instaló PostgreSQL 18 y se aplicaron las migraciones 001 a 006, la seguridad y los seeds, incluido el administrador demo.

**Documentación**
- OpenAPI 3 y Swagger UI con todos los endpoints, README y este documento.

## Evidencia con datos reales

Se probó el backend con Swagger y PostgreSQL local, conectado con el rol `plataforma_backend`:

- **Crear:** `POST /api/cursos` y `POST /api/modulos` insertan filas en `cursos` y `modulos`; `POST /api/modulos/:id/temas` inserta en `temas`. En todas, `creado_por` es el id del administrador del token (no del body).
- **Leer:** `GET /api/cursos`, `GET /api/modulos?cursoId=1` y `GET /api/modulos/:id/temas` devuelven los datos de la base, con `totalTemas` calculado.
- **Actualizar:** `PUT` y `PATCH .../estado` cambian la fila y actualizan `actualizado_en` (verificado en pgAdmin).
- **Eliminar:** `DELETE /api/temas/:id` y `DELETE /api/modulos/:id` borran la fila solo en `BORRADOR` y sin hijos; en cursos, eliminar es archivar.
- **Reglas rechazadas por la base:** orden repetido (409), borrar un módulo con temas (409), archivar un curso con ediciones abiertas (409) y usar el token de un estudiante (403).

## Flujos para probar

1. **Administrador (cursos):** login con `administrador.demo@example.com` → crear curso → consultar → editar → activar → archivar → repetir el código (409) → archivar `CALC-PRUEBA` (409).
2. **Administrador o docente (contenido):** crear módulo → editar → cambiar estado → crear tema → intentar eliminar el módulo con tema (409) → eliminar el tema → eliminar el módulo.
3. **Estudiante:** registro → login → `GET /api/students/:id` → `POST /api/students/:id/recommendation` (404 si no tiene intentos calificados en ese tema) → cualquier ruta de cursos o contenido (403).

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
- **Conflictos de Git:** se resolvió el conflicto de `main.py` coordinando con Daniel, y se trabaja en una rama con Pull Request.

## Observaciones técnicas

- El backend no escribe directamente en `cursos`, `modulos`, `temas`, `intentos` ni `inscripciones`: usa funciones `SECURITY DEFINER` que validan cuenta, rol y reglas. La base vuelve a validar al administrador o docente editor aunque el token tenga un rol antiguo.
- El token guarda `id` y `rol`; si el rol cambia, el token anterior lo conserva hasta que expire (2 horas).
- Los estudiantes **no pueden leer** módulos y temas por estas rutas: la base exige administrador o docente editor incluso para leer. Hará falta una consulta de lectura para estudiantes.
- `cursoId` es opcional y por defecto 1, porque el frontend actual maneja un solo curso. El docente demo es editor del curso `DEMO-006`, por lo que debe enviar su `cursoId`.
- La recomendación calcula `repetitions` como `attempts - 1` y envía `navigation_count = 0`, porque la base no registra navegación; esto debe confirmarse con el responsable del motor.
- `horasEstudio` mide solo el tiempo entre inicio y entrega de los intentos, no el tiempo real de estudio.
- Los datos de `/progress`, el porcentaje completado y los módulos finalizados siguen simulados (`simulado: true`) hasta definir qué significa "completado".
- Si Python no está disponible, la recomendación responde 500.
- El motor es un sistema de reglas, no un modelo de aprendizaje automático.

## Integración prevista

Frontend → Backend / API → Base de datos → Motor adaptativo → Recomendaciones y adaptación.

## Próximos pasos

- Lectura de módulos y temas para estudiantes (la base hoy solo permite leer a administrador o docente editor).
- Selector de curso en el frontend (hoy `cursoId` por defecto es 1).
- Variaciones semanales, módulos y porcentaje completado (requiere definir "completado" con el grupo).
- Dashboard completo: actividad reciente, horas semanales y dominio por tema.
- Guardar intentos del ejercicio y listar evaluaciones del estudiante.
- Endpoint de inscripción con la función `inscribir_estudiante`.
- Confirmar con Daniel `repetitions` y `navigation_count`.
- Mantener `openapi.yaml` actualizado con cada endpoint nuevo.