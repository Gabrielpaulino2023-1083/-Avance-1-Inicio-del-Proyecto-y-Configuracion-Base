# Backend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la API REST del proyecto, construida con Node.js y Express.js siguiendo la arquitectura MVC. Recibe las peticiones del frontend, aplica la lógica del sistema y maneja los datos en PostgreSQL. También es el puente hacia el motor adaptativo en Python.

El backend cubre la autenticación (registro, inicio de sesión con token JWT y control de acceso por roles), un CRUD de cursos para administradores, un CRUD de módulos y temas para administradores y docentes editores, y el aprendizaje del estudiante: sus cursos, el contenido publicado, los intentos de actividades (iniciar, guardar, entregar y calificar), el progreso, los resultados y la recomendación del motor adaptativo con datos reales de la base. Los endpoints del Dashboard (`/api/students/:id` y `/progress`) también usan datos reales.

## Qué contiene esta carpeta

Dentro de `src/` hay una carpeta por cada responsabilidad del backend:

* `config/` — configuración (variables de entorno, conexión a PostgreSQL, roles, permisos, Swagger)
* `controllers/` — reciben la petición y devuelven la respuesta
* `dtos/` — validación de los datos de entrada y forma de los datos de salida
* `errors/` — errores propios de la aplicación y traducción de errores de la base
* `middlewares/` — autenticación, autorización, acceso a estudiantes, validación, límite de intentos y manejo de errores
* `models/` — consultas a la base de datos y llamadas a sus funciones
* `routes/` — definición de los endpoints de la API
* `services/` — lógica de negocio y conexión con el motor adaptativo (`engineClient.js`)
* `docs/` — especificación OpenAPI de la API

El archivo `src/app.js` arma la aplicación y `src/server.js` la enciende.

## Endpoints disponibles

**Autenticación y salud**

* `GET /api/health` — comprueba que el backend funciona
* `POST /api/auth/register` — registra un estudiante
* `POST /api/auth/login` — inicia sesión y devuelve un token JWT
* `GET /api/auth/me` — datos del usuario autenticado (requiere token)

**Estudiantes (Dashboard, datos reales)**

* `GET /api/students/:id` — resumen del estudiante (requiere token)
* `GET /api/students/:id/progress` — progreso del estudiante (requiere token)
* `POST /api/students/:id/recommendation` — recomendación del motor adaptativo por nombre de tema (se mantiene por compatibilidad; preferir la ruta por inscripción)

**Cursos (solo administrador)**

* `POST /api/cursos` — crea un curso (nace en `BORRADOR`)
* `GET /api/cursos` — lista cursos (filtros `estado`, `limite`, `desplazamiento`)
* `GET /api/cursos/:id` — consulta un curso
* `PUT /api/cursos/:id` — edita código, nombre y descripción
* `PATCH /api/cursos/:id/estado` — cambia el estado a `ACTIVO` o `ARCHIVADO`

**Módulos y temas (administrador o docente editor del curso)**

* `GET /api/cursos-administrables` — cursos que el usuario puede gestionar (selector de curso)
* `GET /api/modulos` — lista módulos (`cursoId` opcional, por defecto 1)
* `POST /api/modulos` — crea un módulo
* `PUT /api/modulos/:id` — edita un módulo
* `PATCH /api/modulos/:id/estado` — cambia su estado
* `DELETE /api/modulos/:id` — elimina un módulo
* `GET /api/modulos/:id/temas` — lista los temas de un módulo
* `POST /api/modulos/:id/temas` — crea un tema
* `PUT /api/temas/:id` — edita un tema
* `PATCH /api/temas/:id/estado` — cambia su estado
* `DELETE /api/temas/:id` — elimina un tema

**Aprendizaje del estudiante (solo rol `ESTUDIANTE`)**

