# Backend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la API REST del proyecto, construida con Node.js y Express.js siguiendo la arquitectura MVC. Recibe las peticiones del frontend, aplica la lógica del sistema y maneja los datos en PostgreSQL. Será también el puente hacia el motor adaptativo en Python.

Por ahora el backend cubre la autenticación: registro, inicio de sesión con token JWT y control de acceso por roles. Los endpoints de estudiantes y la integración con el motor adaptativo se incorporarán en las próximas etapas.

## Qué contiene esta carpeta

Dentro de `src/` hay una carpeta por cada responsabilidad del backend:

* `config/` — configuración (variables de entorno, conexión a PostgreSQL, roles, permisos, Swagger)
* `controllers/` — reciben la petición y devuelven la respuesta
* `dtos/` — validación de los datos de entrada y forma de los datos de salida
* `errors/` — errores propios de la aplicación
* `middlewares/` — autenticación, autorización, validación y manejo de errores
* `models/` — consultas a la base de datos
* `routes/` — definición de los endpoints de la API
* `services/` — lógica de negocio
* `docs/` — especificación OpenAPI de la API

El archivo `src/app.js` arma la aplicación y `src/server.js` la enciende.

## Endpoints disponibles

* `GET /api/health` — comprueba que el backend funciona
* `POST /api/auth/register` — registra un estudiante
* `POST /api/auth/login` — inicia sesión y devuelve un token JWT
* `GET /api/auth/me` — datos del usuario autenticado (requiere token)

Las rutas protegidas necesitan el encabezado `Authorization: Bearer <token>`.

## Documentación interactiva (Swagger)

Con el servidor encendido, abrir en el navegador:

http://localhost:3000/api/docs

Desde ahí se pueden probar todos los endpoints. Para las rutas protegidas: hacer login, copiar el `token`, pulsar **Authorize** y pegarlo. La especificación está en `src/docs/openapi.yaml`.

## Tecnologías

Node.js, Express.js, PostgreSQL (`pg`), JWT (`jsonwebtoken`), `bcryptjs` para cifrar contraseñas, Zod para validar los DTOs, `dotenv` para las variables de entorno y Swagger UI para la documentación.

## Cómo correrlo

### 1. Requisitos

* Node.js y npm
* PostgreSQL instalado y funcionando (puerto 5432 por defecto)

### 2. Crear la base de datos

Crear una base llamada `motor_adaptativo` y cargar en ella, en este orden, el script de tablas y el script de datos de prueba (los de la carpeta `database/`). Por ejemplo, desde la terminal:

```
psql -U postgres -c "CREATE DATABASE motor_adaptativo;"
psql -U postgres -d motor_adaptativo -f ruta\al\esquema.sql
psql -U postgres -d motor_adaptativo -f ruta\al\seed.sql
```

También se puede hacer desde pgAdmin con el Query Tool. Cada script se ejecuta una sola vez. El seed es obligatorio, porque inserta los roles (`ESTUDIANTE`, `DOCENTE`, `ADMINISTRADOR`) y el servidor no arranca si faltan.

### 3. Instalar dependencias

```
cd backend
npm install
```

### 4. Configurar las variables de entorno

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
DB_USER=postgres
DB_PASSWORD=la_contraseña_de_tu_postgres
JWT_SECRET=una-clave-larga-y-secreta
```

El archivo `.env` es personal y **no se sube a GitHub**. Cada integrante crea el suyo con su propia contraseña de PostgreSQL. Sin `JWT_SECRET` el servidor no arranca.

### 5. Encender el servidor

```
npm start
```

Debe aparecer `Servidor corriendo en http://localhost:3000`. Para comprobarlo, abrir http://localhost:3000/api/health.

## Usuarios para probar

Los usuarios del seed (`admin@example.com`, `docente@example.com`, `estudiante@example.com`) tienen un hash ficticio y **no pueden iniciar sesión**. Para probar el login, registrar un usuario con `POST /api/auth/register` (desde Swagger) y luego iniciar sesión con él.

## Problemas frecuentes

* **`password authentication failed`**: la contraseña de `DB_PASSWORD` no coincide con la de tu PostgreSQL.
* **`database "motor_adaptativo" does not exist`**: falta crear la base o el nombre de `DB_NAME` es distinto.
* **`Roles ausentes en la base de datos`**: no se cargó el seed.
* **`Falta JWT_SECRET`**: el archivo `.env` no existe o no tiene esa variable.
* **`Cannot find module ...`**: falta ejecutar `npm install` dentro de `backend/`.
* **Puerto 3000 ocupado**: cambiar `PORT` en el `.env`.

## Documentación

El detalle de lo realizado en el backend está en `docs/backend.md`, en la raíz del repositorio.

## Responsable de este módulo

Backend y API REST