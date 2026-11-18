# Reporte de pruebas — Motor de Aprendizaje Adaptativo — Grupo 4

**Fecha de ejecución:** 17 de noviembre de 2026 a las 7:52 p. m. · **Duración:** 188 s · **Casos:** 130 · **Verificaciones automatizadas:** 202

> Archivo generado automáticamente con `npm test` (carpeta `tests/`). No editarlo a mano.

## Resumen

| Estado | Casos | % |
|---|---:|---:|
| ✅ APROBADO | 118 | 91 % |
| ❌ FALLIDO | 10 | 8 % |
| ⛔ BLOQUEADO | 2 | 2 % |
| **Total** | **130** | 100 % |

**Criterio:** un caso es BLOQUEADO cuando no puede ejecutarse por falta de integración (endpoint o pantalla pendiente). No se cuenta como fallo.

## Trazabilidad por requisito

| Requisito | Descripción | ✅ | ❌ | ⛔ | Casos |
|---|---|---:|---:|---:|---|
| RF-01 | Autenticación: registro, inicio y cierre de sesión | 16 | 1 | 0 | CP-LOG-01, CP-LOG-02, CP-LOG-03, CP-LOG-04, CP-LOG-05, CP-LOG-06, CP-LOG-07, CP-LOG-08, CP-LOG-09, CP-LOG-10, CP-LOG-11, CP-LOG-12, CP-UI-01, CP-UI-02, CP-UI-03, CP-UI-06, CP-UI-08 |
| RF-02 | Roles y permisos (estudiante, docente, administrador) | 9 | 0 | 0 | CP-ROL-01, CP-ROL-02, CP-ROL-03, CP-ROL-04, CP-ROL-05, CP-CRUD-04, CP-BE-06, CP-UI-05, CP-UI-18 |
| RF-03 | Gestión de usuarios | 3 | 0 | 2 | CP-CRUD-01, CP-CRUD-02, CP-CRUD-05, CP-CRUD-06, CP-CRUD-07 |
| RF-04 | CRUD de cursos (administrador) | 7 | 0 | 0 | CP-CUR-01, CP-CUR-02, CP-CUR-03, CP-CUR-04, CP-CUR-05, CP-CUR-06, CP-UI-16 |
| RF-05 | CRUD de módulos y temas (docente/administrador) | 10 | 0 | 0 | CP-MT-01, CP-MT-02, CP-MT-03, CP-MT-04, CP-MT-05, CP-MT-06, CP-MT-07, CP-MT-08, CP-UI-17, CP-UI-19 |
| RF-06 | Actividades, intentos y resultados del estudiante | 1 | 0 | 0 | CP-CRUD-09 |
| RF-07 | Motor adaptativo: recomendaciones según desempeño | 29 | 0 | 0 | CP-MOTD-01, CP-MOTD-02, CP-MOTD-03, CP-MOTD-04, CP-MOTD-05, CP-MOTD-06, CP-MOT-01, CP-MOT-02, CP-MOT-03, CP-MOT-04, CP-MOT-05, CP-MOT-06, CP-MOT-07, CP-MOT-08, CP-MOT-09, CP-MOT-10, CP-MOT-11, CP-ADP-01, CP-ADP-02, CP-ADP-03, CP-ADP-04, CP-ADP-05, CP-ADP-06, CP-ADP-07, CP-ADP-08, CP-ADP-09, CP-UI-10, CP-UI-11, CP-UI-12 |
| RF-08 | Dashboard y progreso del estudiante | 4 | 0 | 0 | CP-CRUD-08, CP-UI-09, CP-UI-13, CP-UI-20 |
| RF-09 | Persistencia de datos en PostgreSQL | 4 | 0 | 0 | CP-PER-01, CP-PER-02, CP-PER-03, CP-PER-04 |
| RNF-01 | Seguridad (tokens, contraseñas, límites, datos sensibles) | 4 | 0 | 0 | CP-SEG-01, CP-SEG-02, CP-BE-03, CP-BE-05 |
| RNF-02 | Validación de datos y manejo de errores | 19 | 9 | 0 | CP-CRUD-03, CP-VAL-01, CP-VAL-02, CP-VAL-03, CP-VAL-04, CP-VAL-05, CP-VAL-06, CP-VAL-07, CP-VAL-08, CP-VAL-09, CP-VAL-10, CP-VAL-11, CP-VAL-12, CP-VAL-13, CP-VAL-14, CP-VAL-15, CP-BE-01, CP-BE-02, CP-BE-04, CP-BE-07, CP-BE-09, CP-BE-10, CP-FE-01, CP-FE-02, CP-FE-03, CP-UI-04, CP-UI-14, CP-UI-15 |
| RNF-03 | Usabilidad y navegación del frontend | 1 | 0 | 0 | CP-UI-07 |
| RNF-04 | Integridad y reglas de la base de datos | 10 | 0 | 0 | CP-BD-01, CP-BD-02, CP-BD-03, CP-BD-04, CP-BD-05, CP-BD-06, CP-BD-07, CP-BD-08, CP-BD-09, CP-BD-10 |
| RNF-05 | Documentación de la API (OpenAPI) | 1 | 0 | 0 | CP-BE-08 |

## Por módulo y responsable

| Módulo | Responsable | ✅ | ❌ | ⛔ | Total |
|---|---|---:|---:|---:|---:|
| Backend / API | Porfirio Ramírez | 51 | 4 | 2 | 57 |
| Base de datos | Jeison Rosario | 11 | 0 | 0 | 11 |
| Motor adaptativo | Daniel Beltre | 34 | 6 | 0 | 40 |
| Frontend | Yuleidy De Los Santos | 22 | 0 | 0 | 22 |

## Re-pruebas de incidencias corregidas

| Incidencia | Título | Estado | Resultado de la re-prueba |
|---|---|---|---|
| INC-01 | El backend no tiene CORS: el login real desde el navegador falla | Verificada | CP-UI-01: APROBADO |
| INC-08 | Dashboard y Progreso en modo real usan endpoints que no existen | Verificada | CP-CRUD-08: APROBADO |
| INC-10 | Las operaciones académicas de la base de datos no están expuestas por HTTP | Verificada | CP-CRUD-09: APROBADO |
| INC-11 | El backend todavía no llama al motor adaptativo (POST /api/adaptive/analyze) | Verificada | CP-MOT-11: APROBADO, CP-ADP-01: APROBADO, CP-ADP-02: APROBADO, CP-ADP-03: APROBADO |
| INC-12 | Los ejercicios no envían tiempo, intentos ni errores al backend | Verificada | CP-UI-11: APROBADO |
| INC-15 | El Dashboard se rompe cuando no hay recomendación (estudiante sin intentos o motor caído) | Verificada | CP-UI-13: APROBADO, CP-UI-20: APROBADO |
| INC-16 | El Dashboard real se marca como 'Datos de ejemplo' y la actividad reciente es simulada | Verificada | CP-UI-09: APROBADO |
| INC-17 | El docente debe escribir el ID numérico del curso para gestionar contenido | Verificada | CP-UI-19: APROBADO |

## Casos fallidos

