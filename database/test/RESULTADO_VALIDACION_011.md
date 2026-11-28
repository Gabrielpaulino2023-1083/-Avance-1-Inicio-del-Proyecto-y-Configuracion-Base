# Validación local preparada — BD-011-v1

Fecha documental: 27 de noviembre de 2026. Fuente del contrato backend revisada: main a8accad8f494c5050564e9dbd97535479e98d407. Dependencia SQL: 001–010.

Pruebas ejecutadas por el asistente en PostgreSQL **18.6 nativo Linux x86_64**, con varias conexiones pg sobre un servidor temporal aislado. No se modificaron bases del usuario ni GitHub. No se ejecutó psql nativo en Windows: el arnés aplicó SQL retirando metacomandos y sustituyendo parámetros.

| Comprobación | Resultado |
|---|---|
| Instalación 001–010 y seguridad | Correcta |
| Aplicación de 011 con datos existentes | Correcta; 17 tablas sin cambios y funciones anteriores intactas |
| Pruebas funcionales 011 | 49 comprobaciones, dos ejecuciones aprobadas |
| Regresiones 003–010 | Aprobadas con fixtures y seeds correspondientes |
| Seed y prueba de 010 después de instalar 011 | Correctos; usuarios/hashes conservados y reejecución sin cambios |
| Cierre opcional del registro directo | Aprobado en la base aislada; registrar_estudiante sigue funcionando y el INSERT directo falla 42501 |
| Prueba específica posterior al cierre | Aprobada |
| Concurrencia nativa | Cinco carreras y cuatro comprobaciones aprobadas |

Se comprobaron autorizaciones, privacidad de retornos, filtros/paginación, unicidad, datos inválidos, estado de cuenta, cambios y múltiples roles compatibles, revocación de asignaciones docentes, cambio con intento abierto, conservación del historial, protección del último administrador por funciones/SQL directo y UPDATE/DELETE masivos, además del rechazo de REPEATABLE READ.

Carreras observadas con pg_blocking_pids antes de liberar la primera conexión:

1. Desactivar dos administradores distintos conserva uno activo.
2. Desactivar sus dos roles ADMINISTRADOR conserva uno activo.
3. Asignar simultáneamente ESTUDIANTE y DOCENTE a la misma persona rechaza la combinación.
4. Dos registros del mismo correo confirman uno y rechazan el otro con 23505.
5. Bloquear una cuenta antes de editar su perfil rechaza la edición posterior sin cambiar datos.

Los fixtures concurrentes quedan en una base nueva sin usuarios anteriores, exclusivamente para inspección. No se deshabilitan los triggers para borrar al último administrador. El test debe repetirse en otra base nueva, sin seeds.

Logs incluidos en logs_011/. No contienen contraseñas reales ni tokens. Los hashes de prueba son estructurales y no corresponden a credenciales de login.

Pendiente: conservar logs locales, revisión del contrato por Porfirio, adaptación de registro y autorización JWT, pruebas HTTP de INC-09 y aplicación del cierre de permisos solo cuando corresponda. La confirmación de las pruebas funcionales de 011 se recibió posteriormente, además de la de 010 y ambas suites concurrentes.


## Validación local confirmada por Jeison

- Instalación y pruebas funcionales de 010: resultado esperado.
- Pruebas concurrentes corregidas de 010 y 011 en Windows: resultado esperado.
- Prueba funcional de 011: resultado esperado, después de comprobar/aplicar la migración en la base correcta.
- Base identificada en la comprobación: proyectofinal_revision010_20261127_201103.

Se registra la confirmación del responsable en este chat; los logs finales de Windows no fueron adjuntados a este paquete. Los logs incluidos de PostgreSQL Linux son la evidencia del asistente y se mantienen identificados por separado.

Los errores anteriores (función/tipo ausente en la conexión elegida, intento de repetir un tipo ya existente y guard de variables) forman parte del diagnóstico resuelto; no se deben ocultar ni contar como fallos finales de las reglas SQL. No repetir migraciones en una base ya validada.
