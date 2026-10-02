# Backend — Motor de Aprendizaje Adaptativo

Esta carpeta contiene la API REST del proyecto, construida con Node.js y Express.js siguiendo la arquitectura MVC. Es la parte que se encargará de recibir las peticiones del frontend, aplicar la lógica del sistema y manejar los datos: autenticación de estudiantes, cursos, resultados de evaluaciones y progreso.

Por ahora no hay código a propósito. Lo que se dejó listo en esta primera entrega fue la estructura de carpetas del proyecto y su documentación, para que en las próximas etapas solo haga falta ir agregando controladores, modelos y rutas dentro de cada carpeta.

## Qué contiene esta carpeta

Dentro de `src/` hay una carpeta por cada responsabilidad del backend:

* `config/` — configuración general (variables de entorno, conexión a la base de datos)
* `controllers/` — lógica que responde a cada petición
* `models/` — modelos de datos
* `routes/` — definición de las rutas o endpoints de la API
* `services/` — lógica de negocio reutilizable
* `middlewares/` — funciones intermedias (autenticación, validaciones)

Cada carpeta tiene un archivo `.gitkeep`, que sirve solo para que Git conserve la carpeta mientras esté vacía. Se puede borrar cuando la carpeta tenga archivos reales.

## Tecnologías

Node.js y Express.js con arquitectura MVC. En etapas siguientes se incorporarán PostgreSQL como base de datos y JWT para la autenticación.

## Cómo correrlo

Todavía no es posible, porque el proyecto aún no tiene `package.json` ni servidor. Cuando se inicialice Node.js y se instale Express, los pasos serán:

```
cd backend
npm install
npm start
```

## Documentación

El detalle de lo realizado en el backend está en `docs/backend.md`, en la raíz del repositorio.

## Responsable de este módulo

Backend y estructura de la API