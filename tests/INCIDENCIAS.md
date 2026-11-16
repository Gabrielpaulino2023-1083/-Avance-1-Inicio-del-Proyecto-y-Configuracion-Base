# Listado de incidencias — Motor de Aprendizaje Adaptativo — Grupo 4

Generado el 16 de noviembre de 2026 a las 4:15 p. m. a partir de `tests/matriz/incidencias.json`. Para cambiar el estado de una incidencia, editar ese JSON y volver a ejecutar `npm test`: la columna "Última verificación" se actualiza sola con el resultado de la re-prueba.

| ID | Título | Tipo | Severidad | Responsable | Estado | Casos |
|---|---|---|---|---|---|---|
| [INC-01](#inc-01) | El backend no tiene CORS: el login real desde el navegador falla | Defecto | Alta | Porfirio Ramírez | Verificada | CP-UI-01 |
| [INC-02](#inc-02) | JSON mal formado devuelve un mensaje técnico en inglés en vez de 'JSON inválido' | Defecto | Baja | Porfirio Ramírez | Abierta | CP-LOG-06, CP-BE-07 |
| [INC-03](#inc-03) | Motor: si el JSON no es un objeto, Python termina con traceback y no con JSON de error | Defecto | Media | Daniel Beltre | Abierta | CP-VAL-14 |
| [INC-04](#inc-04) | Motor: acepta Infinity y devuelve un JSON que Node no puede leer | Defecto | Media | Daniel Beltre | Abierta | CP-VAL-09, CP-VAL-15 |
| [INC-05](#inc-05) | Motor: falta de student_id o topic produce KeyError sin mensaje claro | Defecto | Baja | Daniel Beltre | Abierta | CP-VAL-07 |
| [INC-06](#inc-06) | Motor: acepta true/false como números (true = 1 %) | Defecto | Baja | Daniel Beltre | Abierta | CP-VAL-10 |
| [INC-07](#inc-07) | Motor: los conteos con decimales se truncan en silencio | Defecto | Baja | Daniel Beltre | Abierta | CP-VAL-11 |
| [INC-08](#inc-08) | Dashboard y Progreso en modo real usan endpoints que no existen | Integración pendiente | Alta | Porfirio Ramírez (endpoints) y Yuleidy De Los Santos (pantalla) | Verificada | CP-CRUD-08 |
| [INC-09](#inc-09) | No hay endpoints para listar, actualizar, cambiar el rol ni eliminar usuarios | Integración pendiente | Media | Porfirio Ramírez | Pendiente de desarrollo | CP-CRUD-06, CP-CRUD-07 |
| [INC-10](#inc-10) | Las operaciones académicas de la base de datos no están expuestas por HTTP | Integración pendiente | Media | Porfirio Ramírez y Jeison Rosario | Verificada | CP-CRUD-09 |
| [INC-11](#inc-11) | El backend todavía no llama al motor adaptativo (POST /api/adaptive/analyze) | Integración pendiente | Alta | Porfirio Ramírez y Daniel Beltre | Verificada | CP-MOT-11, CP-ADP-01, CP-ADP-02, CP-ADP-03 |
| [INC-12](#inc-12) | Los ejercicios no envían tiempo, intentos ni errores al backend | Integración pendiente | Media | Yuleidy De Los Santos y Porfirio Ramírez | Pendiente de desarrollo | CP-UI-11 |
| [INC-13](#inc-13) | Cuerpo demasiado grande responde en inglés y su rama 413 nunca se ejecuta | Defecto | Baja | Porfirio Ramírez | Abierta | CP-BE-10 |
| [INC-14](#inc-14) | Rutas inexistentes bajo /api responden 401 en lugar de 404 | Defecto | Baja | Porfirio Ramírez | Abierta | CP-BE-09 |
| [INC-15](#inc-15) | El Dashboard se rompe cuando no hay recomendación (estudiante sin intentos o motor caído) | Defecto | Alta | Yuleidy De Los Santos | Abierta | CP-UI-13, CP-UI-20 |
| [INC-16](#inc-16) | El Dashboard real se marca como 'Datos de ejemplo' y la actividad reciente es simulada | Defecto | Media | Yuleidy De Los Santos | Abierta | CP-UI-09 |
| [INC-17](#inc-17) | El docente debe escribir el ID numérico del curso para gestionar contenido | Integración pendiente | Media | Yuleidy De Los Santos | Pendiente de desarrollo | CP-UI-19 |

**Tipos:** *Defecto* = el código hace algo distinto de lo esperado. *Integración pendiente* = falta una pieza; sus casos quedan BLOQUEADOS, no fallidos.

**Estados:** Abierta → En progreso → Resuelta (pendiente de verificar) → Verificada (QA repitió el caso y pasó). *Pendiente de desarrollo* = integración aún no construida.

## INC-01

### El backend no tiene CORS: el login real desde el navegador falla

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Alta |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Verificada** |
| Casos asociados | CP-UI-01 |
| Última verificación | CP-UI-01: APROBADO |

**Historial.** Registrada el 10/11/2026 (avance 3). Corregida en main: backend/src/app.js usa cors con CORS_ORIGIN. Re-prueba del 16/11/2026: CP-UI-01 aprobado (login real desde el navegador).

**Descripción.** El frontend (http://localhost:5173) y el backend (http://localhost:3000) están en orígenes distintos. El navegador hace una petición previa (preflight OPTIONS) y el backend no responde con Access-Control-Allow-Origin, así que el navegador bloquea el login. frontend/README.md afirma que 'el backend permite ese origen mediante CORS_ORIGIN', pero esa variable y el middleware cors no existen en backend/.

**Pasos para reproducir.** 1) npm start en backend. 2) En frontend/.env.local poner VITE_USE_MOCK=false. 3) npm run dev. 4) Iniciar sesión con la cuenta demo.

**Resultado esperado.** Entra al Dashboard.

**Resultado obtenido.** 'No se pudo conectar con el servidor. Verifica que el backend esté encendido.' Consola: 'blocked by CORS policy: No Access-Control-Allow-Origin header'.

**Evidencia.** [evidencias/capturas/CP-UI-01_login_real_con_cors.png](evidencias/capturas/CP-UI-01_login_real_con_cors.png)

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

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (errorHandler.js sin cambios en esa rama).

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
| Responsable | Daniel Beltre |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-14 |
| Última verificación | CP-VAL-14: FALLIDO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (engine.py y analysis/analyzer.py sin cambios; main.py solo cambió espacios).

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
| Responsable | Daniel Beltre |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-09, CP-VAL-15 |
| Última verificación | CP-VAL-09: FALLIDO, CP-VAL-15: FALLIDO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (engine.py y analysis/analyzer.py sin cambios; main.py solo cambió espacios).

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
| Responsable | Daniel Beltre |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-07 |
| Última verificación | CP-VAL-07: FALLIDO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (engine.py y analysis/analyzer.py sin cambios; main.py solo cambió espacios).

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
| Responsable | Daniel Beltre |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-10 |
| Última verificación | CP-VAL-10: FALLIDO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (engine.py y analysis/analyzer.py sin cambios; main.py solo cambió espacios).

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
| Responsable | Daniel Beltre |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-VAL-11 |
| Última verificación | CP-VAL-11: FALLIDO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: sigue igual (engine.py y analysis/analyzer.py sin cambios; main.py solo cambió espacios).

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
| Estado de resolución | **Verificada** |
| Casos asociados | CP-CRUD-08 |
| Última verificación | CP-CRUD-08: APROBADO |

**Historial.** Registrada el 10/11/2026. Corregida en main (PR #16): GET /api/students/:id y /progress con datos reales. Re-prueba del 16/11/2026: CP-CRUD-08 aprobado. Los defectos que quedan en la pantalla se registran en INC-15 e INC-16.

**Descripción.** frontend/src/services/dashboardService.ts llama GET /api/students/:id y GET /api/students/:id/progress. El backend solo tiene /api/health y /api/auth/*. En modo real, Dashboard y Progreso muestran solo 'Ruta no encontrada' (mensaje técnico para el estudiante).

**Pasos para reproducir.** Modo real (VITE_USE_MOCK=false), iniciar sesión y abrir el Dashboard.

**Resultado esperado.** Resumen del estudiante con datos de la base.

**Resultado obtenido.** 404 y el texto 'Ruta no encontrada' en pantalla.

**Evidencia.** [evidencias/capturas/CP-UI-09_dashboard_datos_reales.png](evidencias/capturas/CP-UI-09_dashboard_datos_reales.png) · [evidencias/capturas/CP-UI-07c_progreso.png](evidencias/capturas/CP-UI-07c_progreso.png)

**Corrección sugerida.** Implementar ambos endpoints con el contrato que espera el frontend (campos en español). Mientras tanto, el frontend podría mostrar un mensaje amigable o volver a los datos simulados ante un 404.

## INC-09

### No hay endpoints para listar, actualizar, cambiar el rol ni eliminar usuarios

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Media |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-CRUD-06, CP-CRUD-07 |
| Última verificación | CP-CRUD-06: BLOQUEADO, CP-CRUD-07: BLOQUEADO |

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: siguen sin existir PATCH /api/users/:id/role, DELETE /api/users/:id ni GET /api/students.

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
| Responsable | Porfirio Ramírez y Jeison Rosario |
| Estado de resolución | **Verificada** |
| Casos asociados | CP-CRUD-09 |
| Última verificación | CP-CRUD-09: APROBADO |

**Historial.** Registrada el 10/11/2026. Corregida en main: rutas /api/mis-cursos, /mis-inscripciones, /mis-intentos y /mis-respuestas. Re-prueba del 16/11/2026: CP-CRUD-09 aprobado (intento real calificado al 100 % y guardado en PostgreSQL).

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
| Responsable | Porfirio Ramírez y Daniel Beltre |
| Estado de resolución | **Verificada** |
| Casos asociados | CP-MOT-11, CP-ADP-01, CP-ADP-02, CP-ADP-03 |
| Última verificación | CP-MOT-11: APROBADO, CP-ADP-01: APROBADO, CP-ADP-02: APROBADO, CP-ADP-03: APROBADO |

**Historial.** Registrada el 10/11/2026. Corregida en main: engineClient.js ejecuta python main.py --stdin; rutas POST /api/students/:id/recommendation y /mis-inscripciones/:id/temas/:temaId/recomendacion. Re-prueba del 16/11/2026: CP-MOT-11 y CP-ADP-01 a 09 aprobados.

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

**Historial.** Registrada el 10/11/2026. Re-prueba del 16/11/2026: la pantalla ahora pide la recomendación al motor real, pero solo envía el tema; tiempo, intentos y errores del ejercicio no se guardan.

**Descripción.** ExercisePanel mide tiempo, intentos y errores, pero solo los muestra. No hay endpoint para registrarlos, así que el motor no recibe datos reales del estudiante. Está declarado como pendiente en frontend/README.md.

**Pasos para reproducir.** Responder el ejercicio de /contenido en modo real y observar la red.

**Resultado esperado.** Una petición con las métricas.

**Resultado obtenido.** POST /api/students/:id/recommendation con el cuerpo {"topic":"SQL JOIN"} únicamente.

**Evidencia.** [evidencias/capturas/CP-UI-12c_recomendacion_del_motor.png](evidencias/capturas/CP-UI-12c_recomendacion_del_motor.png)

**Corrección sugerida.** Definir el endpoint (o reutilizar intentos/respuestas de la BD, como indica el contrato) y llamarlo al comprobar la respuesta.

## INC-13

### Cuerpo demasiado grande responde en inglés y su rama 413 nunca se ejecuta

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-BE-10 |
| Última verificación | CP-BE-10: FALLIDO |

**Historial.** Detectada el 16/11/2026 al probar los cambios del avance 4.

**Descripción.** En errorHandler.js el bloque de 'entity.too.large' quedó después de res.status(500) y de un return implícito, así que nunca se alcanza. Además el error de body-parser trae status 413 y entra antes por 'if (err.status)', devolviendo el mensaje interno en inglés.

**Pasos para reproducir.** POST /api/auth/login con un cuerpo JSON de más de 100 KB.

**Resultado esperado.** 413 'El cuerpo de la petición es demasiado grande'.

**Resultado obtenido.** 413 'request entity too large'.

**Evidencia.** [evidencias/logs/03_integracion.log](evidencias/logs/03_integracion.log)

**Corrección sugerida.** Mover las comprobaciones de err.type ('entity.parse.failed', 'entity.too.large') al inicio del errorHandler, antes de 'if (err.status)'. Corrige también INC-02.

## INC-14

### Rutas inexistentes bajo /api responden 401 en lugar de 404

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Baja |
| Módulo | Backend / API |
| Responsable | Porfirio Ramírez |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-BE-09 |
| Última verificación | CP-BE-09: FALLIDO |

**Historial.** Detectada el 16/11/2026.

**Descripción.** app.use('/api', contentRoutes) monta un router con router.use(verifyToken) para TODO /api. Cualquier ruta que no exista, sin token, responde 401 'Token requerido' en vez de 404, lo que confunde al depurar el frontend.

**Pasos para reproducir.** GET /api/no-existe sin cabecera Authorization.

**Resultado esperado.** 404 'Ruta no encontrada'.

**Resultado obtenido.** 401.

**Evidencia.** [evidencias/logs/03_integracion.log](evidencias/logs/03_integracion.log)

**Corrección sugerida.** Aplicar verifyToken en cada ruta de contentRoutes (o montar el router en prefijos concretos como /api/modulos y /api/temas) en vez de router.use(verifyToken) sobre /api.

## INC-15

### El Dashboard se rompe cuando no hay recomendación (estudiante sin intentos o motor caído)

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Alta |
| Módulo | Frontend |
| Responsable | Yuleidy De Los Santos |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-UI-13, CP-UI-20 |
| Última verificación | CP-UI-13: FALLIDO, CP-UI-20: FALLIDO |

**Historial.** Detectada el 16/11/2026. Afecta a todo estudiante nuevo.

**Descripción.** GET /api/students/:id/progress devuelve recomendacion: null cuando el estudiante no tiene intentos calificados o cuando el motor falla (comportamiento correcto del backend). dashboardService.ts lee r.tema sin comprobar null, y toda la pantalla queda reemplazada por un error técnico.

**Pasos para reproducir.** 1) Registrar un estudiante nuevo e iniciar sesión (modo real). 2) O bien, con el estudiante demo, detener Python o configurar mal PYTHON_EXECUTABLE.

**Resultado esperado.** El Dashboard muestra los datos disponibles y omite (o explica) la tarjeta del motor.

**Resultado obtenido.** Pantalla con 'Cannot read properties of null (reading 'tema')'.

**Evidencia.** [evidencias/capturas/CP-UI-13a_dashboard_sin_datos.png](evidencias/capturas/CP-UI-13a_dashboard_sin_datos.png) · [evidencias/capturas/CP-UI-20_dashboard_motor_caido.png](evidencias/capturas/CP-UI-20_dashboard_motor_caido.png)

**Corrección sugerida.** En toDashboardSummary: si progress.recomendacion es null, devolver recommendation/evidence = null y que DashboardScreen no muestre la tarjeta (o muestre 'Aún no hay datos para recomendar').

## INC-16

### El Dashboard real se marca como 'Datos de ejemplo' y la actividad reciente es simulada

| Campo | Valor |
|---|---|
| Tipo | Defecto |
| Severidad | Media |
| Módulo | Frontend |
| Responsable | Yuleidy De Los Santos |
| Estado de resolución | **Abierta** |
| Casos asociados | CP-UI-09 |
| Última verificación | CP-UI-09: FALLIDO |

**Historial.** Detectada el 16/11/2026.

**Descripción.** DashboardScreen pasa sample=true a RecommendationCard siempre, por eso la tarjeta muestra el chip 'Datos de ejemplo' aunque los valores (16.7 %, 10 errores) vienen del motor real. 'Actividad reciente' usa MOCK_ACTIVITY aunque existe GET /api/mis-inscripciones/:id/actividad-reciente, y el texto del anillo dice que el progreso son 'datos de ejemplo'.

**Pasos para reproducir.** Modo real, iniciar sesión como estudiante demo y revisar el Dashboard.

**Resultado esperado.** Sin etiquetas de ejemplo cuando los datos son reales; actividad reciente tomada del backend.

**Resultado obtenido.** Chip 'Datos de ejemplo' en la tarjeta del motor y actividad reciente ficticia ('SQL JOIN: 55 % de aciertos').

**Evidencia.** [evidencias/capturas/CP-UI-09_dashboard_datos_reales.png](evidencias/capturas/CP-UI-09_dashboard_datos_reales.png)

**Corrección sugerida.** Pasar sample solo en modo simulado (USE_MOCK) y conectar 'Actividad reciente' a /actividad-reciente.

## INC-17

### El docente debe escribir el ID numérico del curso para gestionar contenido

| Campo | Valor |
|---|---|
| Tipo | Integración pendiente |
| Severidad | Media |
| Módulo | Frontend |
| Responsable | Yuleidy De Los Santos |
| Estado de resolución | **Pendiente de desarrollo** |
| Casos asociados | CP-UI-19 |
| Última verificación | CP-UI-19: BLOQUEADO |

**Historial.** Registrada el 16/11/2026. El CRUD del docente sí funciona escribiendo el ID (CP-UI-17 aprobado).

**Descripción.** En /gestion el administrador elige el curso de una lista, pero el docente tiene un campo 'ID del curso' y un botón 'Cargar'. El backend ya ofrece GET /api/cursos-administrables con los cursos del docente (DEMO-006). El README de database lo declara pendiente.

**Pasos para reproducir.** Iniciar sesión como docente.demo@example.com y abrir Contenido.

**Resultado esperado.** Selector con los cursos que el docente puede editar.

**Resultado obtenido.** Campo numérico; hay que saber el ID interno (3).

**Evidencia.** [evidencias/capturas/CP-UI-19_docente_selector_curso.png](evidencias/capturas/CP-UI-19_docente_selector_curso.png)

**Corrección sugerida.** Usar el mismo <select> del administrador, cargado con GET /api/cursos-administrables, también para el docente.
