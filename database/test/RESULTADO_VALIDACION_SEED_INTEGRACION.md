# Validación del seed de integración SQL

Fecha: 13 de noviembre de 2026.

## Entorno

PostgreSQL 18.6 embebido en PGlite 0.5.16. Instalación limpia de 001–007 y permisos,
con los seeds anteriores de usuarios, módulos/temas y actividades de 003.
Se ejecutaron las sentencias SQL; las directivas psql se procesaron en el adaptador
de prueba y sus parámetros se sustituyeron por valores de prueba escapados.
No se ejecutó contra la BD local del usuario ni se modificó GitHub.

## Resultados

- Carga completa: cuatro actividades, tres temas, nueve intentos históricos calificados.
- Promedios iniciales: SELECT 91.67, WHERE 66.67, JOIN 16.67; evaluación pendiente NULL.
- Comparación de las 15 tablas con datos previos: todas sus filas originales conservadas.
- Usuarios, roles y asignaciones: sin cambios; hash del estudiante conservado.
- Segunda carga: comparación completa de las 15 tablas sin diferencias.
- Nuevo intento posterior: conservado íntegramente al repetir el seed.
- Cuestionario del seed: leído con 007 como plataforma_backend, sin campos de corrección.
- Archivo de pruebas del seed: aprobado, incluso después de un intento adicional.
- Rechazos atómicos: cuenta ausente/inactiva, referencia futura/infinita y colisión de código.
- Pruebas adicionales en instalaciones nuevas: referencia al inicio del lunes (ocho segundos)
  y al final del domingo aprobadas, sin intentos futuros; rechazos por rol estudiante
  inactivo, hash ficticio, administrador ausente y ejecución como plataforma_backend.
- Motor Python real de main `80815b2`: aumentar dificultad para SELECT, mantener para WHERE,
  reforzar para JOIN. Datos obtenidos de PostgreSQL embebido; no prueba HTTP.

Los resultados iniciales corresponden solo a esta demo. Intentos nuevos pueden cambiar
promedios y recomendaciones. No se generó evidencia de frontend ni del endpoint de producción.

## Validación local del equipo

Pendiente de ejecutar el seed y `pruebas_seed_integracion_resultados.sql` en PostgreSQL local.
Completar versión, base, fecha y resultados después de esa ejecución.
