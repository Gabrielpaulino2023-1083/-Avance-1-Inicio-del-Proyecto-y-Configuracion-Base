# Validación de la corrección de concurrencia

Sin cambios en migraciones o reglas. La corrección afecta a los arneses y sus instrucciones.

Validado en servidor PostgreSQL 18.6 nativo Linux x86_64 con search_path inicial del servidor fijado a pg_catalog (sin public). Cada script establece su contexto de sesión y usa funciones cualificadas.

- 010: cuatro carreras y dos comprobaciones aprobadas; limpieza de fixtures correcta.
- 011: cinco carreras y cuatro comprobaciones aprobadas; fixtures conservados en su base aislada.
- Base instalada hasta 009 usada por 010: rechazo de prevalidación; cero usuarios creados.
- Base instalada hasta 011 usada por 010: rechazo antes de crear fixtures; cero usuarios creados.
- DB_NAME ausente en 011: rechazo explícito antes de conectarse.
- BD011_VALIDACION_AISLADA ausente: rechazo explícito antes de conectarse.

Se verificó la sintaxis de los archivos Node. No se dispone de Windows PowerShell en el entorno de pruebas: el lanzador fue revisado, pero Jeison confirmó posteriormente el resultado esperado de ambas suites en Windows. Los logs finales de su equipo no están adjuntos. No se afirma que se reprodujo íntegramente la configuración original del usuario.

La salida adjunta incluye rechazos deliberados con stack trace; son escenarios negativos esperados y aparecen marcados VERIFICADO, seguidos de las dos suites aprobadas. No contienen contraseñas o tokens.
