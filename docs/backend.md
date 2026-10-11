# Backend

## Descripción

El Backend es la parte del proyecto encargada de recibir las peticiones del Frontend, aplicar la lógica del sistema y manejar los datos. Es una API REST desarrollada con Node.js y Express.js, siguiendo la arquitectura MVC, con PostgreSQL como base de datos.

Ubicación: `backend/`

## Estado actual

El backend tiene un servidor Express funcionando con autenticación conectada a PostgreSQL: registro, inicio de sesión con token JWT, consulta del usuario autenticado y control de acceso por roles. La API está documentada con OpenAPI y Swagger UI.

También cuenta con los endpoints de resumen y progreso del estudiante para el Dashboard, y con CORS habilitado para el frontend. Parte de los datos de esos endpoints todavía es simulada (ver la sección "Endpoints de estudiantes").

Todavía no está la integración con el motor adaptativo. Se incorporará en las próximas etapas.

## Tecnologías

- Node.js v24.11.1 y npm 11.6.2
- Express.js
- PostgreSQL 18, con la librería `pg`
- JWT (`jsonwebtoken`) para la autenticación
- `bcryptjs` para el cifrado de contraseñas
- Zod para la validación de DTOs
- `dotenv` para las variables de entorno
- `cors` para permitir las peticiones del frontend
- OpenAPI 3 y Swagger UI (`swagger-ui-express`, `js-yaml`) para la documentación de la API

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

Responsabilidad de cada parte:

- `app.js`: arma la aplicación Express (CORS, middlewares, rutas, Swagger y manejo de errores). No abre el puerto, lo que facilita las pruebas del equipo de QA.
- `server.js`: comprueba que los roles existan en la base de datos y enciende el servidor.
- `config/`: `config.js` (variables de entorno), `db.js` (conexión a PostgreSQL), `roles.js`, `permissions.js`, `checkRoles.js` y `swagger.js`.
- `controllers/`: reciben la petición y devuelven la respuesta. No contienen lógica de negocio.
- `dtos/`: DTOs de entrada (validación con Zod) y de salida (forma de los datos que se devuelven).
- `errors/`: clase `AppError`, error con código HTTP.
- `middlewares/`: `authMiddleware.js` (token, roles y permisos), `studentAccess.js` (quién puede consultar a qué estudiante), `validate.js` (validación de DTOs) y `errorHandler.js` (errores y rutas inexistentes).
- `models/`: consultas SQL a PostgreSQL.
- `routes/`: definición de los endpoints.
- `services/`: lógica de negocio.
- `docs/`: especificación `openapi.yaml`.

Flujo de una petición:

ruta → middlewares (token, permisos, validación del DTO) → controller → service → model → PostgreSQL

Los errores se lanzan con `AppError` y se responden en un único lugar, `middlewares/errorHandler.js`.

## Endpoints disponibles

| Método | Ruta | Descripción | Protegida |
|---|---|---|---|
| GET | `/api/health` | Comprueba que el backend funciona | No |
| POST | `/api/auth/register` | Registra un estudiante | No |
| POST | `/api/auth/login` | Inicia sesión y devuelve un token JWT | No |
| GET | `/api/auth/me` | Datos del usuario autenticado | Sí |
| GET | `/api/students/:id` | Resumen del estudiante | Sí |
| GET | `/api/students/:id/progress` | Progreso y recomendación del estudiante | Sí |

### Contrato del login

Entrada:

```json
{ "email": "ana@example.com", "password": "Clave1234" }
```

Salida exitosa (200):

```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "user": { "id": 4, "nombre": "Ana", "apellido": "Lopez", "email": "ana@example.com", "rol": "ESTUDIANTE" }
}
```

### Formato de errores

Todas las respuestas incluyen `success`. Los errores traen `message`, y los de validación (400) traen además `details` con el campo y el mensaje:

```json
{
  "success": false,
  "message": "Datos inválidos",
  "details": [{ "campo": "password", "mensaje": "La contraseña debe tener al menos 8 caracteres" }]
}
```

