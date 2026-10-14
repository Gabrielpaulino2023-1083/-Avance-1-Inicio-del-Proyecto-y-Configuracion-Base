# Base de datos — Motor de Aprendizaje Adaptativo

Este directorio contiene la estructura inicial de PostgreSQL del proyecto **Motor de Aprendizaje Adaptativo Basado en Comportamiento del Estudiante**. Su objetivo es permitir que el equipo reproduzca el esquema, consulte las decisiones de diseño y verifique las restricciones implementadas.

**Estado al 13 de octubre de 2026:** esquema académico con once tablas, incluyendo módulos y temas. Se verificaron cinco casos de rechazo del bloque inicial y cuatro del bloque educativo. El backend utiliza las tablas iniciales; la integración de módulos, temas y motor adaptativo sigue pendiente.

## 1. Alcance actual

Esta entrega incluye usuarios, roles, cursos, autorizaciones de edición, ediciones del curso, secciones, asignaciones docentes, inscripciones, módulos y temas.

Todavía no incluye contenidos, evaluaciones, preguntas, respuestas, intentos, eventos de comportamiento ni recomendaciones del motor adaptativo.

## 2. Organización de los archivos

Las rutas siguientes se expresan desde la raíz del repositorio:

| Archivo | Propósito |
|---|---|
| `database/migrations/001_estructura_academica_inicial.sql` | Creación inicial de las nueve tablas y sus restricciones. |
| `database/migrations/002_modulos_temas.sql` | Creación de módulos y temas con relaciones, estados y orden por padre. |
| `database/seeds/datos_pruebas_temas_modulos.sql` | Dos módulos y cuatro temas ficticios en el curso CALC-PRUEBA. |
| `database/test/pruebas_temas_modulos.sql` | Cuatro casos de rechazo sobre posiciones duplicadas o no positivas. |
| `database/seeds/datos_prueba.sql` | Usuarios y datos académicos ficticios para desarrollo. |
| `database/test/pruebas_restricciones.sql` | Cinco casos que deben ser rechazados, cada uno con su transacción y reversión. |
| `database/README.md` | Instrucciones, modelo y estado de la implementación. |

Los archivos SQL deben incorporarse junto con este documento. La carpeta `migrations` contiene cambios de estructura; `seeds`, datos de ejemplo; y `tests`, verificaciones. Los datos ficticios no forman parte de la migración inicial.

## 3. Requisitos

- PostgreSQL instalado y en ejecución.
- Cliente `psql` disponible.
- Una cuenta de PostgreSQL con permisos para crear la base local y sus objetos, o una base vacía proporcionada por el responsable del entorno.
- Una copia local del repositorio.

Registrar la versión utilizada mediante `SELECT version();`. Esta entrega no establece todavía una versión mínima verificada de PostgreSQL.

## 4. Instalación en un entorno nuevo

### 4.1 Crear la base de desarrollo

Desde una terminal, conectarse a una base existente, como `postgres`. Sustituir `TU_USUARIO` por el usuario local de PostgreSQL:

```bash
psql -h localhost -p 5432 -U TU_USUARIO -d postgres
```

La contraseña se introduce cuando el cliente la solicite; no debe escribirse en los archivos del repositorio.

Dentro de `psql`, crear la base fuera de una transacción y conectarse a ella:

```sql
CREATE DATABASE proyectofinal_db;
\connect proyectofinal_db
```

Si ya existe una base con este nombre, no repetir `CREATE DATABASE`. Antes de aplicar la migración, comprobar que no contiene las tablas de esta entrega.

### 4.2 Ejecutar la migración inicial

La migración inicial se ejecuta **una sola vez sobre una base vacía**. Desde `psql`, habilitar la interrupción ante errores y usar una ruta absoluta adaptada a la ubicación del repositorio:

```sql
\set ON_ERROR_STOP on
\i 'C:/ruta/al/proyecto/database/migrations/001_estructura_academica_inicial.sql'
\i 'C:/ruta/al/proyecto/database/migrations/002_modulos_temas.sql'
\dt
```

