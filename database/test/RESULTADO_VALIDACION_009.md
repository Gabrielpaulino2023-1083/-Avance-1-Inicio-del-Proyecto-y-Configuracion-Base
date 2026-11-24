# Validación BD-009-v1

Fecha: 22 de noviembre de 2026. Base: main `6fe1ebdaec46536a9227f4cc1c9086aa1f74aa63`.

## Entorno y alcance ejecutado

PostgreSQL 18.6 embebido mediante PGlite 0.5.16; ejecución de SQL con metacomandos psql retirados y parámetros sustituidos en el arnés. JavaScript ejecutado con `node --test`. No se ejecutó psql contra un servidor externo ni se modificó una base del equipo.

| Verificación ejecutada | Resultado |
|---|---|
| Instalación secuencial 001–003, seguridad y 004–009 | Correcta |
| Pruebas SQL de 009 | 34 comprobaciones; dos ejecuciones correctas |
| Regresiones existentes 003, 004, 005, 006, 007 y 008 | Sin errores inesperados |
| Selector JavaScript | 15 pruebas aprobadas |
| Seed nuevo y su prueba SQL como plataforma_backend | Correctos |
| Segunda carga del seed | Sin cambios en filas |
| Reejecución del seed después de iniciar una candidata | Conservó el nuevo intento |
| Comparación de definiciones y firmas anteriores | Sin cambios |
| Contenido previo tras 009 | Sin dificultad asignada automáticamente |
| Intentos y notas anteriores tras 009 | Sin cambios |
| Seed frente a filas previas de 15 tablas | Filas previas conservadas |
| Usuarios, hashes y roles existentes tras el seed | Sin cambios |
| Filas SQL reales pasadas al selector con los tres ajustes | BAJA / MEDIA / ALTA esperadas |
| Inicio real de candidata BAJA y lectura del cuestionario por 007 | Correctos |

Las pruebas abarcan: permisos, contextos ajenos, datos inválidos, estados de publicación, ventanas de disponibilidad, intentos agotados y abiertos (también vencidos), falta de referencia o nivel, referencia explícita y automática, protección de clasificación, ausencia de candidata y desempates. Las comprobaciones complementarias del arnés sumaron 24 verificaciones de compatibilidad y conservación de datos.

## Validación local reportada por el responsable

El 22 de noviembre de 2026, Jeison confirmó que la instalación y comprobaciones en una base nueva dieron los resultados esperados, y que las pruebas y el proceso también fueron aprobados en la base local existente. Esta confirmación es adicional a la ejecución embebida anterior. No se adjuntaron en este mensaje la versión exacta del servidor ni logs nuevos; no se atribuye esta ejecución al asistente.

## Pendiente antes de integrar

- Conservar los logs locales y la versión del servidor como evidencia del PR, si aún no se guardaron.
- Confirmar el contrato de selección con backend y motor.
- Integrar DTO/endpoints en backend y frontend; hacer prueba completa de sugerencia e inicio con el rol plataforma_backend.
- En la prueba final conjunta, confirmar que la diferencia de porcentajes observada anteriormente entre Progreso y la recomendación quedó corregida. Jeison indica que parece resuelta; no se registra aún como verificación concluida.
- Validación concurrente entre sesiones reales si se necesita evidencia de concurrencia. La consulta no reserva cupo ni intentos; iniciar_intento vuelve a validar.

**No se declara integración HTTP o aprobación del equipo.** La instalación y validación local quedan registradas según la confirmación del responsable; las pruebas embebidas siguen documentadas por separado.
