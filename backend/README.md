# Backend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la API REST del proyecto, construida con Node.js y Express.js siguiendo la arquitectura MVC. Recibe las peticiones del frontend, aplica la lógica del sistema y maneja los datos en PostgreSQL. También es el puente hacia el motor adaptativo en Python.

El backend cubre la autenticación (registro, inicio de sesión con token JWT y control de acceso por roles), los endpoints del Dashboard del estudiante (resumen, progreso y recomendación), un CRUD de cursos para administradores y la conexión con el motor adaptativo. Parte de los datos del Dashboard todavía es simulada y se irá reemplazando por datos reales de la base de datos.

## Qué contiene esta carpeta

Dentro de `src/` hay una carpeta por cada responsabilidad del backend:

* `config/` — configuración (variables de entorno, conexión a PostgreSQL, roles, permisos, Swagger)
* `controllers/` — reciben la petición y devuelven la respuesta
* `dtos/` — validación de los datos de entrada y forma de los datos de salida
* `errors/` — errores propios de la aplicación
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

**Estudiantes (Dashboard)**

* `GET /api/students/:id` — resumen del estudiante (requiere token)
* `GET /api/students/:id/progress` — progreso del estudiante (requiere token)
* `POST /api/students/:id/recommendation` — recomendación del motor adaptativo para un tema (requiere token)

**Cursos (solo administrador)**

* `POST /api/cursos` — crea un curso (nace en `BORRADOR`)
* `GET /api/cursos` — lista cursos (filtros `estado`, `limite`, `desplazamiento`)
* `GET /api/cursos/:id` — consulta un curso
* `PUT /api/cursos/:id` — edita código, nombre y descripción
* `PATCH /api/cursos/:id/estado` — cambia el estado a `ACTIVO` o `ARCHIVADO`

Las rutas protegidas necesitan el encabezado `Authorization: Bearer <token>`. Un estudiante solo puede consultar su propio `:id`; un administrador, cualquiera; un docente, solo los estudiantes de sus secciones.

### Eliminar un curso = archivarlo

El CRUD de cursos no borra registros: **eliminar es una baja lógica** (estado `ARCHIVADO`), para conservar el historial. Archivar se rechaza con `409` si el curso tiene ediciones planificadas, abiertas o en curso, y un curso archivado no se puede editar ni reactivar. La administración de cursos usa funciones de PostgreSQL y el administrador sale siempre del token, nunca del cuerpo de la petición.

### Datos reales y datos simulados

En los endpoints de estudiantes, algunos datos salen de la base de datos y otros son simulados todavía:

* **Reales:** nombre, apellido, email, rol, cursos activos, lista de cursos, actividades pendientes, nota promedio (`null` si aún no hay evaluaciones calificadas) y horas de estudio (tiempo dentro de las actividades).
* **Simulados:** porcentaje completado, módulos finalizados y pendientes, y el contenido de `/progress`.

El resumen incluye `datosReales` con la lista de campos que ya salen de la base. Cuando la respuesta incluye `"simulado": true`, parte de sus datos todavía no viene de la base. El formato no cambiará cuando se reemplacen.

### Recomendación

`POST /api/students/:id/recommendation` recibe `{ "topic": "nombre del tema" }`. El backend arma una interacción por cada intento calificado del estudiante en ese tema, la envía al motor adaptativo y responde `tema`, `accion`, `dificultad`, `recomendacion` y la evidencia `mastery`, `errors` y `attempts`. Si el estudiante no tiene intentos calificados en ese tema, responde `404`.

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
* Python 3 (solo para el endpoint de recomendación; ver "Motor adaptativo")

### 2. Crear la base de datos

Crear una base llamada `motor_adaptativo` y cargar en ella los scripts de la carpeta `database/`, **en este orden**, cada uno una sola vez:

1. `database/migrations/001_estructura_academica_inicial.sql`
2. `database/migrations/002_modulos_temas.sql`
3. `database/migrations/003_actividades_intentos_respuestas.sql`
4. `database/security/001_roles_permisos.sql`
5. `database/migrations/004_inscripcion_estudiantes.sql`
6. `database/migrations/005_crud_cursos.sql`
7. `database/seeds/datos_prueba.sql` y luego `database/seeds/datos_prueba_modulos_temas.sql`

Por ejemplo, desde la terminal (en una sola línea cada comando):

```
psql -U postgres -c "CREATE DATABASE motor_adaptativo;"
psql -U postgres -d motor_adaptativo -v ON_ERROR_STOP=1 -f database/migrations/001_estructura_academica_inicial.sql
```

y así con cada archivo. También se puede hacer desde pgAdmin con el Query Tool y la opción **Open File**. El seed inicial es obligatorio, porque inserta los roles (`ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR`) y el servidor no arranca si faltan. Más detalles en `database/README.md`.