* `GET /api/mis-cursos` — inscripciones activas del estudiante (de aquí sale el `inscripcionId`)
* `GET /api/mis-cursos/:cursoId/modulos` — módulos publicados del curso
* `GET /api/mis-modulos/:moduloId/temas` — temas publicados del módulo
* `GET /api/mis-inscripciones/:inscripcionId/temas/:temaId/actividades` — actividades publicadas del tema
* `POST /api/mis-inscripciones/:inscripcionId/actividades/:actividadId/intentos` — inicia un intento y devuelve el cuestionario
* `GET /api/mis-intentos/:intentoId/cuestionario` — retoma el cuestionario de un intento en curso
* `PUT /api/mis-respuestas/:respuestaId/opciones` — guarda la selección de una pregunta
* `POST /api/mis-intentos/:intentoId/entrega` — entrega el intento y lo califica
* `GET /api/mis-inscripciones/:inscripcionId/resultados` — resultados por actividad
* `GET /api/mis-inscripciones/:inscripcionId/progreso` — progreso por tema
* `GET /api/mis-inscripciones/:inscripcionId/actividad-reciente` — últimos intentos (`limite`, 1 a 100)
* `GET /api/mis-inscripciones/:inscripcionId/minutos` — minutos por día (`desde` y `hasta`, formato `AAAA-MM-DD`)
* `POST /api/mis-inscripciones/:inscripcionId/temas/:temaId/recomendacion` — recomendación del motor adaptativo

Las rutas protegidas necesitan el encabezado `Authorization: Bearer <token>`. Un estudiante solo puede consultar su propio `:id` en `/api/students`; un administrador, cualquiera; un docente, solo los estudiantes de sus secciones. En las rutas de aprendizaje el estudiante sale siempre del token, nunca de la URL ni del cuerpo.

### Eliminar un curso = archivarlo

El CRUD de cursos no borra registros: **eliminar es una baja lógica** (estado `ARCHIVADO`), para conservar el historial. Archivar se rechaza con `409` si el curso tiene ediciones planificadas, abiertas o en curso, y un curso archivado no se puede editar ni reactivar. La administración de cursos usa funciones de PostgreSQL y el administrador sale siempre del token, nunca del cuerpo de la petición.

### Módulos y temas

Respuesta `{ "success": true, "data": ... }`. Cada módulo incluye `totalTemas`. Campos: `nombre`, `descripcion`, `orden` y `estado` (`BORRADOR`, `PUBLICADO`, `ARCHIVADO`). Reglas, validadas por la base de datos:

* `orden` repetido dentro del curso (módulos) o del módulo (temas) → `409`.
* El borrado es físico, solo en `BORRADOR`; con temas (módulo) o actividades (tema) → `409`.
* Solo administrador o docente editor activo del curso; el resto, incluidos estudiantes, → `403`.

El docente elige el curso con `GET /api/cursos-administrables` (el administrador ve todos; el docente, solo donde es editor) y envía ese `cursoId` al administrar módulos.

### Aprendizaje del estudiante

Todas estas rutas leen y escriben mediante funciones de PostgreSQL (migraciones 007 y 008 y las de intentos de la 003). La base valida que la inscripción pertenezca al estudiante del token. Respuesta `{ "success": true, "data": ... }`.

Flujo de un intento:

1. `GET /api/mis-cursos` devuelve las inscripciones; de ahí se toma el `inscripcionId`.
2. Con `GET /api/mis-cursos/:cursoId/modulos`, `GET /api/mis-modulos/:moduloId/temas` y `GET .../temas/:temaId/actividades` se navega el contenido publicado.
3. `POST .../actividades/:actividadId/intentos` inicia el intento y devuelve el cuestionario en una sola transacción. Cada pregunta trae su `respuestaId` y las opciones (`id`, `texto` y `orden`). **Nunca se envían las respuestas correctas ni las explicaciones.**
4. `PUT /api/mis-respuestas/:respuestaId/opciones` con `{ "opciones": [ids] }` guarda la selección. Cada llamada reemplaza la anterior; una lista vacía la borra. Si se recarga la pantalla, `GET /api/mis-intentos/:intentoId/cuestionario` devuelve el mismo intento con lo ya guardado, sin gastar otra oportunidad.
5. `POST /api/mis-intentos/:intentoId/entrega` entrega y califica en el servidor, en una misma transacción. No existe una ruta pública de calificación y el frontend nunca envía puntajes. Si el intento ya venció, `motivoEntrega` es `VENCIMIENTO`.

Resultados, progreso y actividad:

* **Resultados:** una fila por actividad visible, incluidas las pendientes. Antes de calificar, los promedios son `null` (nunca 0). Las prácticas no tienen nota académica. Para las evaluaciones se filtra `finalidad = EVALUACION`.
* **Progreso:** una actividad cuenta como realizada si tiene al menos un intento calificado, sin nota mínima. Un tema sin actividades devuelve `progresoPorcentaje: null` y `completado: false`.
* **Minutos:** tiempo transcurrido entre inicio y entrega, por día local (America/Santo_Domingo). El intervalo es semiabierto (`hasta` no se incluye) y de máximo 366 días. No mide tiempo activo de estudio.

