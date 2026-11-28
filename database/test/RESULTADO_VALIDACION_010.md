# Validación de la entrega local 010

Fecha: 25 de noviembre de 2026. Base main: `38066d2472fcb9521dcb362f681d76fbb9ccd305`.

**Estado:** validación local confirmada por Jeison; pruebas realizadas por el asistente en un servidor PostgreSQL **nativo 18.6 Linux x86_64**, temporal y aislado. Conexiones independientes mediante pg. También hubo una primera comprobación en PostgreSQL embebido PGlite 0.5.16. No se aplicó SQL a las bases de Jeison ni se publicó código en GitHub.

## Resultado final

| Verificación | Resultado |
|---|---|
| Instalación de 001–009 y seguridad | Correcta |
| Instalación de 010 en esquema vacío de datos de negocio | Correcta en la primera ejecución nativa |
| Actualización desde 009 con usuarios, actividades e intentos previos | Correcta en la ejecución final |
| Comparación de las 17 tablas antes/después de la migración | Sin cambios en filas |
| Definiciones y firmas previas | Sin modificaciones |
| Pruebas 010 como plataforma_backend | 67 comprobaciones aprobadas; dos ejecuciones |
| Regresiones existentes 003, 004, 005, 006, 007, 008 y 009 | Aprobadas con sus fixtures/seeds requeridos |
| Publicación, cuestionario 007, guardado, entrega y calificación reales | 20/20; sin claves en el cuestionario del estudiante |
| Seed 010, prueba de lectura y segunda carga | Aprobados; reejecución sin cambios |
| Usuarios y hashes previos frente al seed | Sin cambios |
| Concurrencia en conexiones separadas | Cuatro carreras aprobadas y dos comprobaciones de contenido |
| Limpieza de fixtures concurrentes | Correcta |

Pruebas de rechazo: estudiante/editor sin sección, sección ajena, asignación/editor/cuenta/rol inactivos, curso archivado, argumentos inválidos, dificultad desconocida, fechas infinitas, puntaje que redondea a cero, total excesivo, publicación incompleta, órdenes duplicados y permutaciones inválidas, edición publicada y con historial, archivo con intento abierto, copia no autorizada e aislamiento REPEATABLE READ.

## Concurrencia observada

1. Una edición confirmada precede a publicar; la publicación espera y conserva el cambio.
2. Un inicio de intento precede al archivo; después de esperar, archivo rechaza con 55000.
3. Publicar precede a agregar una pregunta; la segunda operación espera y rechaza 55000.
4. Revocar asignación precede a editar; la operación espera y rechaza 42501 sin cambiar el contenido.

El arnés observó pg_blocking_pids antes de confirmar la primera conexión, sin depender de una espera fija. No certifica todas las combinaciones concurrentes posibles ni reemplaza la gestión de reintentos de transacciones en la aplicación.

## Evidencia y límites

Se incluyen logs de la ejecución nativa final y de concurrencia en logs_010/. El arnés SQL aplicó los archivos retirando metacomandos psql y sustituyendo parámetros del seed. No se ejecutó el cliente psql nativo aquí; quedan por comprobar los comandos de instalación en Windows y el entorno local del responsable. No se declara probada la API o interfaz de gestión docente de cuestionarios, que aún no existen en este paquete.

La migración deja intactas las funciones históricas. La regla de edición de configuración publicada sin intentos se aplica en la interfaz 010; scripts administrativos mantienen las capacidades anteriores. Se agregó únicamente la protección de DELETE de actividad como trigger global nuevo.

## Pendiente para cerrar este bloque

- Conservar la salida y versión de las pruebas locales ya confirmadas por Jeison.
- Equipo: revisar doble asignación docente, reglas de estados y firmas.
- Backend/frontend: implementar su integración después de acordar el contrato.
- Bloques siguientes de la v1: administración de asignaciones, usuarios/roles y ciclo académico/intentos según la matriz.


## Validación local confirmada por Jeison

- Instalación y pruebas funcionales de 010: resultado esperado.
- Pruebas concurrentes corregidas de 010 y 011 en Windows: resultado esperado.
- Prueba funcional de 011: resultado esperado, después de comprobar/aplicar la migración en la base correcta.
- Base identificada en la comprobación: proyectofinal_revision010_20261127_201103.

Se registra la confirmación del responsable en este chat; los logs finales de Windows no fueron adjuntados a este paquete. Los logs incluidos de PostgreSQL Linux son la evidencia del asistente y se mantienen identificados por separado.

Los errores anteriores (función/tipo ausente en la conexión elegida, intento de repetir un tipo ya existente y guard de variables) forman parte del diagnóstico resuelto; no se deben ocultar ni contar como fallos finales de las reglas SQL. No repetir migraciones en una base ya validada.