### 3. Crear la contraseña del rol del backend

El backend se conecta con el rol limitado `plataforma_backend` (creado por el script de seguridad), no con `postgres`. Desde `psql`:

```
\password plataforma_backend
```

### 4. Crear el administrador de pruebas (para el CRUD de cursos)

Generar un hash bcrypt desde `backend`:

```
node -e "console.log(require('bcryptjs').hashSync('AdminDemo-2026!', 10))"
```

y ejecutar el seed por `psql`, que pedirá ese hash:

```
psql -X -U postgres -d motor_adaptativo -f database/seeds/datos_prueba_administrador.sql
```

Cuenta resultante: `administrador.demo@example.com`. La contraseña `AdminDemo-2026!` es pública y solo para desarrollo.

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
```

`CORS_ORIGIN` es la dirección del frontend que puede llamar a la API (por defecto, el servidor de Vite en `http://localhost:5173`). Opcionalmente, `PYTHON_EXECUTABLE` indica el Python del motor adaptativo. El archivo `.env` es personal y **no se sube a GitHub**. Cada integrante crea el suyo. Sin `JWT_SECRET` el servidor no arranca.

### 7. Encender el servidor

```
npm start
```

Debe aparecer `Servidor corriendo en http://localhost:3000`. Para comprobarlo, abrir http://localhost:3000/api/health.

## Motor adaptativo

El endpoint `POST /api/students/:id/recommendation` llama al motor de `adaptive-engine/` (Python) mediante `src/services/engineClient.js`. Para que funcione, en la raíz del repositorio:

```
python -m venv .venv
.venv\Scripts\pip install -r adaptive-engine\requirements.txt
```

También se puede indicar otro Python con la variable `PYTHON_EXECUTABLE`. El motor necesita al menos una interacción; si el estudiante no tiene intentos calificados en el tema, el backend responde `404` antes de llamarlo. Si Python no está disponible o falla, el endpoint responde `500`. Para ver una recomendación real hace falta un estudiante con intentos calificados (seed `datos_prueba_actividades_intentos.sql`).

## Seguridad

* Cabeceras de seguridad con `helmet`.
* Login y registro limitados a 10 peticiones por IP cada 15 minutos (`429`).
* JSON limitado a 100 KB (`413`).
* Conexión a PostgreSQL con el rol limitado `plataforma_backend`; la escritura de cursos, intentos e inscripciones se hace solo mediante funciones.
* Si un usuario tiene varios roles activos, se usa el de mayor jerarquía.

## Conexión con el frontend

El frontend puede llamar directo a `http://localhost:3000` (el backend permite el origen configurado en `CORS_ORIGIN`) o usar el proxy de Vite hacia el puerto 3000. El `id` que se usa en `/api/students/:id` es el `user.id` que devuelve el login. Las rutas de cursos responden `{ "success": true, "data": ... }`.

## Usuarios para probar

Los usuarios del seed inicial (`admin@example.com`, `docente@example.com`, `estudiante@example.com`) tienen un hash ficticio y **no pueden iniciar sesión**. Para probar:

* Estudiante: registrar un usuario con `POST /api/auth/register` y luego iniciar sesión.
* Administrador: `administrador.demo@example.com` (ver paso 4).

Para ver cursos reales en el resumen, el usuario necesita una inscripción en la tabla `inscripciones`.

## Problemas frecuentes

* **`password authentication failed`**: la contraseña de `DB_PASSWORD` no coincide con la de `DB_USER`.
* **`database "motor_adaptativo" does not exist`**: falta crear la base o el nombre de `DB_NAME` es distinto.
* **`Roles ausentes en la base de datos`**: no se cargó el seed inicial.
* **`Falta JWT_SECRET`**: el archivo `.env` no existe o no tiene esa variable.
* **`Cannot find module ...`**: falta ejecutar `npm install` dentro de `backend/`.
* **Puerto 3000 ocupado**: cambiar `PORT` en el `.env`.
* **Error de CORS en el navegador**: el origen del frontend no coincide con `CORS_ORIGIN`.
* **`429 Demasiados intentos`**: se superó el límite de login; reiniciar el servidor o esperar 15 minutos.
* **`403` en `/api/cursos`**: el usuario no es administrador.
* **`409` al archivar un curso**: tiene ediciones pendientes o ya está archivado.
* **`500` en recomendación**: Python no está instalado o falta el entorno `.venv`.
* **`permission denied` (42501)**: faltan las migraciones 004/005 o el script de seguridad.

## Documentación

El detalle de lo realizado en el backend está en `docs/backend.md`, en la raíz del repositorio.

## Responsable de este módulo

Porfirio Ramírez - Backend y API REST