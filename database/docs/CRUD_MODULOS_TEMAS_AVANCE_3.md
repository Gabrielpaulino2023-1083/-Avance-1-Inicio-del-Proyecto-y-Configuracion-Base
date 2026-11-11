# Módulos, temas y docente de pruebas — BD-006-v1

Fecha: 11 de noviembre de 2026. Alcance: PostgreSQL para Avance 3.
No implementa endpoints, pantallas, progreso ni métricas del motor.

## Instalación

Requiere 001 → 002 → 003 → seguridad → 004 → 005, aplicadas en ese orden.
En una base que ya tiene 005, ejecutar SOLO 006 desde la raíz del repositorio:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/006_crud_modulos_temas.sql
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_006.sql
```

No repetir la migración después de COMMIT. Las pruebas no dependen de seeds, crean fixtures
propios y terminan en ROLLBACK. Si psql se detiene en una sesión interactiva, ejecutar ROLLBACK.
Una prueba fallida no justifica deshabilitar triggers ni otorgar permisos generales.

006 no crea ni altera tablas, vistas o triggers. Agrega 12 funciones operativas y dos auxiliares
privadas: total acumulado 17 tablas, 1 vista, 31 funciones propias y 9 triggers. De las funciones,
22 son operativas, seis de trigger y tres auxiliares privadas. Los índices/constraints de 002
siguen protegiendo el orden y las relaciones. No hay cambios al diccionario de columnas existente.

## Autorización y reglas

Todas las operaciones, incluidas las lecturas administrativas, comprueban:

- Cuenta activa y rol ADMINISTRADOR activo; o
- Cuenta activa, rol DOCENTE activo y asignación activa en curso_editores para el curso.

Ser docente de una sección no equivale a ser editor del material compartido. Un docente sin
asignación no puede administrar el curso. Un estudiante no puede hacerlo, aunque exista una
fila accidental de editor. El administrador no necesita una asignación de editor.

El actor se obtiene del JWT verificado por Express, nunca del body. Las funciones no validan
JWT ni distinguen usuarios finales por la conexión SQL compartida. No se agrega RLS.
El rol de conexión sigue siendo plataforma_backend; las funciones ejecutan con el rol interno
plataforma_operaciones, propietario limitado. No se otorga INSERT/UPDATE/DELETE directo al backend.

- Nombre y descripción obligatorios, recortados en extremos; orden entero mayor que cero.
- Orden único por curso en módulos y por módulo en temas. Código 23505 en duplicados.
- Crear admite BORRADOR (default), PUBLICADO o ARCHIVADO, compatible con el formulario actual.
- Actualizar reemplaza nombre, descripción, orden y estado completos. Conserva creado_por/creado_en.
- Estado admite BORRADOR, PUBLICADO, ARCHIVADO; no se agrega una matriz de transición restrictiva.
- Cambiar estado está disponible por separado. Repetir el mismo estado conserva actualizado_en.
- Publicar/archivar no modifica hijos en cascada. Los listados administrativos incluyen todos los estados.
- Se puede editar un módulo/tema archivado o cambiarlo a otro estado si el curso admite escritura;
  no confundirlo con la política de cursos de 005, que no permite reactivación.
- Eliminar físicamente SOLO en BORRADOR y sin dependencias. Otros estados: 55000, usar archivado.
- Módulo con cualquier tema: 55000. Tema con cualquier actividad: 55000, incluso si está archivada.
- No se trasladan módulos de curso ni temas de módulo; los triggers existentes permanecen activos.
- Cursos ARCHIVADO: consultas autorizadas permitidas; escrituras rechazadas con 55000.
- No hay reordenamiento masivo: cambiar a un orden ocupado produce 23505.

La gestión de metadatos no modifica preguntas, intentos o calificaciones. Las reglas existentes
sobre edición de actividades usadas siguen vigentes. La visibilidad de contenido para estudiantes
requiere filtros de backend por inscripción/publicación; este CRUD administrativo no los implementa.

## Funciones y parámetros

Todas usan schema public y actor como primer parámetro. INTEGER para identificadores/orden;
TEXT para nombre, descripción y estado. El actor no es un parámetro editable del formulario.

| Función | Parámetros en orden | Resultado |
|---|---|---|
| crear_modulo | actor, curso, nombre, descripción, orden, estado= BORRADOR | Una fila de módulo con total_temas |
| listar_modulos_por_curso | actor, curso | Filas de módulo con total_temas, ordenadas por orden/id |
| obtener_modulo | actor, módulo | Una fila de módulo con total_temas |
| actualizar_modulo | actor, módulo, nombre, descripción, orden, estado | Una fila de módulo con total_temas |
| cambiar_estado_modulo | actor, módulo, estado | Una fila de módulo con total_temas |
| eliminar_modulo | actor, módulo | ID eliminado |
| crear_tema | actor, módulo, nombre, descripción, orden, estado= BORRADOR | Fila temas |
| listar_temas_por_modulo | actor, módulo | Filas temas ordenadas por orden/id |
| obtener_tema | actor, tema | Fila temas |
| actualizar_tema | actor, tema, nombre, descripción, orden, estado | Fila temas |
| cambiar_estado_tema | actor, tema, estado | Fila temas |
| eliminar_tema | actor, tema | ID eliminado |

Las auxiliares validar_editor_contenido(INTEGER,INTEGER,BOOLEAN) y
validar_datos_contenido(TEXT,TEXT,INTEGER,TEXT) no se conceden al backend.

Los módulos devuelven: id, curso_id, nombre, descripcion, orden, estado, creado_por,
creado_en, actualizado_en, total_temas. total_temas es BIGINT, incluye todos los estados y se
calcula en la consulta; no se almacena una columna nueva. Las listas no tienen paginación en esta versión.
Un padre existente sin hijos produce lista vacía; un padre inexistente produce P0002.

Ejemplos con pg (no pegar $1 literalmente en psql):

```javascript
const { rows } = await pool.query(
  'SELECT * FROM public.crear_modulo($1,$2,$3,$4,$5,$6)',
  [actorId, cursoId, nombre, descripcion, orden, estado]
);
const modulo = rows[0];
const totalTemas = Number(modulo.total_temas);
if (!Number.isSafeInteger(totalTemas) || totalTemas < 0) {
  throw new Error('Conteo fuera del rango admitido por el DTO');
}
// Construir DTO con campos explícitos, no enviar automáticamente todas las columnas.
```

```sql
SELECT * FROM public.listar_modulos_por_curso($1,$2);
SELECT * FROM public.listar_temas_por_modulo($1,$2);
SELECT * FROM public.actualizar_tema($1,$2,$3,$4,$5,$6);
SELECT * FROM public.cambiar_estado_tema($1,$2,$3);
SELECT public.eliminar_tema($1,$2) AS eliminado_id;
```

## Backend y frontend

Mapear curso_id → cursoId, modulo_id → moduloId, actualizado_en → actualizadoEn (ISO 8601),
total_temas → totalTemas (number seguro). Los demás campos de ContenidoInput mantienen sus nombres:
nombre, descripcion, orden y estado. El frontend propone respuestas `{ success, data }`.
Los listados administrativos y de estudiantes son contratos distintos.

Antes de integrar:

1. El frontend debe seleccionar/enviar un curso real para listar/crear módulos; no fijar curso 1.
2. Backend acuerda rutas como GET/POST /api/cursos/:cursoId/modulos con frontend. Son propuestas,
   no endpoints creados por esta migración. Las actuales /modulos son provisionales sin contexto de curso.
3. Para temas, conservar el contexto de módulo en listado/creación; las mutaciones resuelven su curso en BD.
4. Puede usar actualizar_* con estado incluido en PUT, como el formulario actual, o acordar una ruta
   específica de estado. El helper HTTP actual del frontend no admite PATCH sin modificación.
5. Ajustar la UI de eliminar: solo borrador sin dependencias; mostrar conflicto 55000.
6. Validar tipos de entrada antes de SQL; no usar coerciones que acepten IDs fraccionarios.
7. Probar con docente asignado, docente no asignado, administrador y estudiante.

Para ofrecer cursos editables al selector, el backend puede usar esta consulta parametrizada
con los SELECT ya concedidos. El actor procede de la sesión; las funciones vuelven a verificar
permisos al operar, por lo que el listado no sustituye la autorización:

```sql
SELECT c.id, c.codigo, c.nombre, c.estado
FROM public.cursos c
WHERE EXISTS (
  SELECT 1 FROM public.usuarios u WHERE u.id=$1 AND u.activo
) AND (
  EXISTS (
    SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id
    WHERE ur.usuario_id=$1 AND ur.activo AND r.codigo='ADMINISTRADOR'
  ) OR (
    EXISTS (
      SELECT 1 FROM public.usuario_roles ur JOIN public.roles r ON r.id=ur.rol_id
      WHERE ur.usuario_id=$1 AND ur.activo AND r.codigo='DOCENTE'
    ) AND EXISTS (
      SELECT 1 FROM public.curso_editores ce
      WHERE ce.curso_id=c.id AND ce.usuario_id=$1 AND ce.activo
    )
  )
)
ORDER BY c.nombre, c.id;
```

Incluye archivados para consulta; la interfaz debe deshabilitar escrituras en ellos.
No usar listar_cursos_admin para el selector de un docente: esa función exige administrador.

## Errores y transacciones

| SQLSTATE | Interpretación |
|---|---|
| 42501 | Actor sin autorización, cuenta/rol/editor inactivos; también puede indicar un GRANT faltante |
| P0002 | Curso/módulo/tema inexistente |
| 22023 | Parámetros obligatorios, orden, texto o estado inválidos |
| 23505 | Orden duplicado por padre; comprobar nombre de restricción |
| 55000 | Borrado con dependencias, no borrador o escritura en curso archivado |
| 25000 | Aislamiento distinto de READ COMMITTED |
| 40P01 / 40001 | Rollback y reintento acotado de la transacción completa si corresponde |

El backend diferencia autorización del actor de errores internos de permisos; no expone trazas.
Las FK siguen activas. Si una dependencia llega durante el borrado, el rechazo de FK se convierte
al conflicto 55000; no se hace cascada ni se eliminan hijos automáticamente.

Todas las operaciones exigen READ COMMITTED. Las mutaciones serializan por curso: curso → usuario
→ asignaciones de rol → editor → registro. Las consultas toman bloqueos compartidos. Se mantiene
la autorización mientras dura la transacción. Mantener llamadas breves; usar el mismo cliente
para BEGIN/COMMIT/ROLLBACK y no esperar interacción humana o llamadas a Python dentro de bloqueos.
Las sesiones administrativas que escriben directamente pueden saltarse reglas funcionales;
las FK protegen integridad, pero no sustituyen el uso de las funciones. No se afirma haber
probado concurrencia entre conexiones; será una validación posterior.

## Docente de demostración

Seed separado: seeds/datos_prueba_docente.sql. Requiere catálogo de roles y un administrador
activo (seed inicial), además de 006. Rechaza cuenta/curso existentes sin sobrescribirlos.

Desde backend, con dependencias instaladas:

```powershell
node -e "console.log(require('bcryptjs').hashSync('DocenteDemo-2026!', 10))"
```

Desde la raíz del repositorio:

```powershell
chcp 65001
$env:PGCLIENTENCODING = 'UTF8'
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_docente.sql
```

Pegar solo el hash cuando lo solicite. Cuenta docente.demo@example.com, contraseña
DocenteDemo-2026! si se generó con ese texto. Credencial pública exclusiva de desarrollo.
El seed crea DEMO-006 ACTIVO, asignación de editor, un módulo y un tema en borrador. El docente
no es administrador ni estudiante. No cambia DEMO-003 ni otras cuentas. No crea sección ni
seccion_docentes: son innecesarias para este CRUD de material compartido. Los IDs se consultan.
El rol de conexión de Express sigue siendo plataforma_backend, no el correo del docente.

## Verificación

Ver test/RESULTADO_VALIDACION_006.md para evidencia y límites. Repetir las pruebas SQL en
PostgreSQL local, después verificar login/me del docente. El flujo HTTP de módulos/temas
requiere endpoints de Porfirio y ajustes de contexto de curso en frontend. No presentar las
operaciones de localStorage como persistencia en BD ni borrar los errores para que la demo pase.

Agentes: usar funciones; no duplicar tablas, modificar 001–005, conceder permisos amplios,
usar postgres en Express ni confundir seccion_docentes con curso_editores. Los metadatos
SQL siguen el diccionario existente; los DTOs y rutas deben acordarse con el backend.