El script contiene `BEGIN` y `COMMIT`. Si falla dentro de la transacción, ejecutar `ROLLBACK;`, corregir la causa y repetir la migración. No eliminar una base existente para resolver un error sin revisar sus datos.

Si la base ya tiene las nueve tablas iniciales, aplicar únicamente `002_modulos_temas.sql`, siempre que aún no tenga módulos y temas. Si ambas migraciones ya fueron aplicadas, no repetirlas. Los dos scripts incluyen su propia transacción.

### 4.3 Cargar datos ficticios

```sql
\i 'C:/ruta/al/proyecto/database/seeds/datos_prueba.sql'
\i 'C:/ruta/al/proyecto/database/seeds/datos_pruebas_temas_modulos.sql'
```

La carga completa se ejecuta una sola vez. Aunque la inserción de roles admite roles existentes, las demás inserciones no son idempotentes y pueden producir errores al repetirse.

Los usuarios de ejemplo son:

| Correo | Función |
|---|---|
| `admin@example.com` | Administrador inicial. |
| `docente@example.com` | Docente y editor del curso. |
| `estudiante@example.com` | Estudiante. |

Los valores `HASH_FICTICIO_NO_USAR` son marcadores, no hashes de contraseñas válidos. Estas cuentas no deben utilizarse para probar autenticación ni trasladarse a producción.

La carga también crea el curso `CALC-PRUEBA`, las ediciones `ED-PRUEBA-01` y `ED-PRUEBA-02`, dos secciones por edición, las asignaciones docentes y una inscripción autónoma en `SEC 1` de la primera edición. Las fechas y los estados son ejemplos estáticos; no representan una validación automática del calendario.

El segundo seed depende del primero: necesita el curso `CALC-PRUEBA` y `admin@example.com`. Si ya existen los datos iniciales, cargar solo el segundo seed. Si ya se cargaron ambos, no repetirlos.

### 4.4 Consultar la inscripción de ejemplo

```sql
SELECT
    i.id AS inscripcion_id,
    u.nombre,
    u.apellido,
    c.nombre AS curso,
    e.codigo AS edicion,
    s.codigo AS seccion,
    i.estado,
    i.origen
FROM inscripciones i
JOIN usuarios u ON u.id = i.estudiante_id
JOIN ediciones_curso e ON e.id = i.edicion_id
JOIN cursos c ON c.id = e.curso_id
JOIN secciones s ON s.id = i.seccion_id
WHERE u.email = 'estudiante@example.com'
  AND c.codigo = 'CALC-PRUEBA';
```

Se espera una fila correspondiente a Jeison Prueba, Cálculo, `ED-PRUEBA-01`, `SEC 1`, estado `ACTIVA` y origen `AUTONOMA`. El identificador depende de la secuencia local y no debe suponerse igual a 1.

### 4.5 Consultar módulos y temas

```sql
SELECT c.nombre AS curso, m.nombre AS modulo,
       m.orden AS orden_modulo, t.nombre AS tema,
       t.orden AS orden_tema
FROM cursos c
JOIN modulos m ON m.curso_id = c.id
JOIN temas t ON t.modulo_id = m.id
WHERE c.codigo = 'CALC-PRUEBA'
ORDER BY m.orden, t.orden;
```

Se esperan cuatro filas: Concepto de límite y Límites laterales en el módulo Límites (orden 1); Concepto de derivada y Reglas de derivación en Derivadas (orden 2). Cada módulo tiene temas en las posiciones 1 y 2. Todos se cargaron como publicados.

## 5. Tablas y relaciones