| Caso | Requisito | Título | Incidencia | Responsable | Resultado real |
|---|---|---|---|---|---|
| [CP-LOG-06](#cp-log-06) | RF-01 | Login con JSON mal formado | INC-02 | Porfirio Ramírez | 400 { success:false, message:'Unexpected end of JSON input' } (ver INC-02) |
| [CP-VAL-07](#cp-val-07) | RNF-02 | Falta student_id o topic | INC-05 | Daniel Beltre | KeyError('topic'). (ver INC-05) |
| [CP-VAL-09](#cp-val-09) | RNF-02 | Valores infinitos (Infinity) o NaN | INC-04 | Daniel Beltre | Código 0 y salida con 'Infinity'. (ver INC-04) |
| [CP-VAL-10](#cp-val-10) | RNF-02 | Valores booleanos en campos numéricos | INC-06 | Daniel Beltre | Se procesa con promedio 1.0 y acción reinforce_topic. (ver INC-06) |
| [CP-VAL-11](#cp-val-11) | RNF-02 | Conteos con decimales (errores, intentos, repeticiones, navegación) | INC-07 | Daniel Beltre | total_errors = 2. (ver INC-07) |
| [CP-VAL-14](#cp-val-14) | RNF-02 | CLI: JSON válido cuya raíz no es un objeto | INC-03 | Daniel Beltre | Traceback de Python: AttributeError: 'list' object has no attribute 'get'. (ver INC-03) |
| [CP-VAL-15](#cp-val-15) | RNF-02 | CLI: Infinity en la entrada no rompe el JSON de salida | INC-04 | Daniel Beltre | Código 0 y salida con 'Infinity'. (ver INC-04) |
| [CP-BE-07](#cp-be-07) | RNF-02 | errorHandler traduce cada tipo de error | INC-02 | Porfirio Ramírez | 400 { success:false, message:'Unexpected end of JSON input' } (ver INC-02) |
| [CP-BE-09](#cp-be-09) | RNF-02 | Health check y ruta inexistente | INC-14 | Porfirio Ramírez | 401. (ver INC-14) |
| [CP-BE-10](#cp-be-10) | RNF-02 | Cuerpo demasiado grande (413) | INC-13 | Porfirio Ramírez | 413 'request entity too large'. (ver INC-13) |

## Casos bloqueados

| Caso | Título | Motivo del bloqueo | Incidencia |
|---|---|---|---|
| [CP-CRUD-06](#cp-crud-06) | Actualizar usuario / cambiar rol | BLOQUEADO: PATCH /api/users/:id/role no está implementado en el backend (404). | INC-09 |
| [CP-CRUD-07](#cp-crud-07) | Eliminar / desactivar usuario | BLOQUEADO: DELETE /api/users/:id no está implementado en el backend (404). | INC-09 |

## Incidencias

Detalle completo con pasos de reproducción en [`tests/INCIDENCIAS.md`](../INCIDENCIAS.md).

| ID | Título | Tipo | Severidad | Responsable | Estado |
|---|---|---|---|---|---|
| INC-01 | El backend no tiene CORS: el login real desde el navegador falla | Defecto | Alta | Porfirio Ramírez | Verificada |
| INC-02 | JSON mal formado devuelve un mensaje técnico en inglés en vez de 'JSON inválido' | Defecto | Baja | Porfirio Ramírez | Abierta |
| INC-03 | Motor: si el JSON no es un objeto, Python termina con traceback y no con JSON de error | Defecto | Media | Daniel Beltre | Abierta |
| INC-04 | Motor: acepta Infinity y devuelve un JSON que Node no puede leer | Defecto | Media | Daniel Beltre | Abierta |
| INC-05 | Motor: falta de student_id o topic produce KeyError sin mensaje claro | Defecto | Baja | Daniel Beltre | Abierta |
| INC-06 | Motor: acepta true/false como números (true = 1 %) | Defecto | Baja | Daniel Beltre | Abierta |
| INC-07 | Motor: los conteos con decimales se truncan en silencio | Defecto | Baja | Daniel Beltre | Abierta |
| INC-08 | Dashboard y Progreso en modo real usan endpoints que no existen | Integración pendiente | Alta | Porfirio Ramírez (endpoints) y Yuleidy De Los Santos (pantalla) | Verificada |
| INC-09 | No hay endpoints para listar, actualizar, cambiar el rol ni eliminar usuarios | Integración pendiente | Media | Porfirio Ramírez | Pendiente de desarrollo |
| INC-10 | Las operaciones académicas de la base de datos no están expuestas por HTTP | Integración pendiente | Media | Porfirio Ramírez y Jeison Rosario | Verificada |
| INC-11 | El backend todavía no llama al motor adaptativo (POST /api/adaptive/analyze) | Integración pendiente | Alta | Porfirio Ramírez y Daniel Beltre | Verificada |
| INC-12 | Los ejercicios no envían tiempo, intentos ni errores al backend | Integración pendiente | Media | Yuleidy De Los Santos y Porfirio Ramírez | Verificada |
| INC-13 | Cuerpo demasiado grande responde en inglés y su rama 413 nunca se ejecuta | Defecto | Baja | Porfirio Ramírez | Abierta |
| INC-14 | Rutas inexistentes bajo /api responden 401 en lugar de 404 | Defecto | Baja | Porfirio Ramírez | Abierta |
| INC-15 | El Dashboard se rompe cuando no hay recomendación (estudiante sin intentos o motor caído) | Defecto | Alta | Yuleidy De Los Santos | Verificada |
| INC-16 | El Dashboard real se marca como 'Datos de ejemplo' y la actividad reciente es simulada | Defecto | Media | Yuleidy De Los Santos | Verificada |
| INC-17 | El docente debe escribir el ID numérico del curso para gestionar contenido | Integración pendiente | Media | Yuleidy De Los Santos | Verificada |

## Detalle de todos los casos

### CP-LOG-01

**✅ APROBADO** — Login con credenciales válidas

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con la cuenta demo del seed de integración.
- **Datos:** estudiante.demo@example.com / DemoEquipo-2026!
- **Resultado esperado:** 200, success=true, token JWT válido (id y rol), usuario con rol ESTUDIANTE y sin passwordHash.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-02

**✅ APROBADO** — Login sin distinguir mayúsculas y con espacios en el correo

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con el correo en mayúsculas y con espacios alrededor.
- **Datos:** '  ESTUDIANTE.DEMO@EXAMPLE.COM  '
- **Resultado esperado:** 200: el correo se normaliza (trim + lower).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-03

**✅ APROBADO** — Login con contraseña incorrecta

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con un correo existente y contraseña errónea.
- **Datos:** estudiante.demo@example.com / ClaveIncorrecta1
- **Resultado esperado:** 401 'Credenciales inválidas', sin token.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-04

**✅ APROBADO** — Login con correo no registrado

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con un correo inexistente.
- **Datos:** no.existe@example.com
- **Resultado esperado:** 401 con el MISMO mensaje que contraseña incorrecta (no revela si el correo existe).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-05

**✅ APROBADO** — Login con campos vacíos o ausentes

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con email y password vacíos, y con cuerpo {}.
- **Datos:** {email:'', password:''} y {}
- **Resultado esperado:** 400 'Datos inválidos' con details por campo.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-06

**❌ FALLIDO** — Login con JSON mal formado

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con un cuerpo que no es JSON válido.
- **Datos:** {"email": 
- **Resultado esperado:** 400 'JSON inválido' (no 500).
- **Resultado real:** 400 { success:false, message:'Unexpected end of JSON input' } (ver INC-02)
- **Detalle técnico:** 1 de 1 verificaciones fallaron. Expected values to be strictly equal:+ actual - expected+ 'Unexpected end of JSON input'- 'JSON inválido'
- **Incidencias:** INC-02
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-07

**✅ APROBADO** — Login con tipos de datos incorrectos

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con password numérico, email como objeto y cuerpo como arreglo.
- **Datos:** {password: 12345678}, {email:{}}, []
- **Resultado esperado:** 400 en todos los casos (no 500).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-08

**✅ APROBADO** — Login de usuario con hash ficticio del seed

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con estudiante@example.com (password_hash = HASH_FICTICIO_NO_USAR).
- **Datos:** estudiante@example.com / estudiante123
- **Resultado esperado:** 401 controlado (no 500).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-09

**✅ APROBADO** — Login de cuenta desactivada

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar un usuario, desactivarlo en BD (activo=false) e intentar login; probar también /me con su token previo.
- **Datos:** Usuario QA temporal
- **Resultado esperado:** Login 401; /me con token emitido antes de desactivar → 401.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-10

**✅ APROBADO** — Consultar /api/auth/me con token válido

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Login y luego GET /api/auth/me con Authorization: Bearer <token>.
- **Datos:** Token de la cuenta demo
- **Resultado esperado:** 200 con los datos del usuario autenticado (sin passwordHash).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-11

**✅ APROBADO** — Acceso a /me sin token, con token alterado o vencido

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/auth/me sin cabecera, con esquema distinto de Bearer, con firma alterada, con otro secreto y con token expirado.
- **Datos:** Tokens generados en la prueba
- **Resultado esperado:** 401 en todos los casos.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-LOG-12

**✅ APROBADO** — Intento de inyección SQL en el login

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Login · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con cargas típicas de inyección en email y password.
- **Datos:** ' OR '1'='1' -- , admin@example.com'--
- **Resultado esperado:** 401 (las consultas son parametrizadas); nunca 200 ni 500.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ROL-01

**✅ APROBADO** — Cada cuenta demo inicia sesión con su rol

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Roles y permisos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Login y /me con estudiante, docente y administrador demo.
- **Datos:** Cuentas demo de los seeds
- **Resultado esperado:** Rol ESTUDIANTE, DOCENTE y ADMINISTRADOR respectivamente.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ROL-02

**✅ APROBADO** — Matriz de permisos por rol en rutas protegidas

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Roles y permisos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Llamar /cursos, /cursos-administrables, /modulos y /mis-cursos con cada rol y sin token.
- **Datos:** Tabla de rutas × roles
- **Resultado esperado:** Estudiante: solo /mis-cursos. Docente: contenido y cursos administrables. Administrador: cursos y contenido. Sin token: 401.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ROL-03

**✅ APROBADO** — Acceso a los datos de un estudiante según el rol

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Roles y permisos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/students/:id con el propio estudiante, otro estudiante, un docente ajeno y el administrador.
- **Datos:** Cuenta demo y estudiante QA
- **Resultado esperado:** 200 propio, 403 otro estudiante, 403 docente sin relación, 200 administrador, 404 si el id no es estudiante.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ROL-04

**✅ APROBADO** — El docente solo edita el contenido de sus cursos

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Roles y permisos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Docente demo crea un módulo en CALC-PRUEBA (no es editor).
- **Datos:** docente.demo@example.com
- **Resultado esperado:** Solo ve DEMO-006 como administrable; 403 y nada guardado en la base.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ROL-05

**✅ APROBADO** — Usuario con varios roles recibe el de mayor jerarquía

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Roles y permisos · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Asignar DOCENTE a un estudiante QA e iniciar sesión.
- **Datos:** Estudiante QA + rol DOCENTE
- **Resultado esperado:** El token y la respuesta tienen rol DOCENTE (ADMINISTRADOR > DOCENTE > ESTUDIANTE).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-SEG-01

**✅ APROBADO** — Límite de intentos de login

- **Requisito:** RNF-01 — Seguridad (tokens, contraseñas, límites, datos sensibles)
- **Módulo / área:** Backend / API · Seguridad · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** 11 intentos de login fallidos seguidos desde la misma IP.
- **Datos:** Credenciales incorrectas
- **Resultado esperado:** Los 10 primeros 401; el 11.º 429 'Demasiados intentos'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-SEG-02

**✅ APROBADO** — Las respuestas no exponen datos sensibles

- **Requisito:** RNF-01 — Seguridad (tokens, contraseñas, límites, datos sensibles)
- **Módulo / área:** Backend / API · Seguridad · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Revisar el resumen del estudiante y una respuesta de error.
- **Datos:** Cuenta demo
- **Resultado esperado:** Sin contraseñas, hashes, SQL ni trazas internas.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-01

**✅ APROBADO** — Crear (registro) con datos válidos

- **Requisito:** RF-03 — Gestión de usuarios
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/register con nombre, apellido, email y password válidos.
- **Datos:** Usuario QA con correo único
- **Resultado esperado:** 201, usuario con id, rol ESTUDIANTE y sin passwordHash.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-02

**✅ APROBADO** — Crear con correo duplicado (otra capitalización)

- **Requisito:** RF-03 — Gestión de usuarios
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar dos veces el mismo correo; la segunda en mayúsculas.
- **Datos:** qa.xxx@example.com y QA.XXX@EXAMPLE.COM
- **Resultado esperado:** 409 'Ya existe un usuario con ese email'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-03

**✅ APROBADO** — Crear con datos inválidos

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar con email mal formado, contraseña de 7 y de 73 caracteres, nombre vacío y apellido de 51 caracteres.
- **Datos:** Varias combinaciones
- **Resultado esperado:** 400 'Datos inválidos' con el campo señalado en details.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-04

**✅ APROBADO** — Registro no permite escalar privilegios

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar enviando rol: 'ADMINISTRADOR' en el cuerpo.
- **Datos:** {..., rol:'ADMINISTRADOR'}
- **Resultado esperado:** 201 con rol ESTUDIANTE; el campo rol se ignora.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-05

**✅ APROBADO** — Leer el usuario recién creado

- **Requisito:** RF-03 — Gestión de usuarios
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar, iniciar sesión y consultar GET /api/auth/me.
- **Datos:** Usuario QA
- **Resultado esperado:** 200 con los mismos nombre, apellido y email registrados.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-06

**⛔ BLOQUEADO** — Actualizar usuario / cambiar rol

- **Requisito:** RF-03 — Gestión de usuarios
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** PATCH /api/users/:id/role (existe changeRoleDto y el permiso users:change-role, pero no la ruta).
- **Datos:** {rol:'DOCENTE'} con token de administrador
- **Resultado esperado:** Endpoint disponible. Si devuelve 404 → BLOQUEADO (no implementado).
- **Resultado real:** BLOQUEADO: PATCH /api/users/:id/role no está implementado en el backend (404).
- **Incidencias:** INC-09
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-07

**⛔ BLOQUEADO** — Eliminar / desactivar usuario

- **Requisito:** RF-03 — Gestión de usuarios
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Baja
- **Responsable:** Porfirio Ramírez
- **Pasos:** DELETE /api/users/:id.
- **Datos:** Usuario QA
- **Resultado esperado:** Endpoint disponible. Si devuelve 404 → BLOQUEADO (no implementado).
- **Resultado real:** BLOQUEADO: DELETE /api/users/:id no está implementado en el backend (404).
- **Incidencias:** INC-09
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-08

**✅ APROBADO** — Consultar resumen y progreso de un estudiante

- **Requisito:** RF-08 — Dashboard y progreso del estudiante
- **Módulo / área:** Backend / API · CRUD usuarios · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/students/:id y /progress con el token del propio estudiante; luego con el token de otro estudiante; y GET /api/students.
- **Datos:** Cuenta demo y un estudiante QA
- **Resultado esperado:** 200 para el propio estudiante con simulado=false; 403 para otro estudiante; el listado general aún no existe (404, ver INC-09).
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-08
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CRUD-09

**✅ APROBADO** — Flujo académico por HTTP: inscripciones, actividades, intento, respuestas y entrega

- **Requisito:** RF-06 — Actividades, intentos y resultados del estudiante
- **Módulo / área:** Backend / API · CRUD académico · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /mis-cursos, /modulos, /temas y /actividades; POST intento; PUT opciones correctas; POST entrega; GET resultados.
- **Datos:** Cuenta demo, curso DEMO-SQL-007, evaluación de SQL JOIN
- **Resultado esperado:** 201 al iniciar (sin exponer respuestas correctas), 100 % al entregar, intento CALIFICADO en PostgreSQL y visible en resultados.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-10
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-01

**✅ APROBADO** — Crear curso y guardarlo en PostgreSQL

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/cursos como administrador y consultar la tabla cursos.
- **Datos:** Código QA-xxxx
- **Resultado esperado:** 201; fila en cursos con creado_por = administrador.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-02

**✅ APROBADO** — Listar, filtrar y consultar cursos

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/cursos, con filtro de estado y por id.
- **Datos:** Curso QA
- **Resultado esperado:** El curso aparece; el filtro respeta el estado; GET por id 200.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-03

**✅ APROBADO** — Actualizar curso y persistir el cambio

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** PUT /api/cursos/:id y consultar la tabla.
- **Datos:** Nombre y descripción nuevos
- **Resultado esperado:** 200 y los nuevos valores guardados.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-04

**✅ APROBADO** — Archivar curso (baja lógica) y bloquear cambios posteriores

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** PATCH estado ARCHIVADO; luego intentar reactivar y editar.
- **Datos:** Curso QA
- **Resultado esperado:** 200 al archivar y el registro se conserva; reactivar y editar → 409 (regla documentada).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-05

**✅ APROBADO** — Código de curso duplicado

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Crear un curso con un código existente.
- **Datos:** Código QA-xxxx
- **Resultado esperado:** 409 y no se crea un segundo registro.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-CUR-06

**✅ APROBADO** — Datos inválidos e ids inexistentes en cursos

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Backend / API · CRUD cursos · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Código vacío, nombre de 151, descripción en blanco, estado inválido, id 'abc', id inexistente, paginación y filtro inválidos.
- **Datos:** Tabla de casos
- **Resultado esperado:** 400 en datos inválidos, 404 en id inexistente.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-01

**✅ APROBADO** — Crear módulo (BORRADOR por defecto) y guardarlo

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/modulos como docente en DEMO-006.
- **Datos:** Módulo QA
- **Resultado esperado:** 201, estado BORRADOR, fila en modulos con el docente como autor.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-02

**✅ APROBADO** — Listar y actualizar módulo

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/modulos?cursoId y PUT /api/modulos/:id sin estado.
- **Datos:** Módulo QA
- **Resultado esperado:** Aparece en la lista; el cambio se guarda y conserva el estado.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-03

**✅ APROBADO** — Orden de módulo duplicado

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Crear otro módulo con el mismo orden en el mismo curso.
- **Datos:** Orden repetido
- **Resultado esperado:** 409.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-04

**✅ APROBADO** — Crear, listar, actualizar y publicar tema

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST, GET, PUT y PATCH estado de un tema.
- **Datos:** Tema QA
- **Resultado esperado:** Cambios guardados en la tabla temas; estado PUBLICADO.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-05

**✅ APROBADO** — Cambiar estado del módulo

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** PATCH estado PUBLICADO, ARCHIVADO y BORRADOR.
- **Datos:** Módulo QA
- **Resultado esperado:** 200 y cada estado guardado.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-06

**✅ APROBADO** — Reglas de eliminación de temas y módulos

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Eliminar un módulo con temas; pasar el tema a BORRADOR y eliminarlo; eliminar el módulo.
- **Datos:** Módulo y tema QA
- **Resultado esperado:** 409 con temas dependientes; luego 200 y ambos desaparecen de la base.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-07

**✅ APROBADO** — Datos inválidos e ids inexistentes en módulos y temas

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Nombre vacío, orden 0 o texto, estado inválido, descripción de 1001, ids inválidos o inexistentes.
- **Datos:** Tabla de casos
- **Resultado esperado:** 400 en datos inválidos, 404 en ids inexistentes.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MT-08

**✅ APROBADO** — El estudiante solo ve contenido publicado

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Backend / API · CRUD módulos y temas · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** El administrador crea un módulo BORRADOR en DEMO-SQL-007 y luego lo publica.
- **Datos:** Módulo QA
- **Resultado esperado:** Oculto para el estudiante en BORRADOR; visible al publicarlo.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-PER-01

**✅ APROBADO** — El registro se guarda en PostgreSQL de forma segura

- **Requisito:** RF-09 — Persistencia de datos en PostgreSQL
- **Módulo / área:** Backend / API · Persistencia · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar por la API y consultar directamente usuarios y usuario_roles.
- **Datos:** Usuario QA
- **Resultado esperado:** 1 fila en usuarios con hash bcrypt (no la contraseña en texto plano) y 1 rol ESTUDIANTE activo.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-PER-02

**✅ APROBADO** — Los datos sobreviven a un reinicio del backend

- **Requisito:** RF-09 — Persistencia de datos en PostgreSQL
- **Módulo / área:** Backend / API · Persistencia · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Registrar un usuario, cerrar la conexión, iniciar un proceso NUEVO con backend/src/server.js e iniciar sesión.
- **Datos:** Usuario QA
- **Resultado esperado:** El servidor nuevo arranca (checkRoles OK) y el login devuelve 200.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-PER-03

**✅ APROBADO** — Un registro rechazado no deja datos a medias

- **Requisito:** RF-09 — Persistencia de datos en PostgreSQL
- **Módulo / área:** Backend / API · Persistencia · Integración · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Contar filas, provocar un duplicado y datos inválidos, volver a contar.
- **Datos:** Correo existente
- **Resultado esperado:** El número de usuarios y de usuario_roles no cambia.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-PER-04

**✅ APROBADO** — Resultados persistidos del seed de integración

- **Requisito:** RF-09 — Persistencia de datos en PostgreSQL
- **Módulo / área:** Base de datos · Persistencia · Integración · prioridad Media
- **Responsable:** Jeison Rosario
- **Pasos:** Consultar resultados_actividades para la cuenta demo con el rol del backend.
- **Datos:** Curso DEMO-003
- **Resultado esperado:** Práctica: promedio 50, nota académica NULL. Evaluación: promedio 100, nota 100.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-01

**✅ APROBADO** — Regresión de la migración 003 (actividades, intentos, resultados, permisos)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL existentes · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_003.sql sobre la base de QA.
- **Datos:** Seeds iniciales
- **Resultado esperado:** Termina con 'PRUEBAS 003 COMPLETADAS' y ROLLBACK.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-02

**✅ APROBADO** — Pruebas de la migración 004 (inscripción)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL existentes · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_004.sql.
- **Datos:** Datos propios del script
- **Resultado esperado:** Avisos OK 1–7 y 'PRUEBAS 004 COMPLETADAS'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-03

**✅ APROBADO** — Restricciones de integridad (5 rechazos esperados)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL existentes · SQL · prioridad Media
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_restricciones.sql (cada bloque debe fallar).
- **Datos:** Seeds iniciales
- **Resultado esperado:** Exactamente 5 errores de restricción, uno por bloque.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-04

**✅ APROBADO** — Orden de módulos y temas (4 rechazos esperados)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL existentes · SQL · prioridad Media
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_temas_modulos.sql.
- **Datos:** Seeds de módulos y temas
- **Resultado esperado:** Exactamente 4 errores, uno por bloque.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-05

**✅ APROBADO** — Permisos del rol plataforma_backend

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL existentes · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_permisos.sql.
- **Datos:** —
- **Resultado esperado:** Sin INSERT en intentos, sin UPDATE en respuestas, sin DELETE en selecciones; con EXECUTE en iniciar_intento.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-06

**✅ APROBADO** — Pruebas de la migración 005 (CRUD de cursos)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL del equipo · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_005.sql
- **Datos:** Fixtures propios
- **Resultado esperado:** 'PRUEBAS 005 COMPLETADAS' y ROLLBACK.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-07

**✅ APROBADO** — Pruebas de la migración 006 (módulos y temas)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL del equipo · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_006.sql
- **Datos:** Fixtures propios
- **Resultado esperado:** 'PRUEBAS 006 COMPLETADAS' y ROLLBACK.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-08

**✅ APROBADO** — Pruebas de la migración 007 (lectura del estudiante)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL del equipo · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_007.sql
- **Datos:** Fixtures propios
- **Resultado esperado:** 'PRUEBAS 007 COMPLETADAS' y ROLLBACK.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-09

**✅ APROBADO** — Pruebas de la migración 008 (integración y motor)

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL del equipo · SQL · prioridad Alta
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_migracion_008.sql
- **Datos:** Seeds DEMO-SQL-007 y DEMO-006
- **Resultado esperado:** 'PRUEBAS 008 COMPLETADAS' y ROLLBACK.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BD-10

**✅ APROBADO** — Pruebas del seed de integración DEMO-SQL-007

- **Requisito:** RNF-04 — Integridad y reglas de la base de datos
- **Módulo / área:** Base de datos · Pruebas SQL del equipo · SQL · prioridad Media
- **Responsable:** Jeison Rosario
- **Pasos:** psql -f database/test/pruebas_seed_integracion_resultados.sql
- **Datos:** Seed recién cargado
- **Resultado esperado:** Seis 'OK SEED' y 'PRUEBAS SEED INTEGRACION COMPLETADAS'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MOTD-01

**✅ APROBADO** — Prueba de Daniel: rendimiento bajo

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** adaptive-engine/tests/test_engine.py::test_low_performance
- **Datos:** score 45, 6 errores
- **Resultado esperado:** reinforce_topic / reduced.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOTD-02

**✅ APROBADO** — Prueba de Daniel: rendimiento medio

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** test_engine.py::test_medium_performance
- **Datos:** score 75, 2 errores
- **Resultado esperado:** maintain_difficulty.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOTD-03

**✅ APROBADO** — Prueba de Daniel: rendimiento alto

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** test_engine.py::test_high_performance
- **Datos:** score 95, 0 errores, 1 intento
- **Resultado esperado:** increase_difficulty.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOTD-04

**✅ APROBADO** — Prueba de Daniel: interacciones vacías

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** test_engine.py::test_empty_interactions
- **Datos:** interactions = []
- **Resultado esperado:** ValueError.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOTD-05

**✅ APROBADO** — Prueba de Daniel: puntuación inválida

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** test_engine.py::test_invalid_score
- **Datos:** score 150
- **Resultado esperado:** ValueError.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOTD-06

**✅ APROBADO** — Prueba de Daniel: campo obligatorio faltante

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Pruebas del motor (Daniel) · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** test_engine.py::test_missing_required_field
- **Datos:** sin navigation_count
- **Resultado esperado:** ValueError.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02b_pruebas_motor_daniel.log](../evidencias/logs/02b_pruebas_motor_daniel.log)

### CP-MOT-01

**✅ APROBADO** — Escenario 1 — Rendimiento bajo

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** process_student con puntuación 45 y 6 errores.
- **Datos:** score=45, errors=6, attempts=2
- **Resultado esperado:** action=reinforce_topic, difficulty=reduced, mensaje con el tema.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-02

**✅ APROBADO** — Escenario 2 — Rendimiento medio

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** process_student con puntuación 75 y 2 errores.
- **Datos:** score=75, errors=2, attempts=2
- **Resultado esperado:** action=maintain_difficulty, difficulty=current.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-03

**✅ APROBADO** — Escenario 3 — Rendimiento alto

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** process_student con puntuación 95, 0 errores y 1 intento.
- **Datos:** score=95, errors=0, attempts=1
- **Resultado esperado:** action=increase_difficulty, difficulty=increased.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-04

**✅ APROBADO** — Valores límite de las reglas (60 %, 85 %, 2 y 5 errores, 2 intentos)

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Evaluar combinaciones justo en y alrededor de cada umbral.
- **Datos:** Tabla parametrizada
- **Resultado esperado:** Cada combinación cae en la regla que indica INTEGRATION.md (orden: refuerzo → aumento → mantener).
- **Resultado real:** Coincide con el esperado. 9 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (9):**
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[59.99-0-1-reinforce_topic]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[60-0-1-maintain_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[90-5-1-reinforce_topic]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[90-4-1-maintain_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[84.99-0-1-maintain_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[85-2-2-increase_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[85-3-2-maintain_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[85-2-3-maintain_difficulty]`
  - ✅ `test_CP_MOT_04_valores_limite_de_las_reglas[50-0-1-reinforce_topic]`

### CP-MOT-05

**✅ APROBADO** — Material complementario con 5 o más repeticiones

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Refuerzo con 5 repeticiones y mantener con 5 repeticiones.
- **Datos:** repetitions=5
- **Resultado esperado:** Solo el refuerzo añade 'material complementario'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-06

**✅ APROBADO** — Datos de ejemplo data/estudiante_prueba.json

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Procesar el archivo de ejemplo del repositorio.
- **Datos:** 3 interacciones de SQL JOIN
- **Resultado esperado:** Promedio 53.33, 9 errores, 3 intentos promedio → reinforce_topic.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-07

**✅ APROBADO** — Cálculo correcto del perfil con varias interacciones

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Comparar el perfil con cálculos manuales.
- **Datos:** 3 interacciones con valores conocidos
- **Resultado esperado:** Promedios, sumas y total de interacciones correctos.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-MOT-08

**✅ APROBADO** — La salida respeta el contrato usado por el frontend

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Contrato · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Verificar claves y valores permitidos de profile y recommendation.
- **Datos:** Escenario medio
- **Resultado esperado:** Mismas claves que INTEGRATION.md y que el tipo Recommendation de frontend/src/types.
- **Resultado real:** Coincide con el esperado. 2 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (2):**
  - ✅ `test_CP_MOT_08_salida_respeta_el_contrato_del_frontend`
  - ✅ `test_CP_MOT_08_no_modifica_los_datos_de_entrada`

### CP-MOT-09

**✅ APROBADO** — main.py --stdin devuelve JSON que Node puede leer

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Integración Node ↔ Python · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Desde Node, ejecutar python main.py --stdin enviando JSON y hacer JSON.parse de la salida.
- **Datos:** Los 3 escenarios
- **Resultado esperado:** Código de salida 0 y JSON válido con la acción esperada.
- **Resultado real:** Coincide con el esperado. 3 verificaciones aprobadas.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)
- **Verificaciones (3):**
  - ✅ `CP-MOT-09 --stdin escenario bajo devuelve JSON legible por Node`
  - ✅ `CP-MOT-09 --stdin escenario medio devuelve JSON legible por Node`
  - ✅ `CP-MOT-09 --stdin escenario alto devuelve JSON legible por Node`

### CP-MOT-10

**✅ APROBADO** — main.py en modo local (sin --stdin) se ejecuta sin errores críticos

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Integración Node ↔ Python · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** python main.py desde adaptive-engine.
- **Datos:** data/estudiante_prueba.json
- **Resultado esperado:** Código 0, imprime PERFIL y RECOMENDACIÓN.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-MOT-11

**✅ APROBADO** — Backend llama al motor: POST /api/students/:id/recommendation

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Backend / API · Integración Node ↔ Python · Integración · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/students/:id/recommendation con {topic:'SQL JOIN'} y el token del estudiante demo.
- **Datos:** SQL JOIN (promedio 16.67)
- **Resultado esperado:** 200 con accion=reinforce_topic y dificultad=reduced calculadas por Python.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-11
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-01

**✅ APROBADO** — Escenario bajo por la API: SQL JOIN

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** POST /api/mis-inscripciones/:id/temas/:temaId/recomendacion y POST /api/students/:id/recommendation.
- **Datos:** SQL JOIN (0, 25, 25 → 16.67)
- **Resultado esperado:** reinforce_topic / reduced en ambas rutas.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-11
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-02

**✅ APROBADO** — Escenario medio por la API: SQL WHERE

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Igual que CP-ADP-01 con SQL WHERE.
- **Datos:** SQL WHERE (50, 75, 75 → 66.67)
- **Resultado esperado:** maintain_difficulty / current.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-11
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-03

**✅ APROBADO** — Escenario alto por la API: SQL SELECT

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Igual que CP-ADP-01 con SQL SELECT.
- **Datos:** SQL SELECT (75, 100, 100 → 91.67)
- **Resultado esperado:** increase_difficulty / increased.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-11
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-04

**✅ APROBADO** — La evidencia de la recomendación coincide con PostgreSQL

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Comparar mastery con el promedio de los intentos calificados en la base.
- **Datos:** Los tres temas
- **Resultado esperado:** mastery igual al promedio real; errores enteros ≥ 0.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-05

**✅ APROBADO** — El progreso recomienda reforzar el tema más débil

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** GET /api/students/:id/progress.
- **Datos:** Cuenta demo
- **Resultado esperado:** Recomendación SQL JOIN, reinforce_topic, prioridad alta.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-06

**✅ APROBADO** — Un intento nuevo cambia los datos que analiza el motor

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Escenarios por API · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Hacer un intento al 100 % en la evaluación de SQL JOIN y volver a pedir la recomendación.
- **Datos:** Evaluación de SQL JOIN
- **Resultado esperado:** El promedio (mastery) sube y coincide con la base.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-07

**✅ APROBADO** — Estudiante sin intentos

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Casos límite · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Estudiante nuevo pide recomendación, resumen y progreso; el demo pide recomendación de un tema publicado sin intentos.
- **Datos:** Estudiante QA y tema QA
- **Resultado esperado:** 404 con mensaje claro; resumen y progreso 200 con recomendación null (sin errores 500).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-08

**✅ APROBADO** — Datos inválidos en las rutas del motor

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Casos límite · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Tema vacío o largo, ids inválidos, inscripción ajena y sin token.
- **Datos:** Tabla de casos
- **Resultado esperado:** 400, 403 o 401 según el caso; nunca 500.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-ADP-09

**✅ APROBADO** — Errores del motor: Python ausente o motor que falla

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Motor adaptativo · Casos límite · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Configurar PYTHON_EXECUTABLE inválido y luego un ejecutable que no es Python.
- **Datos:** PYTHON_EXECUTABLE
- **Resultado esperado:** 502 'El motor de recomendación no está disponible' sin detalles internos; el progreso sigue respondiendo 200; se recupera al volver Python.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-VAL-01

**✅ APROBADO** — Interacciones vacías

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** process_student con interactions = [].
- **Datos:** []
- **Resultado esperado:** ValueError 'al menos una interacción'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-VAL-02

**✅ APROBADO** — Interacciones ausentes o null

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Sin la clave interactions y con interactions = None.
- **Datos:** {} / None
- **Resultado esperado:** ValueError.
- **Resultado real:** Coincide con el esperado. 2 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (2):**
  - ✅ `test_CP_VAL_02_interacciones_ausentes_o_null[ausente]`
  - ✅ `test_CP_VAL_02_interacciones_ausentes_o_null[null]`

### CP-VAL-03

**✅ APROBADO** — Campo obligatorio faltante (cada uno de los 6)

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Eliminar uno a uno los campos obligatorios.
- **Datos:** study_minutes … score_percentage
- **Resultado esperado:** ValueError que nombra el campo faltante.
- **Resultado real:** Coincide con el esperado. 6 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (6):**
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[study_minutes]`
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[errors]`
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[attempts]`
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[repetitions]`
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[navigation_count]`
  - ✅ `test_CP_VAL_03_campo_obligatorio_faltante[score_percentage]`

### CP-VAL-04

**✅ APROBADO** — Valores no numéricos o nulos

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar 'abc', '', None y listas en campos numéricos.
- **Datos:** score_percentage='abc', errors=None…
- **Resultado esperado:** ValueError 'Los datos deben ser numéricos y válidos.'
- **Resultado real:** Coincide con el esperado. 5 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (5):**
  - ✅ `test_CP_VAL_04_valores_no_numericos_o_nulos[score_percentage-abc]`
  - ✅ `test_CP_VAL_04_valores_no_numericos_o_nulos[score_percentage-]`
  - ✅ `test_CP_VAL_04_valores_no_numericos_o_nulos[errors-None]`
  - ✅ `test_CP_VAL_04_valores_no_numericos_o_nulos[attempts-valor3]`
  - ✅ `test_CP_VAL_04_valores_no_numericos_o_nulos[study_minutes-veinte]`

### CP-VAL-05

**✅ APROBADO** — Valores fuera de rango

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** score 150 y -1, minutos/errores/repeticiones/navegación negativos, attempts 0.
- **Datos:** Tabla parametrizada
- **Resultado esperado:** ValueError 'fuera de los rangos permitidos'.
- **Resultado real:** Coincide con el esperado. 7 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (7):**
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[score_percentage-150]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[score_percentage--1]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[study_minutes--5]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[errors--1]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[attempts-0]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[repetitions--2]`
  - ✅ `test_CP_VAL_05_valores_fuera_de_rango[navigation_count--3]`

### CP-VAL-06

**✅ APROBADO** — Números enviados como texto ('90')

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Baja
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar valores numéricos como cadenas.
- **Datos:** score_percentage='90'
- **Resultado esperado:** Se convierten y se procesan (comportamiento documentado por pd.to_numeric).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)

### CP-VAL-07

**❌ FALLIDO** — Falta student_id o topic

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** process_student sin student_id y sin topic.
- **Datos:** {topic, interactions} / {student_id, interactions}
- **Resultado esperado:** ValueError con mensaje claro que nombre el campo (igual que los demás campos obligatorios).
- **Resultado real:** KeyError('topic'). (ver INC-05)
- **Detalle técnico:** 2 de 2 verificaciones fallaron. KeyError: 'student_id'
- **Incidencias:** INC-05
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (2):**
  - ❌ `test_CP_VAL_07_falta_student_id_o_topic[student_id]`
  - ❌ `test_CP_VAL_07_falta_student_id_o_topic[topic]`

### CP-VAL-08

**✅ APROBADO** — interactions con tipo incorrecto

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** interactions como texto, objeto y lista de números.
- **Datos:** 'abc', {a:1}, [1,2]
- **Resultado esperado:** ValueError controlado (no otra excepción).
- **Resultado real:** Coincide con el esperado. 3 verificaciones aprobadas.
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (3):**
  - ✅ `test_CP_VAL_08_interactions_con_tipo_incorrecto[abc]`
  - ✅ `test_CP_VAL_08_interactions_con_tipo_incorrecto[valor1]`
  - ✅ `test_CP_VAL_08_interactions_con_tipo_incorrecto[valor2]`

### CP-VAL-09

**❌ FALLIDO** — Valores infinitos (Infinity) o NaN

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar float('inf') y float('nan') en campos numéricos.
- **Datos:** study_minutes=inf, score=nan
- **Resultado esperado:** ValueError: no son datos válidos.
- **Resultado real:** Código 0 y salida con 'Infinity'. (ver INC-04)
- **Detalle técnico:** 2 de 3 verificaciones fallaron. Failed: DID NOT RAISE ValueError
- **Incidencias:** INC-04
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (3):**
  - ❌ `test_CP_VAL_09_infinito_o_nan_se_rechazan[study_minutes-inf]`
  - ✅ `test_CP_VAL_09_infinito_o_nan_se_rechazan[score_percentage-nan]`
  - ❌ `test_CP_VAL_09_infinito_o_nan_se_rechazan[navigation_count-inf]`

### CP-VAL-10

**❌ FALLIDO** — Valores booleanos en campos numéricos

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Baja
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar true/false en score_percentage y errors.
- **Datos:** score_percentage=True
- **Resultado esperado:** ValueError (true no es una puntuación).
- **Resultado real:** Se procesa con promedio 1.0 y acción reinforce_topic. (ver INC-06)
- **Detalle técnico:** 2 de 2 verificaciones fallaron. Failed: DID NOT RAISE ValueError
- **Incidencias:** INC-06
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (2):**
  - ❌ `test_CP_VAL_10_booleanos_se_rechazan[score_percentage]`
  - ❌ `test_CP_VAL_10_booleanos_se_rechazan[errors]`

### CP-VAL-11

**❌ FALLIDO** — Conteos con decimales (errores, intentos, repeticiones, navegación)

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Unitaria · prioridad Baja
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar errors=2.7.
- **Datos:** errors=2.7
- **Resultado esperado:** ValueError: los conteos deben ser enteros (hoy se truncan en silencio).
- **Resultado real:** total_errors = 2. (ver INC-07)
- **Detalle técnico:** 4 de 4 verificaciones fallaron. Failed: DID NOT RAISE ValueError
- **Incidencias:** INC-07
- **Evidencia:** [02_unitarias_motor.log](../evidencias/logs/02_unitarias_motor.log)
- **Verificaciones (4):**
  - ❌ `test_CP_VAL_11_conteos_con_decimales_se_rechazan[errors]`
  - ❌ `test_CP_VAL_11_conteos_con_decimales_se_rechazan[attempts]`
  - ❌ `test_CP_VAL_11_conteos_con_decimales_se_rechazan[repetitions]`
  - ❌ `test_CP_VAL_11_conteos_con_decimales_se_rechazan[navigation_count]`

### CP-VAL-12

**✅ APROBADO** — CLI: JSON mal formado

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar texto no JSON a main.py --stdin.
- **Datos:** { esto no es json
- **Resultado esperado:** Código 1 y {"error": ...} en stderr.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-VAL-13

**✅ APROBADO** — CLI: interacciones vacías

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Integración · prioridad Alta
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar un estudiante con interactions=[] a main.py --stdin.
- **Datos:** interactions: []
- **Resultado esperado:** Código 1 y {"error": ...} en stderr.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-VAL-14

**❌ FALLIDO** — CLI: JSON válido cuya raíz no es un objeto

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar [], "texto", 5 y null a main.py --stdin.
- **Datos:** [] / "x" / 5 / null
- **Resultado esperado:** Código 1 y {"error": ...} en stderr (sin traceback de Python).
- **Resultado real:** Traceback de Python: AttributeError: 'list' object has no attribute 'get'. (ver INC-03)
- **Detalle técnico:** 4 de 4 verificaciones fallaron. main() ~~~~^^ File "/home/claude/v3/proyecto-grupo4/adaptive-engine/main.py", line 20[Actual message: "Unexpected token 'T', "Traceback "... is not valid JSON""> [Error [ERR_TEST_FAILURE]: Got unwanted exception: stderr no es JSON: Traceback (most recent call last): File "/home/claude/v3/proyecto-grupo4/adaptive-engine/main.py", line 47, in <module> main() ~~~~^^ File "/home/claude/v3/proyecto-gr
- **Incidencias:** INC-03
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)
- **Verificaciones (4):**
  - ❌ `CP-VAL-14 CLI con raíz JSON que no es objeto: []`
  - ❌ `CP-VAL-14 CLI con raíz JSON que no es objeto: "texto"`
  - ❌ `CP-VAL-14 CLI con raíz JSON que no es objeto: 5`
  - ❌ `CP-VAL-14 CLI con raíz JSON que no es objeto: null`

### CP-VAL-15

**❌ FALLIDO** — CLI: Infinity en la entrada no rompe el JSON de salida

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Motor adaptativo · Datos vacíos e incorrectos · Integración · prioridad Media
- **Responsable:** Daniel Beltre
- **Pasos:** Enviar study_minutes: Infinity (Python lo acepta al leer).
- **Datos:** study_minutes: Infinity
- **Resultado esperado:** Rechazo con código 1, o salida que JSON.parse de Node pueda leer.
- **Resultado real:** Código 0 y salida con 'Infinity'. (ver INC-04)
- **Detalle técnico:** 1 de 1 verificaciones fallaron. Got unwanted exception: Node no puede leer la salida:{"profile": {"student_id": 1, "topic": "SQL JOIN", "average_score": 75.0, "total_errors": 2, "average_attempts": 2.0, "total_repetitions": 1, "average_study_minutes": Infinity, "total_interactions": 1Actual message: "Unexpected token 'I', ..."minutes": Infinity, "... is not valid JSON"
- **Incidencias:** INC-04
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BE-01

**✅ APROBADO** — registerDto acepta y rechaza según las reglas

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Validación · Unitaria · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** safeParse con datos válidos e inválidos.
- **Datos:** Tabla de casos
- **Resultado esperado:** Válidos aceptados (con trim); inválidos rechazados con mensaje.
- **Resultado real:** Coincide con el esperado. 8 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (8):**
  - ✅ `CP-BE-01 acepta datos válidos y aplica trim`
  - ✅ `CP-BE-01 rechaza email mal formado`
  - ✅ `CP-BE-01 rechaza contraseña de 7 caracteres`
  - ✅ `CP-BE-01 rechaza contraseña de 73 caracteres`
  - ✅ `CP-BE-01 rechaza nombre vacío`
  - ✅ `CP-BE-01 rechaza apellido de 51 caracteres`
  - ✅ `CP-BE-01 rechaza nombre numérico`
  - ✅ `CP-BE-01 acepta los límites exactos (8 y 72 caracteres, 50 en nombre)`

### CP-BE-02

**✅ APROBADO** — loginDto exige email y password

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Validación · Unitaria · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** safeParse con campos vacíos, ausentes y con tipos erróneos.
- **Datos:** —
- **Resultado esperado:** Rechazo en todos los casos inválidos.
- **Resultado real:** Coincide con el esperado. 5 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (5):**
  - ✅ `CP-BE-02 rechaza campos vacíos`
  - ✅ `CP-BE-02 rechaza campos ausentes`
  - ✅ `CP-BE-02 rechaza campos email solo con espacios`
  - ✅ `CP-BE-02 rechaza campos password numérico`
  - ✅ `CP-BE-02 acepta credenciales con formato correcto`

### CP-BE-03

**✅ APROBADO** — toUserResponse nunca expone campos internos

- **Requisito:** RNF-01 — Seguridad (tokens, contraseñas, límites, datos sensibles)
- **Módulo / área:** Backend / API · Seguridad · Unitaria · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Pasar un objeto con passwordHash y activo.
- **Datos:** —
- **Resultado esperado:** Solo id, nombre, apellido, email y rol.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)

### CP-BE-04

**✅ APROBADO** — Middleware validate

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Validación · Unitaria · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Ejecutar con cuerpo válido e inválido.
- **Datos:** —
- **Resultado esperado:** Inválido → AppError 400 con details {campo, mensaje}; válido → req.body limpio y next().
- **Resultado real:** Coincide con el esperado. 2 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (2):**
  - ✅ `CP-BE-04 cuerpo inválido → AppError 400 con details {campo, mensaje}`
  - ✅ `CP-BE-04 cuerpo válido → next() y req.body limpio`

### CP-BE-05

**✅ APROBADO** — Middleware verifyToken

- **Requisito:** RNF-01 — Seguridad (tokens, contraseñas, límites, datos sensibles)
- **Módulo / área:** Backend / API · Seguridad · Unitaria · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Sin cabecera, esquema Basic, token inválido, expirado y válido.
- **Datos:** —
- **Resultado esperado:** 401 en los inválidos; con el válido, req.user = {id, rol}.
- **Resultado real:** Coincide con el esperado. 7 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (7):**
  - ✅ `CP-BE-05 rechaza sin cabecera con 401`
  - ✅ `CP-BE-05 rechaza esquema Basic con 401`
  - ✅ `CP-BE-05 rechaza Bearer sin token con 401`
  - ✅ `CP-BE-05 rechaza token basura con 401`
  - ✅ `CP-BE-05 rechaza firmado con otro secreto con 401`
  - ✅ `CP-BE-05 rechaza expirado con 401`
  - ✅ `CP-BE-05 token válido → req.user con id y rol`

### CP-BE-06

**✅ APROBADO** — requireRole y requirePermission

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Backend / API · Seguridad · Unitaria · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** Probar cada rol contra cada permiso de config/permissions.js.
- **Datos:** —
- **Resultado esperado:** 403 si el rol no está autorizado; error si el permiso no existe.
- **Resultado real:** Coincide con el esperado. 3 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (3):**
  - ✅ `CP-BE-06 requireRole permite el rol indicado y bloquea los demás`
  - ✅ `CP-BE-06 cada permiso respeta config/permissions.js para los 3 roles`
  - ✅ `CP-BE-06 un permiso no definido produce un error de programación`

### CP-BE-07

**❌ FALLIDO** — errorHandler traduce cada tipo de error

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Errores · Unitaria · prioridad Media
- **Responsable:** Porfirio Ramírez
- **Pasos:** AppError, JSON inválido, código 23505 y error inesperado.
- **Datos:** —
- **Resultado esperado:** status propio, 400, 409 y 500 sin filtrar detalles internos.
- **Resultado real:** 400 { success:false, message:'Unexpected end of JSON input' } (ver INC-02)
- **Detalle técnico:** 1 de 5 verificaciones fallaron. Expected values to be strictly equal:+ actual - expected+ 'Unexpected end of JSON input'- 'JSON inválido'
- **Incidencias:** INC-02
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (5):**
  - ✅ `CP-BE-07 AppError conserva su status, mensaje y details`
  - ❌ `CP-BE-07 JSON inválido → 400 'JSON inválido'`
  - ✅ `CP-BE-07 violación de unicidad de PostgreSQL (23505) → 409`
  - ✅ `CP-BE-07 error inesperado → 500 sin filtrar el detalle interno`
  - ✅ `CP-BE-07 notFound → 404 JSON`

### CP-BE-08

**✅ APROBADO** — OpenAPI coincide con las rutas implementadas

- **Requisito:** RNF-05 — Documentación de la API (OpenAPI)
- **Módulo / área:** Backend / API · Documentación · Unitaria · prioridad Baja
- **Responsable:** Porfirio Ramírez
- **Pasos:** Comparar paths de openapi.yaml con los routers de Express.
- **Datos:** —
- **Resultado esperado:** Mismos endpoints y enum de roles igual a config/roles.js.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)

### CP-BE-09

**❌ FALLIDO** — Health check y ruta inexistente

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Errores · Integración · prioridad Baja
- **Responsable:** Porfirio Ramírez
- **Pasos:** GET /api/health y GET /api/no-existe.
- **Datos:** —
- **Resultado esperado:** 200 {status:'ok'}; una ruta que no existe responde 404 JSON 'Ruta no encontrada' (también sin token).
- **Resultado real:** 401. (ver INC-14)
- **Detalle técnico:** 1 de 1 verificaciones fallaron. respondió 401: Token requerido401 !== 404
- **Incidencias:** INC-14
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-BE-10

**❌ FALLIDO** — Cuerpo demasiado grande (413)

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Backend / API · Errores · Integración · prioridad Baja
- **Responsable:** Porfirio Ramírez
- **Pasos:** POST /api/auth/login con un cuerpo de más de 100 KB.
- **Datos:** email de 200.000 caracteres
- **Resultado esperado:** 413 con el mensaje en español 'El cuerpo de la petición es demasiado grande'.
- **Resultado real:** 413 'request entity too large'. (ver INC-13)
- **Detalle técnico:** 1 de 1 verificaciones fallaron. Expected values to be strictly equal:+ actual - expected+ 'request entity too large'- 'El cuerpo de la petición es demasiado grande'
- **Incidencias:** INC-13
- **Evidencia:** [03_integracion.log](../evidencias/logs/03_integracion.log)

### CP-FE-01

**✅ APROBADO** — loginSchema

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Validación · Unitaria · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** safeParse con correo vacío, mal formado, contraseña vacía y datos válidos.
- **Datos:** —
- **Resultado esperado:** Mensajes 'Ingresa tu correo.', 'Ingresa un correo válido.', 'Ingresa tu contraseña.'
- **Resultado real:** Coincide con el esperado. 4 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (4):**
  - ✅ `CP-FE-01 correo vacío → 'Ingresa tu correo.'`
  - ✅ `CP-FE-01 correo mal formado → 'Ingresa un correo válido.'`
  - ✅ `CP-FE-01 contraseña vacía → 'Ingresa tu contraseña.'`
  - ✅ `CP-FE-01 datos válidos se aceptan`

### CP-FE-02

**✅ APROBADO** — registerSchema

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Validación · Unitaria · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Contraseñas distintas, cortas, largas y nombres de más de 50 caracteres.
- **Datos:** —
- **Resultado esperado:** Rechazo con el mensaje y el campo correctos.
- **Resultado real:** Coincide con el esperado. 7 verificaciones aprobadas.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)
- **Verificaciones (7):**
  - ✅ `CP-FE-02 contraseñas distintas → 'Las contraseñas no coinciden.' en confirmPassword`
  - ✅ `CP-FE-02 contraseña corta → 'La contraseña debe tener al menos 8 caracteres.' en password`
  - ✅ `CP-FE-02 contraseña de 73 → 'Máximo 72 caracteres.' en password`
  - ✅ `CP-FE-02 nombre de 51 → 'Máximo 50 caracteres.' en nombre`
  - ✅ `CP-FE-02 apellido vacío → 'Ingresa tu apellido.' en apellido`
  - ✅ `CP-FE-02 confirmación vacía → 'Confirma tu contraseña.' en confirmPassword`
  - ✅ `CP-FE-02 datos válidos se aceptan`

### CP-FE-03

**✅ APROBADO** — Reglas del registro iguales en frontend y backend

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Validación · Unitaria · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Pasar los mismos datos a registerSchema (frontend) y registerDto (backend).
- **Datos:** Tabla de casos frontera
- **Resultado esperado:** Ambos aceptan o ambos rechazan cada caso.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [01_unitarias_node.log](../evidencias/logs/01_unitarias_node.log)

### CP-UI-01

**✅ APROBADO** — Login real desde el navegador contra el backend (CORS) — re-prueba de INC-01

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Backend / API · Integración Frontend ↔ Backend · Funcional (E2E) · prioridad Alta
- **Responsable:** Porfirio Ramírez
- **Pasos:** Frontend con VITE_USE_MOCK=false en otro origen y backend real con CORS_ORIGIN; iniciar sesión con la cuenta demo.
- **Datos:** estudiante.demo@example.com / DemoEquipo-2026!
- **Resultado esperado:** Redirige al Dashboard sin errores de CORS.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-01
- **Evidencia:** [CP-UI-01_login_real_con_cors.png](../evidencias/capturas/CP-UI-01_login_real_con_cors.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-02

**✅ APROBADO** — Login válido en la pantalla

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Frontend · Login (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Escribir credenciales válidas y pulsar 'Iniciar sesión'.
- **Datos:** Cuenta demo
- **Resultado esperado:** Redirige a '/', muestra el nombre del usuario y su rol en la barra.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-02_login_valido_dashboard.png](../evidencias/capturas/CP-UI-02_login_valido_dashboard.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-03

**✅ APROBADO** — Login inválido en la pantalla

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Frontend · Login (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Escribir contraseña incorrecta y enviar.
- **Datos:** Cuenta demo / ClaveIncorrecta1
- **Resultado esperado:** Permanece en /login y muestra 'Credenciales inválidas'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-03_login_invalido.png](../evidencias/capturas/CP-UI-03_login_invalido.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-04

**✅ APROBADO** — Validación de campos vacíos e inválidos en el formulario

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Login (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Enviar el formulario vacío y luego con un correo mal formado.
- **Datos:** '' y 'correo-invalido'
- **Resultado esperado:** Mensajes de validación junto a cada campo; no se llama al backend.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-04a_login_campos_vacios.png](../evidencias/capturas/CP-UI-04a_login_campos_vacios.png) · [CP-UI-04b_login_correo_invalido.png](../evidencias/capturas/CP-UI-04b_login_correo_invalido.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-05

**✅ APROBADO** — Rutas protegidas sin sesión

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Frontend · Navegación · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Abrir /, /contenido, /resultados, /progreso, /cursos y /gestion sin sesión.
- **Datos:** —
- **Resultado esperado:** Redirección a /login en todos los casos.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-05_ruta_protegida_redirige.png](../evidencias/capturas/CP-UI-05_ruta_protegida_redirige.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-06

**✅ APROBADO** — Registro desde la pantalla y login con la cuenta nueva

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Frontend · CRUD usuarios (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Completar /registro, enviar, iniciar sesión con la cuenta creada.
- **Datos:** Usuario QA único
- **Resultado esperado:** Cuenta creada (201) e inicio de sesión exitoso.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-06a_registro_formulario.png](../evidencias/capturas/CP-UI-06a_registro_formulario.png) · [CP-UI-06b_registro_exitoso.png](../evidencias/capturas/CP-UI-06b_registro_exitoso.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-07

**✅ APROBADO** — Navegación entre pantallas sin recarga

- **Requisito:** RNF-03 — Usabilidad y navegación del frontend
- **Módulo / área:** Frontend · Navegación · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Con sesión, pulsar Contenido, Resultados, Progreso y Dashboard en la barra.
- **Datos:** —
- **Resultado esperado:** Cambia la URL y el contenido sin recargar la página (SPA).
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-08

**✅ APROBADO** — La sesión se conserva al recargar y se borra al cerrar sesión

- **Requisito:** RF-01 — Autenticación: registro, inicio y cierre de sesión
- **Módulo / área:** Frontend · Persistencia (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Iniciar sesión, recargar (F5), luego pulsar 'Cerrar sesión' e intentar volver a '/'.
- **Datos:** Cuenta demo
- **Resultado esperado:** Tras recargar sigue dentro; tras cerrar sesión vuelve a /login y no puede regresar.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-08_sesion_cerrada.png](../evidencias/capturas/CP-UI-08_sesion_cerrada.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-09

**✅ APROBADO** — Dashboard con datos reales del backend

- **Requisito:** RF-08 — Dashboard y progreso del estudiante
- **Módulo / área:** Frontend · Integración Frontend ↔ Backend · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Con VITE_USE_MOCK=false, iniciar sesión como estudiante demo y revisar el Dashboard.
- **Datos:** Cuenta demo
- **Resultado esperado:** Muestra el resumen y la tarjeta del motor con datos reales (SQL JOIN), sin etiquetas ni actividad de ejemplo.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-16
- **Evidencia:** [CP-UI-09_dashboard_datos_reales.png](../evidencias/capturas/CP-UI-09_dashboard_datos_reales.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-10

**✅ APROBADO** — Cuestionario real de Contenido: responder y entregar

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Frontend · Motor adaptativo (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Contenido → curso 'SQL: integracion y resultados' → tema SQL JOIN → Iniciar 'SQL JOIN - practica' → responder todo bien → Entregar intento.
- **Datos:** Cuenta demo, actividad 'SQL JOIN - practica'
- **Resultado esperado:** Resultado 100 % en pantalla y el intento queda CALIFICADO en PostgreSQL.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-10a_actividades_del_tema.png](../evidencias/capturas/CP-UI-10a_actividades_del_tema.png) · [CP-UI-10b_cuestionario_respondido.png](../evidencias/capturas/CP-UI-10b_cuestionario_respondido.png) · [CP-UI-10c_resultado_del_intento.png](../evidencias/capturas/CP-UI-10c_resultado_del_intento.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-11

**✅ APROBADO** — Las respuestas del estudiante se envían y guardan en el backend

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Frontend · Motor adaptativo (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Responder un cuestionario real y revisar las peticiones y la base de datos.
- **Datos:** —
- **Resultado esperado:** Un PUT /mis-respuestas/:id/opciones por pregunta, POST /mis-intentos/:id/entrega y las selecciones guardadas en respuesta_opciones. Si no se envían → BLOQUEADO.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-12
- **Evidencia:** [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-12

**✅ APROBADO** — Recorrido visual completo del estudiante con recomendación real

- **Requisito:** RF-07 — Motor adaptativo: recomendaciones según desempeño
- **Módulo / área:** Frontend · Recorrido completo · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Login → Dashboard → Contenido → curso SQL → tema SQL JOIN → Iniciar práctica → responder → Entregar → Ver recomendación del motor → Resultados → Progreso → Cerrar sesión.
- **Datos:** Cuenta demo
- **Resultado esperado:** Cada pantalla carga con datos reales; tras entregar, el motor real responde reinforce_topic y la tarjeta muestra 'Detectamos dificultades en SQL JOIN'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-12a_login.png](../evidencias/capturas/CP-UI-12a_login.png) · [CP-UI-12b_dashboard_recomendacion.png](../evidencias/capturas/CP-UI-12b_dashboard_recomendacion.png) · [CP-UI-12c_cuestionario.png](../evidencias/capturas/CP-UI-12c_cuestionario.png) · [CP-UI-12d_recomendacion_del_motor.png](../evidencias/capturas/CP-UI-12d_recomendacion_del_motor.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-13

**✅ APROBADO** — Estudiante sin intentos ni cursos ve avisos, no errores

- **Requisito:** RF-08 — Dashboard y progreso del estudiante
- **Módulo / área:** Frontend · Motor adaptativo (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Registrar un estudiante nuevo, abrir el Dashboard y luego Contenido.
- **Datos:** Estudiante QA
- **Resultado esperado:** Dashboard sin error; Contenido muestra 'Aún no estás inscrito en ningún curso activo'.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-15
- **Evidencia:** [CP-UI-13a_dashboard_sin_datos.png](../evidencias/capturas/CP-UI-13a_dashboard_sin_datos.png) · [CP-UI-13b_contenido_sin_cursos.png](../evidencias/capturas/CP-UI-13b_contenido_sin_cursos.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-14

**✅ APROBADO** — Error del motor visto desde la pantalla

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Motor adaptativo (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Entregar un intento real y pedir la recomendación con Python no disponible.
- **Datos:** PYTHON_EXECUTABLE inválido
- **Resultado esperado:** Mensaje 'No se pudo generar la recomendación. El motor de recomendación no está disponible'.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-14_error_del_motor.png](../evidencias/capturas/CP-UI-14_error_del_motor.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-15

**✅ APROBADO** — Desconexión del backend

- **Requisito:** RNF-02 — Validación de datos y manejo de errores
- **Módulo / área:** Frontend · Robustez · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Con sesión y un cuestionario respondido, apagar el backend; intentar entregar, abrir el Dashboard e iniciar sesión.
- **Datos:** Backend detenido
- **Resultado esperado:** 'No se pudo conectar con el servidor…' al entregar, en el Dashboard y en el Login, sin quedarse colgado.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-15a_backend_desconectado_contenido.png](../evidencias/capturas/CP-UI-15a_backend_desconectado_contenido.png) · [CP-UI-15b_backend_desconectado_dashboard.png](../evidencias/capturas/CP-UI-15b_backend_desconectado_dashboard.png) · [CP-UI-15c_backend_desconectado_login.png](../evidencias/capturas/CP-UI-15c_backend_desconectado_login.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-16

**✅ APROBADO** — El administrador crea un curso desde la pantalla

- **Requisito:** RF-04 — CRUD de cursos (administrador)
- **Módulo / área:** Frontend · CRUD cursos (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** /cursos → + Nuevo curso → guardar.
- **Datos:** Curso UI-xxxx
- **Resultado esperado:** Aparece en la lista y queda guardado en PostgreSQL.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-16a_nuevo_curso_formulario.png](../evidencias/capturas/CP-UI-16a_nuevo_curso_formulario.png) · [CP-UI-16b_curso_creado.png](../evidencias/capturas/CP-UI-16b_curso_creado.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-17

**✅ APROBADO** — El docente crea un módulo desde la pantalla

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Frontend · CRUD módulos y temas (UI) · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** /gestion → elegir DEMO-006 en el selector de curso → + Nuevo módulo → guardar.
- **Datos:** Módulo UI-xxxx
- **Resultado esperado:** Aparece en la lista y queda guardado en DEMO-006.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-17a_nuevo_modulo_formulario.png](../evidencias/capturas/CP-UI-17a_nuevo_modulo_formulario.png) · [CP-UI-17b_modulo_creado.png](../evidencias/capturas/CP-UI-17b_modulo_creado.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-18

**✅ APROBADO** — El menú muestra solo las secciones de cada rol

- **Requisito:** RF-02 — Roles y permisos (estudiante, docente, administrador)
- **Módulo / área:** Frontend · Roles (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Iniciar sesión con cada cuenta demo y leer el menú.
- **Datos:** 3 cuentas demo
- **Resultado esperado:** Estudiante: Dashboard/Contenido/Resultados/Progreso. Docente: Inicio/Contenido. Administrador: Inicio/Cursos/Contenido.
- **Resultado real:** Coincide con el esperado.
- **Evidencia:** [CP-UI-18_inicio_administrador.png](../evidencias/capturas/CP-UI-18_inicio_administrador.png) · [CP-UI-18_inicio_docente.png](../evidencias/capturas/CP-UI-18_inicio_docente.png) · [CP-UI-18_inicio_estudiante.png](../evidencias/capturas/CP-UI-18_inicio_estudiante.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-19

**✅ APROBADO** — El docente elige su curso de una lista

- **Requisito:** RF-05 — CRUD de módulos y temas (docente/administrador)
- **Módulo / área:** Frontend · CRUD módulos y temas (UI) · Funcional (E2E) · prioridad Media
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Abrir /gestion como docente.
- **Datos:** docente.demo@example.com
- **Resultado esperado:** Selector con sus cursos (GET /api/cursos-administrables), sin escribir IDs. Si pide escribir el ID → BLOQUEADO.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-17
- **Evidencia:** [CP-UI-19_docente_selector_curso.png](../evidencias/capturas/CP-UI-19_docente_selector_curso.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)

### CP-UI-20

**✅ APROBADO** — El Dashboard sigue funcionando cuando el motor falla

- **Requisito:** RF-08 — Dashboard y progreso del estudiante
- **Módulo / área:** Frontend · Robustez · Funcional (E2E) · prioridad Alta
- **Responsable:** Yuleidy De Los Santos
- **Pasos:** Con Python no disponible, iniciar sesión como estudiante demo.
- **Datos:** PYTHON_EXECUTABLE inválido
- **Resultado esperado:** El Dashboard muestra los datos sin la tarjeta del motor, sin mensaje de error técnico.
- **Resultado real:** Coincide con el esperado.
- **Incidencias:** INC-15
- **Evidencia:** [CP-UI-20_dashboard_motor_caido.png](../evidencias/capturas/CP-UI-20_dashboard_motor_caido.png) · [04_e2e.log](../evidencias/logs/04_e2e.log)
