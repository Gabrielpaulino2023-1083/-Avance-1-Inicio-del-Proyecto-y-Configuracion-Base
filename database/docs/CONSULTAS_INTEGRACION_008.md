# Contrato de consultas de integración — 008

Aplicar después de 007. No agrega tablas, no modifica las funciones existentes y no implementa rutas HTTP. Las consultas se ejecutan desde Express con `plataforma_backend`. Obtener `actorId` de la identidad autenticada; nunca aceptarlo del body ni reemplazarlo con el ID de un estudiante solicitado en la ruta. Las funciones de estudiante son de autoservicio: no delegan acceso a docentes ni administradores. Mantener la autorización de las demás rutas.

| Consulta SQL (`SELECT * FROM public.función(...)`) | Contrato |
|---|---|
| `listar_cursos_administrables(actorId)` | Administrador activo: todos los cursos. Docente activo: solo asignaciones activas de `curso_editores`. Devuelve `curso_id, codigo, nombre, estado, puede_editar_contenido`; archivados en solo lectura. No concede CRUD de cursos al docente. |
| `listar_inscripciones_estudiante(actorId)` | Devuelve `inscripcion_id, curso_id, codigo, curso, edicion_id, seccion_id, seccion`. Solo inscripciones propias activas en cursos activos, sin sección o edición cancelada. |
| `listar_resultados_estudiante(actorId, inscripcionId)` | Una fila por actividad visible, incluidas las pendientes. Conserva resultados calificados de actividades archivadas. Para evaluaciones filtrar `finalidad='EVALUACION'`. Campos: `actividad_id, tema_id, modulo_id, titulo, finalidad, intentos_calificados, promedio_porcentaje, nota_academica_porcentaje, ultima_calificacion_en`. Antes de calificar, los promedios y la fecha quedan en NULL. Las prácticas nunca tienen nota académica. |
| `listar_actividad_reciente_estudiante(actorId, inscripcionId, limite)` | Un evento por intento entregado o calificado, ordenado por fecha descendente. Límite 1–100, por defecto 10. Campos: `intento_id, actividad_id, tema_id, titulo, estado, ocurrido_en, puntaje_porcentaje`. Se usa la fecha de calificación cuando existe; de lo contrario, la de entrega. |
| `listar_progreso_estudiante(actorId, inscripcionId)` | Por módulo/tema publicado: `tema_id, modulo_id, actividades_publicadas, actividades_calificadas, progreso_porcentaje, completado`. Contar una actividad publicada de la sección una sola vez si tiene al menos un intento calificado, sin nota mínima. Sin actividades: porcentaje NULL y completado falso. Nuevas publicaciones pueden cambiar el progreso. |
| `listar_minutos_intentos_estudiante(actorId, inscripcionId, desde, hastaExclusiva)` | Fechas DATE, intervalo semiabierto de hasta 366 días, zona America/Santo_Domingo. Devuelve `dia_local, intentos_entregados, minutos_transcurridos`. Agrupa por día de inicio, cuenta también calificados y omite días vacíos. Es tiempo transcurrido entre inicio y entrega, incluso si hubo pausas; no es medición de tiempo activo. |
| `listar_interacciones_motor_estudiante(actorId, inscripcionId, temaId)` | Una fila por intento calificado en el contexto exacto; sin intentos, cero filas. Columnas: `tema, score_percentage, errors, attempts, repetitions, navigation_count, study_minutes`. Errores = respuestas a cero; attempts = número de intento; repetitions = número menos uno; navigation_count = 0 por falta de medición. Convertir NUMERIC y BIGINT a números para Python, separar `tema` como `topic` y preservar NULL en los DTOs que lo permiten. |

Las consultas de resultados y motor requieren inscripción propia activa. No son consultas de historial para inscripciones retiradas o completadas. SQLSTATE `22023` = parámetros inválidos; `42501` = no autorizado; `P0002` = tema no disponible en el contexto. No exponer el texto interno de errores SQL sin filtrar. La función auxiliar no es invocable por el backend. Solo el backend debe tener credenciales de su rol.

## Cableado sugerido

1. Pasar al frontend los cursos gestionables y las inscripciones mediante rutas autenticadas de Express. Al administrar módulos, enviar siempre el curso seleccionado. Eliminar el fallback silencioso a ID 1.
2. Conectar las cuatro lecturas de [007](LECTURA_ESTUDIANTES_007.md). Para abrir una actividad, ejecutar `iniciar_intento(actividadId, inscripcionId, actorId)` y `obtener_cuestionario_estudiante(actorId, intentoId)` en la misma transacción; hacer rollback si el cuestionario rechaza el contexto. Guardar, entregar y calificar con las funciones existentes. Calificación interna después de entregar un intento autorizado; no aceptar un intento ajeno como objetivo de una ruta de calificación.
3. Adaptar la recomendación para recibir `inscripcionId` y `temaId`. El endpoint antiguo por nombre ya se probó con la demo, pero no distingue homónimos. Mantener o cambiar el contrato HTTP de forma coordinada; 008 no cambia la ruta ni los permisos de aplicación. El frontend utiliza `mastery`, `errors` y `attempts` de la API para la tarjeta real, y etiqueta `attempts` como intentos promedio.
4. Usar los resultados de 008 para las pantallas. No escribir progreso ni minutos en el cliente ni sustituir una nota NULL por cero.

## Base ya validada hasta 007

Desde la raíz del repositorio, con el seed SQL y el docente demo ya cargados y la evaluación de SQL JOIN aún pendiente:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/008_consultas_integracion.sql
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_008.sql
```

Aplicar el primer comando una sola vez. Ejecutar el segundo solo tras `COMMIT`. La prueba revierte todos sus cambios, incluida la preparación de un tema homónimo, y requiere los fixtures del seed inicial, docente y SQL. Si ya se practicó sobre la demo, usar una base independiente para comparar los valores de referencia. Esperar `PRUEBAS 008 COMPLETADAS` y `ROLLBACK`.

## Estado

Instalación y prueba funcional de 008 aprobadas en PostgreSQL embebido con PGlite 0.5.16, con 001–007, seguridad y seeds. 008 también se verificó en PostgreSQL local; queda integrar sus rutas y validar pantallas. La propia demo SQL y 007 se verificaron anteriormente en el PostgreSQL local. No se agrega historial de recomendaciones, telemetría de navegación ni cierre automático de intentos; no hacen falta para el flujo del Avance 3 aquí documentado.