| Tabla | Responsabilidad | Relaciones principales |
|---|---|---|
| `usuarios` | Identidad, correo, hash de contraseña y estado de cuenta. | Participa en roles, asignaciones e inscripciones. |
| `roles` | Catálogo de estudiante, docente y administrador. | Referenciado por `usuario_roles`. |
| `usuario_roles` | Asignación y estado de cada rol por usuario. | Usuario, rol y responsable de asignación. |
| `cursos` | Definición compartida de una materia. | Creador, ediciones y editores. |
| `curso_editores` | Autorizaciones para modificar materiales compartidos. | Curso, editor y responsable de asignación. |
| `ediciones_curso` | Oferta de un curso en fechas concretas. | Curso, creador y secciones. |
| `secciones` | Grupo de una edición con capacidad máxima. | Edición, creador, docentes e inscripciones. |
| `seccion_docentes` | Asignación docente a una sección. | Sección, docente y responsable de asignación. |
| `inscripciones` | Participación del estudiante en una edición y sección. | Estudiante, edición, sección y responsable de registro. |

| `modulos` | Organización educativa compartida dentro del curso. | Curso y usuario creador. |
| `temas` | Unidad temática dentro de un módulo. | Módulo y usuario creador. |

La jerarquía es **curso → edición → sección**. Una edición pertenece a un curso y una sección pertenece a una edición. Un usuario puede tener varios roles y un docente puede tener varias asignaciones.

La estructura educativa implementada es **curso → módulos → temas**; los contenidos se incorporarán después. Módulos y temas se comparten entre las secciones y no se duplican por edición.

Una inscripción referencia la combinación `(seccion_id, edicion_id)`, para garantizar que la sección corresponde a la edición indicada.

## 6. Reglas implementadas en el esquema

- Claves primarias enteras generadas mediante identidad.
- Correo único sin distinguir mayúsculas, mediante el índice `uq_usuarios_email` sobre `lower(email)`.
- Textos esenciales obligatorios y no vacíos; el correo no admite espacios al principio o al final.
- Roles limitados a `ESTUDIANTE`, `DOCENTE` y `ADMINISTRADOR`, con código único.
- Una asignación por combinación usuario–rol, curso–editor y sección–docente.
- Código de curso único; descripción sin restricción de unicidad.
- Código de edición único dentro del curso.
- Código de sección único dentro de la edición.
- Cupo máximo entero positivo.
- Fecha de fin de edición igual o posterior al inicio.
- Ventana de inscripción con ambas fechas presentes o ambas ausentes; cuando existe, su cierre no precede a su apertura ni supera el fin académico.
- Ventana obligatoria para ediciones abiertas, en curso o finalizadas.
- Una inscripción por estudiante y edición, incluyendo inscripciones cerradas. Una eventual reactivación utiliza el mismo registro.
- Inscripción activa sin fecha de cierre; inscripción no activa con fecha de cierre igual o posterior a la de inscripción.
- Rol activo sin fecha de desactivación; rol inactivo con fecha de desactivación coherente.
- En una inscripción autónoma, el responsable del registro es el propio estudiante.
- Claves foráneas con `ON DELETE RESTRICT` para impedir borrar registros referenciados.
- Orden de módulo entero positivo y único dentro del curso (`uq_modulos_curso_orden`).
- Orden de tema entero positivo y único dentro del módulo (`uq_temas_modulo_orden`).
- Nombre y descripción obligatorios y no vacíos también en módulos y temas en borrador.
- Módulos y temas inicialmente en `BORRADOR`, con creador y fechas obligatorias.
- Fecha de actualización igual o posterior a la de creación.
- Los registros archivados conservan su posición; archivar no libera el orden.
- Fechas y horas registradas como `TIMESTAMPTZ`.

`ON DELETE RESTRICT` no prohíbe borrar todos los registros: protege los que tienen referencias. La política general de conservación requiere también control de permisos.

## 7. Estados disponibles

| Entidad | Valores permitidos |
|---|---|
| Módulo y tema | `BORRADOR`, `PUBLICADO`, `ARCHIVADO` |
| Curso | `BORRADOR`, `ACTIVO`, `ARCHIVADO` |
| Edición | `PLANIFICADA`, `ABIERTA`, `EN_CURSO`, `FINALIZADA`, `CANCELADA` |
| Sección | `ABIERTA`, `CERRADA`, `CANCELADA` |
| Inscripción | `ACTIVA`, `RETIRADA`, `COMPLETADA`, `CANCELADA` |
| Origen de inscripción | `AUTONOMA`, `ADMINISTRATIVA` |