Errores de la base traducidos: `42501` → `403`, `22023` → `400`, `P0002` → `404`, `55000` y `P0001` → `409`. El texto interno de SQL nunca se envía al cliente.

### Datos del Dashboard

Todo sale de la base de datos: las rutas `/api/mis-*` y los endpoints `/api/students/:id` y `/progress` (`"simulado": false`).

* **`/api/students/:id`:** nombre, apellido, email, rol, cursos activos, lista de cursos, porcentaje completado (promedio del progreso por tema), módulos finalizados y pendientes, actividades pendientes, nota promedio (`null` si aún no hay evaluaciones calificadas) y horas de estudio.
* **`/api/students/:id/progress`:** variaciones de los últimos 7 días contra los 7 anteriores y la recomendación del motor para el tema más débil. `porcentajeSemanal` es siempre `null` (la base no guarda el historial del progreso) y las variaciones sin datos para comparar también son `null`: el frontend debe mostrar un guion. `recomendacion` es `null` si no hay intentos calificados.

Para detalle por inscripción, el frontend puede usar `/api/mis-inscripciones/:inscripcionId/progreso`, `/resultados`, `/actividad-reciente` y `/minutos`.

### Recomendación

`POST /api/mis-inscripciones/:inscripcionId/temas/:temaId/recomendacion` no recibe cuerpo. El backend arma una interacción por cada intento calificado del estudiante en ese tema y esa inscripción, la envía al motor adaptativo y responde:

```json
{
  "success": true,
  "data": {
    "inscripcionId": 7, "temaId": 15, "tema": "SQL JOIN",
    "accion": "reinforce_topic", "dificultad": "reduced",
    "recomendacion": "Se recomienda reforzar el tema SQL JOIN ...",
    "mastery": 16.67, "errors": 10, "attempts": 2
  }
}
```

* `mastery`: promedio de puntaje (0 a 100) de los intentos calificados.
* `errors`: total de respuestas con puntaje 0.
* `attempts`: promedio del número de intento.
* Si el estudiante no tiene intentos calificados en ese tema, responde `404`.

Usar `inscripcionId` y `temaId` evita mezclar temas con el mismo nombre en cursos o ediciones distintos. La ruta antigua `POST /api/students/:id/recommendation` (por nombre del tema) se mantiene por compatibilidad.

## Documentación interactiva (Swagger)

Con el servidor encendido, abrir en el navegador:

http://localhost:3000/api/docs

Desde ahí se pueden probar todos los endpoints. Para las rutas protegidas: hacer login, copiar el `token`, pulsar **Authorize** y pegarlo. La especificación está en `src/docs/openapi.yaml`.

## Tecnologías

Node.js, Express.js, PostgreSQL (`pg`), JWT (`jsonwebtoken`), `bcryptjs` para cifrar contraseñas, Zod para validar los DTOs, `dotenv` para las variables de entorno, `cors` para la comunicación con el frontend, `helmet` y `express-rate-limit` para seguridad, Swagger UI para la documentación y Python con Pandas para el motor adaptativo.

## Cómo correrlo

### 1. Requisitos

* Node.js y npm
* PostgreSQL instalado y funcionando (puerto 5432 por defecto)
* Python 3 (para el endpoint de recomendación; ver "Motor adaptativo")

### 2. Crear la base de datos

Crear una base llamada `motor_adaptativo` y cargar en ella los scripts de la carpeta `database/`, **en este orden**, cada uno una sola vez:

1. `database/migrations/001_estructura_academica_inicial.sql`
2. `database/migrations/002_modulos_temas.sql`
3. `database/migrations/003_actividades_intentos_respuestas.sql`
4. `database/security/001_roles_permisos.sql`
5. `database/migrations/004_inscripcion_estudiantes.sql`
6. `database/migrations/005_crud_cursos.sql`
7. `database/migrations/006_crud_modulos_temas.sql`
8. `database/migrations/007_lectura_contenido_estudiantes.sql`
9. `database/migrations/008_consultas_integracion.sql`
10. `database/seeds/datos_prueba.sql` y luego `database/seeds/datos_prueba_modulos_temas.sql`

Por ejemplo, desde la terminal (en una sola línea cada comando):