Códigos usados: `400` datos inválidos, `401` credenciales o token inválidos, `403` sin permiso, `404` ruta o recurso inexistente, `409` email ya registrado, `500` error interno.

Las rutas protegidas requieren el encabezado `Authorization: Bearer <token>`. El token dura 2 horas.

### `/api/auth/me`

Devuelve los datos actuales del usuario dueño del token, consultados en la base de datos. Sirve para que el frontend sepa quién inició sesión, recupere la sesión al recargar la página y detecte usuarios desactivados.

## Endpoints de estudiantes

Alimentan el Dashboard del frontend. El `:id` es el `user.id` que devuelve el login.

- **`GET /api/students/:id`:** resumen del estudiante (datos personales, cursos activos, porcentaje completado, módulos, actividades pendientes, nota promedio y horas de estudio).
- **`GET /api/students/:id/progress`:** variaciones respecto al periodo anterior y recomendación (tema, acción, dificultad, prioridad, descripción y motivo).

Reglas de acceso:

- Un estudiante solo puede consultar su propio `:id`; si consulta otro, recibe `403`.
- Docentes y administradores pueden consultar cualquiera (pendiente: limitar al docente a los estudiantes de sus secciones).
- Si el id no es un entero válido responde `400`, y si no existe o no es un estudiante activo, `404`.

Datos reales y simulados:

- **Datos reales:** nombre, apellido, email, rol, cursos activos y lista de cursos (tablas `usuarios`, `inscripciones`, `secciones`, `ediciones_curso` y `cursos`).
- **Datos simulados:** porcentaje completado, módulos, actividades pendientes, nota promedio, horas de estudio, variaciones y recomendación. La respuesta incluye `"simulado": true` mientras esto sea así. Están en `studentService.js`, marcados con `TODO`, y se reemplazarán cuando existan las tablas de temas, interacciones, recomendaciones, contenidos y evaluaciones. El formato de la respuesta no cambiará.

Ejemplo de resumen (`GET /api/students/4`):

```json
{
  "success": true,
  "simulado": true,
  "student": {
    "id": 4,
    "nombre": "Ana",
    "apellido": "Lopez",
    "email": "ana@example.com",
    "rol": "ESTUDIANTE",
    "cursosActivos": 1,
    "cursos": [{ "cursoId": 1, "nombre": "Cálculo", "seccion": "SEC 1", "estado": "ACTIVA" }],
    "porcentajeCompletado": 72,
    "modulosFinalizados": 18,
    "modulosPendientes": 7,
    "actividadesPendientes": 8,
    "notaPromedio": 86,
    "horasEstudio": 32
  }
}
```

## CORS y conexión con el frontend

El backend permite las peticiones del origen configurado en la variable `CORS_ORIGIN` (por defecto `http://localhost:5173`, el servidor de Vite). El frontend puede llamar directo a `http://localhost:3000` o usar el proxy de Vite hacia el puerto 3000.

## Documentación de la API (Swagger)

Con el servidor encendido: http://localhost:3000/api/docs

La especificación está en `backend/src/docs/openapi.yaml` y su versión en JSON en http://localhost:3000/api/docs.json. Si se cambia un DTO o un endpoint, se debe actualizar también ese archivo. El enum de roles de la especificación se toma de `roles.js`, no se edita a mano.

## Roles y permisos

- Los roles (`ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR`) se definen en `src/config/roles.js`, única fuente de verdad. Deben coincidir con `roles.codigo` en PostgreSQL; el servidor lo verifica al arrancar y no inicia si falta alguno.
- Los permisos por rol se definen en `src/config/permissions.js`.
- Las rutas se protegen con `verifyToken` y `requireRole(...)` o `requirePermission('permiso')`.
- El registro público siempre crea usuarios con rol `ESTUDIANTE`, para evitar que alguien se asigne un rol con más permisos (escalada de privilegios). Los docentes y administradores se crean directamente en la base de datos.
- El token guarda el `id` y el `rol` del usuario. Si el rol cambia, el token anterior conserva el valor viejo hasta que expire.
- En las rutas de estudiantes, además del permiso, el middleware `studentAccess.js` verifica que el estudiante consulte solo sus propios datos.

