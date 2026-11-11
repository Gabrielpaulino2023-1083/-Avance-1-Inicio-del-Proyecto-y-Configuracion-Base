# Listado de incidencias — Motor de Aprendizaje Adaptativo — Grupo 4

Generado el 10 de noviembre de 2026 a las 12:01 p. m. a partir de `tests/matriz/incidencias.json`. Para cambiar el estado de una incidencia, editar ese JSON y volver a ejecutar `npm test`.

| ID | Título | Tipo | Severidad | Módulo | Responsable | Estado | Casos |
|---|---|---|---|---|---|---|---|
| [INC-01](#inc-01) | El backend no tiene CORS: el login real desde el navegador falla | Defecto | Alta | Backend / API | Porfirio Ramírez | Abierta | CP-UI-01 |
| [INC-02](#inc-02) | JSON mal formado devuelve un mensaje técnico en inglés en vez de 'JSON inválido' | Defecto | Baja | Backend / API | Porfirio Ramírez | Abierta | CP-LOG-06, CP-BE-07 |
| [INC-03](#inc-03) | Motor: si el JSON no es un objeto, Python termina con traceback y no con JSON de error | Defecto | Media | Motor adaptativo | Daniel Beltre (por confirmar) | Abierta | CP-VAL-14 |
| [INC-04](#inc-04) | Motor: acepta Infinity y devuelve un JSON que Node no puede leer | Defecto | Media | Motor adaptativo | Daniel Beltre (por confirmar) | Abierta | CP-VAL-09, CP-VAL-15 |
| [INC-05](#inc-05) | Motor: falta de student_id o topic produce KeyError sin mensaje claro | Defecto | Baja | Motor adaptativo | Daniel Beltre (por confirmar) | Abierta | CP-VAL-07 |
| [INC-06](#inc-06) | Motor: acepta true/false como números (true = 1 %) | Defecto | Baja | Motor adaptativo | Daniel Beltre (por confirmar) | Abierta | CP-VAL-10 |
| [INC-07](#inc-07) | Motor: los conteos con decimales se truncan en silencio | Defecto | Baja | Motor adaptativo | Daniel Beltre (por confirmar) | Abierta | CP-VAL-11 |
| [INC-08](#inc-08) | Dashboard y Progreso en modo real usan endpoints que no existen | Integración pendiente | Alta | Backend / API | Porfirio Ramírez (endpoints) y Yuleidy De Los Santos (pantalla) | Pendiente de desarrollo | CP-UI-09, CP-CRUD-08 |
| [INC-09](#inc-09) | No hay endpoints para actualizar, cambiar el rol ni eliminar usuarios | Integración pendiente | Media | Backend / API | Porfirio Ramírez | Pendiente de desarrollo | CP-CRUD-06, CP-CRUD-07 |
| [INC-10](#inc-10) | Las operaciones académicas de la base de datos no están expuestas por HTTP | Integración pendiente | Media | Backend / API | Porfirio Ramírez y Jeison Rosario (por confirmar) | Pendiente de desarrollo | CP-CRUD-09 |
| [INC-11](#inc-11) | El backend todavía no llama al motor adaptativo (POST /api/adaptive/analyze) | Integración pendiente | Alta | Backend / API | Porfirio Ramírez y Daniel Beltre (por confirmar) | Pendiente de desarrollo | CP-MOT-11 |
| [INC-12](#inc-12) | Los ejercicios no envían tiempo, intentos ni errores al backend | Integración pendiente | Media | Frontend | Yuleidy De Los Santos y Porfirio Ramírez | Pendiente de desarrollo | CP-UI-11 |

**Tipos:** *Defecto* = el código hace algo distinto de lo esperado. *Integración pendiente* = falta una pieza (endpoint, conexión); sus casos quedan BLOQUEADOS, no fallidos.

## INC-01

### El backend no tiene CORS: el login real desde el navegador falla

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Alta |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-UI-01 |
| Última verificación | CP-UI-01: FALLIDO |

**Descripción.** El frontend (http://localhost:5173) y el backend (http://localhost:3000) están en orígenes distintos. El navegador hace una petición previa (preflight OPTIONS) y el backend no responde con Access-Control-Allow-Origin, así que el navegador bloquea el login. frontend/README.md afirma que 'el backend permite ese origen mediante CORS_ORIGIN', pero esa variable y el middleware cors no existen en backend/.

**Pasos para reproducir.** 1) npm start en backend. 2) En frontend/.env.local poner VITE_USE_MOCK=false. 3) npm run dev. 4) Iniciar sesión con la cuenta demo.

**Resultado esperado.** Entra al Dashboard.

**Resultado obtenido.** 'No se pudo conectar con el servidor. Verifica que el backend esté encendido.' Consola: 'blocked by CORS policy: No Access-Control-Allow-Origin header'.

**Evidencia.** [evidencias/capturas/CP-UI-01_login_real_sin_cors.png](evidencias/capturas/CP-UI-01_login_real_sin_cors.png) · [evidencias/logs/e2e_consola_navegador.log](evidencias/logs/e2e_consola_navegador.log)

**Corrección sugerida.** En backend: npm install cors; en app.js, antes de las rutas: app.use(require('cors')({ origin: (process.env.CORS_ORIGIN || 'http://localhost:5173').split(',') })); y añadir CORS_ORIGIN=http://localhost:5173 a .env.example. Alternativa solo para desarrollo: proxy '/api' en frontend/vite.config.ts.

## INC-02

### JSON mal formado devuelve un mensaje técnico en inglés en vez de 'JSON inválido'

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-LOG-06, CP-BE-07 |
| Última verificación | CP-LOG-06: FALLIDO, CP-BE-07: FALLIDO |

**Descripción.** En middlewares/errorHandler.js la primera condición es 'if (err.status)'. El error que produce express.json() ya trae status 400, así que entra por ahí y nunca llega a la rama 'entity.parse.failed'. Resultado: el cliente recibe el mensaje interno del parser.

**Pasos para reproducir.** POST /api/auth/login con el cuerpo '{"email": ' y Content-Type application/json.

**Resultado esperado.** 400 { success:false, message:'JSON inválido' }

**Resultado obtenido.** 400 { success:false, message:'Unexpected end of JSON input' }

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-log-06](reportes/REPORTE_DE_PRUEBAS.md#cp-log-06)

**Corrección sugerida.** Mover la comprobación de err.type === 'entity.parse.failed' ANTES de 'if (err.status)', o usar 'if (err instanceof AppError)' en la primera rama.

## INC-03

### Motor: si el JSON no es un objeto, Python termina con traceback y no con JSON de error

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Media |
| Módulo | Motor adaptativo |
| Responsable | Daniel Beltre (por confirmar) |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-14 |
| Última verificación | CP-VAL-14: FALLIDO |

**Descripción.** analyzer.py llama student_data.get(...) sin comprobar que sea un diccionario. Con [], "texto", 5 o null se lanza AttributeError, que main.py no captura (solo captura ValueError, KeyError, TypeError y JSONDecodeError). Se rompe el contrato de INTEGRATION.md (errores como JSON por stderr), y el backend no podrá interpretar el error.

**Pasos para reproducir.** echo [] | python main.py --stdin

**Resultado esperado.** Código 1 y {"error": "..."} en stderr.

**Resultado obtenido.** Traceback de Python: AttributeError: 'list' object has no attribute 'get'.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-val-14](reportes/REPORTE_DE_PRUEBAS.md#cp-val-14)

**Corrección sugerida.** Al inicio de analyze_behavior: if not isinstance(student_data, dict): raise ValueError('Los datos del estudiante deben ser un objeto JSON.')

## INC-04

### Motor: acepta Infinity y devuelve un JSON que Node no puede leer

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Media |
| Módulo | Motor adaptativo |
| Responsable | Daniel Beltre (por confirmar) |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-09, CP-VAL-15 |
| Última verificación | CP-VAL-09: FALLIDO, CP-VAL-15: FALLIDO |

**Descripción.** json.load de Python acepta Infinity/NaN. NaN se rechaza, pero Infinity pasa la validación (inf ≥ 0) y la salida contiene 'average_study_minutes: Infinity', que no es JSON estándar: JSON.parse en Node falla.

**Pasos para reproducir.** Enviar study_minutes: Infinity por --stdin.

**Resultado esperado.** Rechazo con código 1 y mensaje de datos inválidos.

**Resultado obtenido.** Código 0 y salida con 'Infinity'.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-val-15](reportes/REPORTE_DE_PRUEBAS.md#cp-val-15)

**Corrección sugerida.** En analyzer.py añadir: if not np.isfinite(df[required_columns]).all().all(): raise ValueError(...). En main.py usar json.dumps(..., allow_nan=False).

## INC-05

### Motor: falta de student_id o topic produce KeyError sin mensaje claro

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Motor adaptativo |
| Responsable | Daniel Beltre (por confirmar) |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-07 |
| Última verificación | CP-VAL-07: FALLIDO |

**Descripción.** Los seis campos de interacción se validan con un mensaje claro, pero student_id y topic se leen con student_data['...']. Sin ellos se lanza KeyError y la CLI responde {"error": "'topic'"}.

**Pasos para reproducir.** process_student({'student_id': 1, 'interactions': [...]})

**Resultado esperado.** ValueError 'Faltan campos obligatorios: topic'.

**Resultado obtenido.** KeyError('topic').

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-val-07](reportes/REPORTE_DE_PRUEBAS.md#cp-val-07)

**Corrección sugerida.** Validar student_id y topic al inicio junto con interactions.

## INC-06

### Motor: acepta true/false como números (true = 1 %)

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Motor adaptativo |
| Responsable | Daniel Beltre (por confirmar) |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-10 |
| Última verificación | CP-VAL-10: FALLIDO |

**Descripción.** pd.to_numeric convierte booleanos en 1/0. score_percentage=true se interpreta como 1 % y genera una recomendación de refuerzo con datos que no son una puntuación.

**Pasos para reproducir.** Interacción con score_percentage: true.

**Resultado esperado.** ValueError de datos inválidos.

**Resultado obtenido.** Se procesa con promedio 1.0 y acción reinforce_topic.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-val-10](reportes/REPORTE_DE_PRUEBAS.md#cp-val-10)

**Corrección sugerida.** Rechazar columnas con valores bool antes de to_numeric (p. ej. df[c].map(type).eq(bool).any()).

## INC-07

### Motor: los conteos con decimales se truncan en silencio

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Motor adaptativo |
| Responsable | Daniel Beltre (por confirmar) |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-11 |
| Última verificación | CP-VAL-11: FALLIDO |

**Descripción.** errors, attempts, repetitions y navigation_count son conteos, pero se aceptan decimales. total_errors usa int(), así que 2.7 se convierte en 2 sin avisar y puede cambiar la regla aplicada.

**Pasos para reproducir.** Interacción con errors: 2.7.

**Resultado esperado.** ValueError: los conteos deben ser enteros.

**Resultado obtenido.** total_errors = 2.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-val-11](reportes/REPORTE_DE_PRUEBAS.md#cp-val-11)

**Corrección sugerida.** Comprobar (df[conteos] % 1 == 0).all().all() o acordar con el equipo que se redondea.

## INC-08

### Dashboard y Progreso en modo real usan endpoints que no existen

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Alta |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez (endpoints) y Yuleidy De Los Santos (pantalla) |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-UI-09, CP-CRUD-08 |
| Última verificación | CP-CRUD-08: BLOQUEADO, CP-UI-09: BLOQUEADO |

**Descripción.** frontend/src/services/dashboardService.ts llama GET /api/students/:id y GET /api/students/:id/progress. El backend solo tiene /api/health y /api/auth/*. En modo real, Dashboard y Progreso muestran solo 'Ruta no encontrada' (mensaje técnico para el estudiante).

**Pasos para reproducir.** Modo real (VITE_USE_MOCK=false), iniciar sesión y abrir el Dashboard.

**Resultado esperado.** Resumen del estudiante con datos de la base.

**Resultado obtenido.** 404 y el texto 'Ruta no encontrada' en pantalla.

**Evidencia.** [evidencias/capturas/CP-UI-09_dashboard_datos_reales.png](evidencias/capturas/CP-UI-09_dashboard_datos_reales.png) · [evidencias/capturas/CP-UI-07c_progreso.png](evidencias/capturas/CP-UI-07c_progreso.png)

**Corrección sugerida.** Implementar ambos endpoints con el contrato que espera el frontend (campos en español). Mientras tanto, el frontend podría mostrar un mensaje amigable o volver a los datos simulados ante un 404.

## INC-09

### No hay endpoints para actualizar, cambiar el rol ni eliminar usuarios

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Media |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-CRUD-06, CP-CRUD-07 |
| Última verificación | CP-CRUD-06: BLOQUEADO, CP-CRUD-07: BLOQUEADO |

**Descripción.** Existen dtos/user.dto.js (changeRoleDto) y el permiso users:change-role, pero ninguna ruta los usa. El CRUD de usuarios disponible es solo Crear (registro) y Leer (/me).

**Pasos para reproducir.** PATCH /api/users/:id/role y DELETE /api/users/:id

**Resultado esperado.** Endpoints protegidos por permiso.

**Resultado obtenido.** 404 Ruta no encontrada.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-crud-06](reportes/REPORTE_DE_PRUEBAS.md#cp-crud-06)

**Corrección sugerida.** Crear userRoutes con requirePermission('users:change-role') y validate(changeRoleDto).

## INC-10

### Las operaciones académicas de la base de datos no están expuestas por HTTP

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Media |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez y Jeison Rosario (por confirmar) |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-CRUD-09 |
| Última verificación | CP-CRUD-09: BLOQUEADO |

**Descripción.** inscribir_estudiante, iniciar_intento, guardar_opciones_respuesta, entregar_intento, calificar_intento y la vista resultados_actividades funcionan en SQL (CP-BD-01/02 aprobados), pero no hay rutas de Express que las usen.

**Pasos para reproducir.** Buscar rutas de inscripción, intentos y resultados.

**Resultado esperado.** Rutas que llamen a las funciones con el estudiante tomado del token.

**Resultado obtenido.** 404.

**Evidencia.** [evidencias/logs/sql_pruebas_migracion_003.log](evidencias/logs/sql_pruebas_migracion_003.log)

**Corrección sugerida.** Seguir database/docs/CONTRATO_INTEGRACION_BD.md (consultas parametrizadas $1, $2…).

## INC-11

### El backend todavía no llama al motor adaptativo (POST /api/adaptive/analyze)

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Alta |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez y Daniel Beltre (por confirmar) |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-MOT-11 |
| Última verificación | CP-MOT-11: BLOQUEADO |

**Descripción.** INTEGRATION.md propone el endpoint y el mecanismo (Node ejecuta python main.py --stdin). La parte Python ya funciona (CP-MOT-09 aprobado), falta la ruta en Express.

**Pasos para reproducir.** POST /api/adaptive/analyze con token.

**Resultado esperado.** 200 con profile y recommendation.

**Resultado obtenido.** 404.

**Evidencia.** [reportes/REPORTE_DE_PRUEBAS.md#cp-mot-11](reportes/REPORTE_DE_PRUEBAS.md#cp-mot-11)

**Corrección sugerida.** Implementar con child_process.spawn, timeout y manejo del código de salida. Corregir antes INC-03 e INC-04 para que los errores lleguen siempre como JSON.

## INC-12

### Los ejercicios no envían tiempo, intentos ni errores al backend

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Media |
| Módulo | Frontend |
| Responsable | Yuleidy De Los Santos y Porfirio Ramírez |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-UI-11 |
| Última verificación | CP-UI-11: BLOQUEADO |

**Descripción.** ExercisePanel mide tiempo, intentos y errores, pero solo los muestra. No hay endpoint para registrarlos, así que el motor no recibe datos reales del estudiante. Está declarado como pendiente en frontend/README.md.

**Pasos para reproducir.** Responder el ejercicio de /contenido en modo real y observar la red.

**Resultado esperado.** Una petición con las métricas.

**Resultado obtenido.** Ninguna petición.

**Evidencia.** [evidencias/capturas/CP-UI-10b_ejercicio_correcto.png](evidencias/capturas/CP-UI-10b_ejercicio_correcto.png)

**Corrección sugerida.** Definir el endpoint (o reutilizar intentos/respuestas de la BD, como indica el contrato) y llamarlo al comprobar la respuesta.
