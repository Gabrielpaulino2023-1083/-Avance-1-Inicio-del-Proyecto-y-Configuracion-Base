# Resultado de validación — 008

**Aprobado en PostgreSQL 18.6 embebido (PGlite 0.5.16).** Se instaló 001–008 con seguridad,
se cargaron los fixtures iniciales y los seeds docente y SQL, y se ejecutó
`pruebas_migracion_008.sql` como plataforma_backend en la parte de consultas.

Se comprobó el selector docente (excluye el curso ajeno), el rechazo a estudiante en ese selector,
la evaluación pendiente con nota NULL, el límite del listado reciente, el progreso JOIN al 50 %,
el reparto de 3 y 6 intentos por semana, los 3 intentos de JOIN con promedio 16.67 y 10 errores
incluso con un tema homónimo, el rechazo a otro estudiante, los límites de fechas y el auxiliar privado.
Se repitieron las pruebas de 007 (72 comprobaciones) y del seed ampliado tras instalar 008.

**Validación local confirmada:** el responsable compartió la salida de psql:

```text
BEGIN
SET
UPDATE 1
SET
PRUEBAS 008 COMPLETADAS: selector, contexto, tablero, motor y permisos.
DO
ROLLBACK
```

El `UPDATE 1` preparó el tema homónimo y el `ROLLBACK` revirtió ese cambio temporal,
sin retirar 008 ni el seed ya cargado.
No se ejecutaron rutas HTTP que consuman 008. La prueba HTTP histórica de SQL JOIN está en
[la evidencia del seed](RESULTADO_VALIDACION_SEED_INTEGRACION.md).