## Configuración

El backend lee sus variables desde `backend/.env`, que no se sube a GitHub. El archivo `backend/.env.example` muestra cuáles son: `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET` y `CORS_ORIGIN`. Sin `JWT_SECRET` el servidor no arranca.

## Base de datos

Se utiliza PostgreSQL con la base `motor_adaptativo`. El esquema (usuarios, roles, usuario_roles, cursos, curso_editores, ediciones_curso, secciones, seccion_docentes e inscripciones) y los datos de prueba fueron elaborados por el compañero de base de datos.

- El seed es obligatorio, porque inserta los roles que el backend necesita.
- Los usuarios del seed tienen un hash ficticio y no pueden iniciar sesión. Para probar el login se registra un usuario con `POST /api/auth/register`.
- El registro crea el usuario y su rol en una sola transacción, de modo que no queda nada a medias si algo falla.
- Para ver cursos reales en el resumen del estudiante, el usuario necesita una inscripción en la tabla `inscripciones`.

## Trabajo realizado

**Preparación del entorno y estructura**

- Se verificó el entorno de desarrollo: Git, Node.js y npm.
- Se clonó el repositorio del grupo y se creó la carpeta `backend/` con la estructura MVC.
- Se agregaron un `README.md` y un `.gitignore` propios del backend.

**Servidor y API**

- Se inicializó el proyecto Node.js, se instaló Express y se creó el servidor con el script `npm start`.
- Se separó `app.js` (arma la aplicación) de `server.js` (la enciende).
- Se implementó `GET /api/health`.
- Se implementó el registro, el login y `/api/auth/me`, con contraseñas cifradas con bcrypt y token JWT.
- Se implementaron `GET /api/students/:id` y `GET /api/students/:id/progress` para el Dashboard, con datos reales (identidad y cursos) y datos simulados marcados con `simulado: true`.
- Se habilitó CORS para el origen del frontend, configurable con `CORS_ORIGIN`.

**Calidad y arquitectura**

- Se agregaron DTOs de entrada y salida con Zod; la salida nunca expone el hash de la contraseña.
- Se centralizó el manejo de errores con `AppError` y `errorHandler`.
- Se implementó el control de acceso por roles y permisos, con los roles definidos en una única fuente de verdad y verificados contra la base al arrancar.
- Se creó el middleware de validación de DTOs.
- Se creó el middleware `studentAccess` para que cada estudiante solo consulte sus propios datos.

**Base de datos**

- Se instaló PostgreSQL 18, se creó la base `motor_adaptativo` y se cargaron el esquema y los datos de prueba.
- Se conectó el backend a PostgreSQL con `pg`, usando variables de entorno.

**Documentación**

- Se documentó la API con OpenAPI 3 y Swagger UI, incluidos los endpoints de estudiantes.
- Se actualizaron el README del backend y este documento.

## Integración prevista

El Backend será el punto de conexión entre los demás componentes del proyecto:

Frontend → Backend / API → Base de datos → Motor adaptativo → Recomendaciones y adaptación

El Backend recibirá la información generada por la interacción del estudiante, como resultados, tiempo de estudio y progreso, la almacenará en PostgreSQL y la enviará al motor adaptativo (Node → Python → JSON → Node) para generar recomendaciones.

## Próximos pasos

- Reemplazar los datos simulados de los endpoints de estudiantes cuando el compañero de base de datos cree las tablas de temas, interacciones, recomendaciones, contenidos y evaluaciones (campos de comportamiento: `study_minutes`, `errors`, `attempts`, `repetitions`, `navigation_count` y `score_percentage`).
- Definir con Daniel el formato JSON de entrada y salida del motor adaptativo y cómo Node lo invocará (Node → Python → JSON → Node).
- Limitar al docente a los estudiantes de sus secciones.
- Agregar cada endpoint nuevo al `openapi.yaml`.