# Backend

## Descripción

El Backend es la parte del proyecto encargada de recibir las peticiones del Frontend, aplicar la lógica del sistema y manejar los datos. Será una API REST desarrollada con Node.js y Express.js, siguiendo la arquitectura MVC.

Ubicación: `backend/`

## Estado actual

En esta primera etapa solo se dejó preparada la estructura inicial del módulo. Todavía no hay código, endpoints, conexión a base de datos ni autenticación. Estos elementos se irán incorporando en las próximas etapas.

## Tecnologías

Tecnologías actuales:

- Node.js v24.11.1
- npm 11.6.2
- Arquitectura MVC

Tecnologías previstas:

- Express.js
- PostgreSQL
- JWT para la autenticación

## Estructura

```
backend/
├── .gitignore
├── README.md
└── src/
    ├── config/
    ├── controllers/
    ├── models/
    ├── routes/
    ├── services/
    └── middlewares/
```

Cada carpeta dentro de `src/` tiene una responsabilidad definida:

- `config/`: configuración general, como variables de entorno y conexión a la base de datos.
- `controllers/`: lógica que responde a cada petición.
- `models/`: modelos de datos.
- `routes/`: definición de las rutas o endpoints de la API.
- `services/`: lógica de negocio reutilizable.
- `middlewares/`: funciones intermedias, como autenticación y validaciones.

Cada carpeta contiene un archivo `.gitkeep`, que sirve únicamente para que Git conserve las carpetas mientras estén vacías. Se podrá eliminar cuando la carpeta tenga archivos reales.

## Trabajo realizado

- Se verificó el entorno de desarrollo: Git, Node.js y npm.
- Se clonó el repositorio del grupo.
- Se creó la carpeta `backend/` con la estructura MVC dentro de `src/`.
- Se agregaron un `README.md` y un `.gitignore` propios del backend, igual que en los demás módulos.
- Se documentó lo realizado en este archivo.

## Integración prevista

El Backend será el punto de conexión entre los demás componentes del proyecto. La arquitectura prevista es:

Frontend → Backend / API → Base de datos → Motor adaptativo → Recomendaciones y adaptación

El Backend recibirá la información generada por la interacción del estudiante, como resultados, tiempo de estudio y progreso, la almacenará en la base de datos y la pondrá a disposición del motor adaptativo para generar recomendaciones.

## Próximos pasos

- Inicializar el proyecto Node.js con `npm init`.
- Instalar Express y crear el servidor base.
- Conectar la base de datos PostgreSQL.
- Implementar autenticación y los primeros endpoints.