Una sección cerrada no admite nuevas inscripciones; el estado académico de la oferta corresponde a la edición. Los `CHECK` limitan valores, pero todavía no controlan las transiciones ni sincronizan los estados con las fechas.

## 8. Verificaciones realizadas

Se confirmó la carga válida y se ejecutaron los siguientes casos en el entorno del desarrollador:

| Caso | Resultado observado |
|---|---|
| Insertar `ESTUDIANTE@example.com` existiendo `estudiante@example.com` | Rechazado por `uq_usuarios_email`. |
| Repetir `SEC 1` dentro de la misma edición | Rechazado por unicidad de edición y código. |
| Inscribir al mismo estudiante en otra sección de la misma edición | Rechazado por unicidad de estudiante y edición. |
| Cambiar una inscripción a una sección de otra edición sin cambiar su edición | Rechazado por `fk_inscripciones_seccion_edicion`. |
| Retirar una inscripción dejando `cerrado_en` vacío | Rechazado por `ck_inscripciones_cierre`. |

También se crearon correctamente secciones con el mismo código en ediciones diferentes.

### Verificaciones de módulos y temas

La migración 002 y la carga de dos módulos y cuatro temas finalizaron correctamente. Se consultó la jerarquía ordenada y se verificó que distintos módulos admiten un tema en posición 1.

| Caso | Resultado observado |
|---|---|
| Repetir orden 1 de módulo dentro de CALC-PRUEBA | Rechazado por `uq_modulos_curso_orden`. |
| Repetir orden 1 de tema dentro del módulo Límites | Rechazado por `uq_temas_modulo_orden`. |
| Asignar orden 0 a un módulo | Rechazado por `modulos_orden_check`. |
| Asignar orden -1 a un tema | Rechazado por `temas_orden_check`. |

Los cuatro bloques terminaron con `ROLLBACK`, conservando los datos originales. Estas verificaciones son manuales y no cubren todavía permisos, publicación ni integración del nuevo bloque con el backend.

### Cómo repetir las pruebas

Los bloques de `tests/pruebas_restricciones.sql` y `tests/pruebas_modulos_temas.sql` son pruebas manuales de rechazo, no una suite automatizada. Ejecutar cada bloque por separado en una base de desarrollo con los datos de ejemplo.

Cada bloque debe contener `BEGIN;`, la operación inválida y `ROLLBACK;`. Un error esperado deja la transacción abortada: ejecutar `ROLLBACK;` antes de la siguiente prueba. Si `ON_ERROR_STOP` interrumpe la ejecución antes del cierre del bloque, también ejecutar el rollback manualmente.

Si una operación inválida tiene éxito, revertirla y revisar la restricción. No considerar correcto cualquier error: debe corresponder a la regla indicada en la tabla anterior.

## 9. Reglas pendientes

| Regla | Implementación pendiente |
|---|---|
| Evitar sobrepasar cupos ante inscripciones simultáneas | Transacciones y bloqueo coordinado de la sección. |
| No reducir el cupo por debajo de la ocupación | Validación coordinada con inscripciones activas. |
| No enseñar y estudiar en la misma sección | Comprobación en inscripción, asignación docente, cambio de sección y reactivación. |
| Exigir roles activos y cuenta habilitada | Autorización del backend y protecciones adicionales según el diseño acordado. |
| Limitar creación de cursos y asignación de roles a administradores | Autorización del backend. |
| Limitar edición de materiales a editores autorizados | Autorización del backend. |
| Validar fechas y disponibilidad para inscripción autónoma | Servicio de inscripción. |
| Exigir un docente habilitado antes de iniciar actividades | Validación de inicio. |
| Controlar cambios de estado y cancelaciones con estudiantes | Operaciones de negocio específicas. |
| Conservar cambios de sección | Tabla de historial y operación transaccional. |
| Actualizar `actualizado_en` al modificar una fila | Backend o trigger; el valor predeterminado solo se aplica al insertar. |
| Visibilidad de temas publicados | Comprobar módulo publicado y oferta accesible antes de mostrarlos al estudiante. |
| Reordenar módulos y temas | Operación que respete la unicidad durante los cambios de posición. |
| Calcular progreso por tema | Definir evidencia de finalización; el estado publicado no representa progreso del estudiante. |