```
psql -U postgres -c "CREATE DATABASE motor_adaptativo;"
psql -U postgres -d motor_adaptativo -v ON_ERROR_STOP=1 -f database/migrations/001_estructura_academica_inicial.sql
```

y así con cada archivo. También se puede hacer desde pgAdmin con el Query Tool y la opción **Open File**. El seed inicial es obligatorio, porque inserta los roles (`ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR`) y el servidor no arranca si faltan. Si `psql` no se reconoce en Windows, agregar su carpeta al PATH de la ventana: `set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin`. Más detalles en `database/README.md`.

Las migraciones 007 y 008 y los seeds con `\prompt` (que piden un hash) deben ejecutarse con `psql`; pgAdmin no entiende esos comandos.

### 3. Crear la contraseña del rol del backend

El backend se conecta con el rol limitado `plataforma_backend` (creado por el script de seguridad), no con `postgres`. Desde `psql`:

```
\password plataforma_backend
```

### 4. Crear los usuarios de prueba

Cada seed pide un hash bcrypt. Generarlo desde `backend` (uno por cuenta):

```
node -e "console.log(require('bcryptjs').hashSync('AdminDemo-2026!', 10))"
```

y ejecutar el seed por `psql` desde la raíz del repositorio, pegando el hash cuando lo pida. Orden recomendado:

```
psql -X -U postgres -d motor_adaptativo -f database/seeds/datos_prueba_administrador.sql
psql -X -U postgres -d motor_adaptativo -f database/seeds/datos_prueba_actividades_intentos.sql
psql -X -U postgres -d motor_adaptativo -f database/seeds/datos_prueba_docente.sql
psql -X -U postgres -d motor_adaptativo -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_integracion_resultados.sql
```

En Windows, antes de ejecutarlos: `chcp 65001` y `set PGCLIENTENCODING=UTF8`. El último seed no pide hash: reutiliza al estudiante demo creado por el segundo. Cuentas resultantes (contraseñas públicas, solo para desarrollo):

* Administrador: `administrador.demo@example.com` / `AdminDemo-2026!`
* Estudiante: `estudiante.demo@example.com` / `DemoEquipo-2026!` (con los cursos `DEMO-003` y `DEMO-SQL-007`)
* Docente: `docente.demo@example.com` / `DocenteDemo-2026!` (editor del curso `DEMO-006`)

Cada seed trae su archivo de pruebas en `database/test/`, y también hay pruebas para las migraciones 007 y 008 (`pruebas_migracion_007.sql` y `pruebas_migracion_008.sql`). Las pruebas revierten sus cambios al terminar.

### 5. Instalar dependencias

```
cd backend
npm install
```

### 6. Configurar las variables de entorno

Copiar el archivo de ejemplo y completar los valores:

```
copy .env.example .env
```

Variables del archivo `.env`:

```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=motor_adaptativo
DB_USER=plataforma_backend
DB_PASSWORD=la_contraseña_del_rol_plataforma_backend
JWT_SECRET=una-clave-larga-y-secreta
CORS_ORIGIN=http://localhost:5173
PYTHONUTF8=1
PYTHONIOENCODING=utf-8
```

`CORS_ORIGIN` es la dirección del frontend que puede llamar a la API (por defecto, el servidor de Vite en `http://localhost:5173`). `PYTHONUTF8` y `PYTHONIOENCODING` hacen que Python lea y escriba en UTF-8; sin ellas, en Windows los acentos de las recomendaciones salen dañados. Opcionalmente, `PYTHON_EXECUTABLE` indica el Python del motor adaptativo. El archivo `.env` es personal y **no se sube a GitHub**. Cada integrante crea el suyo. Sin `JWT_SECRET` el servidor no arranca.

### 7. Encender el servidor

```
npm start
```

Debe aparecer `Servidor corriendo en http://localhost:3000`. Para comprobarlo, abrir http://localhost:3000/api/health.

## Motor adaptativo

El endpoint de recomendación llama al motor de `adaptive-engine/` (Python) mediante `src/services/engineClient.js`. Para que funcione, en la raíz del repositorio:

```
python -m venv .venv
.venv\Scripts\pip install -r adaptive-engine\requirements.txt
```

También se puede indicar otro Python con la variable `PYTHON_EXECUTABLE`. El motor necesita al menos una interacción; si el estudiante no tiene intentos calificados en el tema, el backend responde `404` antes de llamarlo. Si Python no está disponible o falla, el endpoint responde `502`. Para ver una recomendación real hace falta un estudiante con intentos calificados (seed `datos_prueba_integracion_resultados.sql`, tema `SQL JOIN`, que da `reinforce_topic`).

