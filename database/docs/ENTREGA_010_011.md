# Cierre de entrega SQL 010/011 para revisión

## Estado comprobado

| Elemento | Evidencia |
|---|---|
| 010: 20 operaciones públicas editoriales | 67 comprobaciones nativas; validación funcional local confirmada por Jeison |
| 011: 11 operaciones públicas de identidad | 49 comprobaciones nativas; validación funcional local confirmada por Jeison |
| Regresiones 003–009 y compatibilidad con 010/011 | Aprobadas en PostgreSQL 18.6 nativo del asistente |
| Concurrencia corregida 010 | Cuatro carreras y dos comprobaciones; confirmada también en Windows por Jeison |
| Concurrencia corregida 011 | Cinco carreras y cuatro comprobaciones; confirmada también en Windows por Jeison |
| Conservación | Migraciones no cambian filas existentes ni definiciones previas; ver reporte nativo |
| Cierre opcional de registro | Probado solo en entorno aislado del asistente; no aplicado ni confirmado en el backend del equipo |

Los logs finales Windows no se adjuntaron en este chat; se registra la confirmación del responsable. Los archivos logs_010/logs_011 son del entorno Linux del asistente. No convertir uno en evidencia del otro.

## Correcciones incluidas

Prevalidación de firmas/base antes de fixtures; funciones y tablas cualificadas; search_path explícito; mensajes separados de variables ausentes; lanzador de PowerShell con bases nuevas distintas para 010 y 011, restauración del entorno y códigos de salida. Las primeras incidencias de configuración se documentan, no se ocultan. Las migraciones permanecen sin cambios respecto a las versiones probadas.

## Integración pendiente

- Porfirio: endpoints editoriales e INC-09, mapeo de DTOs/errores y comprobación de estado/roles actuales en peticiones con JWT antiguo.
- Registro: sustituir create del modelo por registrar_estudiante, probar registro/login y recién entonces aplicar security/002_cerrar_registro_directo.sql y su prueba específica.
- Yuleidy: pantallas nuevas cuando el contrato HTTP exista; no consumir claves editoriales desde rutas estudiante.
- QA: probar acceso revocado, último administrador, cambio académico, creación/publicación real y regresiones de la API.

No publicar como “INC-09 resuelta” solo porque existe el SQL. No declarar finalizada toda la BD v1: siguen los bloques de asignaciones, ediciones/secciones, inscripciones, intentos, métricas, base central y recuperación.

## Publicación y despliegue

Este paquete es local, sin cambios directos en GitHub. Preparar un PR de revisión sobre main con 010 y 011 en orden, sin migraciones antiguas reescritas ni modificaciones de backend/frontend. Revisar los diff de documentos si el repositorio avanzó desde la base indicada.

El merge no ejecuta SQL. Aplicar cada migración una vez por entorno; no reinstalar en la base local ya validada. Conservar los logs originales y el nombre de base utilizado. La base central aún no se configura en esta entrega.