Las referencias a `usuarios` comprueban existencia, no que el usuario tenga el rol adecuado. El backend ya accede al esquema inicial con `pg`; la conexión del nuevo bloque y del motor Python debe verificarse conjuntamente.

## 10. Decisiones para los próximos bloques

Estas decisiones están acordadas para orientar el diseño, pero aún no están implementadas:

- Incorporar contenidos a la estructura ya implementada de curso → módulos → temas, manteniendo materiales compartidos entre secciones.
- Evaluaciones pertenecientes a secciones.
- Preguntas de selección única y múltiple.
- Corrección exacta de selección múltiple: todas las correctas y ninguna incorrecta para recibir el puntaje completo.
- Promedio de los intentos entregados y calificados para la nota de una evaluación calificada; intentos no utilizados no cuentan como cero.
- Prácticas con resultados para retroalimentación y análisis, sin aporte a la nota académica.
- Entrega automática al vencer un intento, usando respuestas guardadas y cero para preguntas vacías.
- Conservación de intentos y protección o versionado de evaluaciones utilizadas.

El siguiente bloque será interacciones y recomendaciones. Antes del SQL, revisar `analyzer.py`, `adaptation_rules.py` y el servicio de progreso del backend para acordar el significado, alcance temporal y origen de cada métrica.

## 11. Integración y credenciales

El backend Express utiliza `pg`, `bcryptjs` y JWT, según los archivos revisados. Consulta `usuarios`, `usuario_roles` y `roles`, y registra usuario y rol estudiante en una misma transacción. Las credenciales de PostgreSQL permanecen en el entorno del servidor.

La revisión de código detectó que las consultas seleccionan un único rol mediante `LIMIT 1`, aunque el esquema permite varios. También vinculan la búsqueda del correo a la existencia de un rol activo. Quedan pendientes coordinar múltiples roles, separar la comprobación de existencia del correo y manejar la violación del índice único ante registros simultáneos. No se verificó su corrección posterior.

El registro público genera hashes reales con bcryptjs. Los hashes de los seeds siguen siendo ficticios. No se identificó un ejecutor de migraciones en el package.json revisado; el mecanismo definitivo y el intercambio con Python requieren coordinación.

No subir contraseñas, tokens, archivos `.env` con secretos ni respaldos con datos personales. Un futuro `.env.example` contendrá únicamente nombres de variables y valores ficticios. El `.gitignore` debe conservar los archivos `.sql` del proyecto y excluir los archivos locales sensibles.

Para la primera cuenta administrativa, la inicialización controlada crea el usuario y luego su asignación de rol, pudiendo registrar al mismo usuario como responsable. Esta operación no debe convertirse en una ruta pública de autoasignación de privilegios.

## 12. Gestión de cambios

Esta entrega utiliza scripts SQL manuales; todavía no existe un ejecutor de migraciones ni una tabla que registre cuáles se aplicaron.

Una vez que el equipo adopte la migración inicial, no reescribirla para actualizar bases existentes. Crear archivos nuevos, como `003_interacciones_recomendaciones.sql` (nombre propuesto para el siguiente bloque), con cambios incrementales. Coordinar su orden y registrar qué archivo aplicó cada entorno hasta disponer de una herramienta de migraciones.

Los cambios deben revisarse mediante pull requests y comprobarse en una base de desarrollo. No ejecutar scripts de prueba o modificaciones destructivas sobre datos reales.