## Seguridad

* Cabeceras de seguridad con `helmet`.
* Login y registro limitados a 10 peticiones por IP cada 15 minutos (`429`).
* JSON limitado a 100 KB (`413`).
* Conexión a PostgreSQL con el rol limitado `plataforma_backend`; la escritura de cursos, módulos, temas, intentos e inscripciones se hace solo mediante funciones.
* En las rutas del estudiante, el usuario sale siempre del token y la base valida que la inscripción o el intento le pertenezcan; otro estudiante recibe `403`.
* El cuestionario nunca incluye `es_correcta` ni explicaciones, y la calificación se hace solo en el servidor.
* Los errores de la base se traducen a códigos HTTP sin enviar el texto interno de SQL.
* Si un usuario tiene varios roles activos, se usa el de mayor jerarquía.

## Conexión con el frontend

El frontend puede llamar directo a `http://localhost:3000` (el backend permite el origen configurado en `CORS_ORIGIN`) o usar el proxy de Vite hacia el puerto 3000. El `id` que se usa en `/api/students/:id` es el `user.id` que devuelve el login. Las rutas de cursos, módulos, temas y aprendizaje del estudiante responden `{ "success": true, "data": ... }`.

## Usuarios para probar

Los usuarios del seed inicial (`admin@example.com`, `docente@example.com`, `estudiante@example.com`) tienen un hash ficticio y **no pueden iniciar sesión**. Para probar:

* Estudiante con datos: `estudiante.demo@example.com` (ver paso 4). También se puede registrar uno nuevo con `POST /api/auth/register`, aunque no tendrá inscripciones.
* Administrador: `administrador.demo@example.com`.
* Docente: `docente.demo@example.com`, editor del curso `DEMO-006`.

Para ver cursos reales en el resumen, el usuario necesita una inscripción en la tabla `inscripciones`.

## Problemas frecuentes

* **`password authentication failed`**: la contraseña de `DB_PASSWORD` no coincide con la de `DB_USER`.
* **`database "motor_adaptativo" does not exist`**: falta crear la base o el nombre de `DB_NAME` es distinto.
* **`Roles ausentes en la base de datos`**: no se cargó el seed inicial.
* **`Falta JWT_SECRET`**: el archivo `.env` no existe o no tiene esa variable.
* **`Cannot find module ...`**: falta ejecutar `npm install` dentro de `backend/`, o falta algún archivo nuevo.
* **Puerto 3000 ocupado**: cambiar `PORT` en el `.env`.
* **Error de CORS en el navegador**: el origen del frontend no coincide con `CORS_ORIGIN`.
* **`429 Demasiados intentos`**: se superó el límite de login; reiniciar el servidor o esperar 15 minutos.
* **`403` en `/api/cursos` o `/api/modulos`**: el usuario no es administrador (o docente editor del curso).
* **`403` en las rutas `/api/mis-*`**: el usuario no es estudiante, la inscripción no es suya o ya no está activa.
* **`409` al archivar un curso**: tiene ediciones pendientes o ya está archivado.
* **`409` al eliminar un módulo o tema**: no está en `BORRADOR` o tiene temas/actividades.
* **`409` al iniciar un intento**: la actividad no está disponible, ya hay un intento abierto (entregarlo primero) o se alcanzó el límite de intentos.
* **`404` en recomendación**: el estudiante no tiene intentos calificados en ese tema.
* **`502` en recomendación con `spawn ... python.exe ENOENT` en la consola del servidor**: falta el entorno `.venv` en la raíz del repositorio (ver "Motor adaptativo").
* **Acentos dañados (`�`) en la recomendación**: faltan `PYTHONUTF8=1` y `PYTHONIOENCODING=utf-8` en el `.env`.
* **`permission denied` (42501)**: faltan las migraciones 004 a 008 o el script de seguridad.
* **`psql` no se reconoce**: agregar la carpeta `bin` de PostgreSQL al PATH de la ventana.
* **"Token requerido" al abrir `/api/docs`**: un router con `verifyToken` está montado antes que Swagger en `app.js`.

## Documentación

El detalle de lo realizado en el backend está en `docs/backend.md`, en la raíz del repositorio.

## Responsable de este módulo

Porfirio Ramírez - Backend y API REST