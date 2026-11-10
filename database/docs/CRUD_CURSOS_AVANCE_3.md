# Cursos y administrador de pruebas — Avance 3

Fecha: 10 de noviembre de 2026. Alcance: PostgreSQL. No crea endpoints ni pantallas.

## Archivos y ejecución

Copiar los archivos nuevos a sus rutas dentro del repositorio. No reemplazar migraciones anteriores.
En una base con 001–004 y seguridad instaladas, ejecutar desde la raíz del proyecto:

```powershell
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/005_crud_cursos.sql
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_005.sql
```

En una base nueva: 001 → 002 → 003 → security/001_roles_permisos.sql → 004 → 005.
La 005 se aplica una sola vez. Esperado después de instalar: 17 tablas, 1 vista,
17 funciones propias y 9 triggers (sin extensiones). Se agregan cinco funciones
operativas y una auxiliar privada. Las pruebas no dependen de seeds y terminan en ROLLBACK.
Si psql detiene un archivo dentro de una sesión interactiva, ejecutar ROLLBACK antes de continuar.

## Cuenta administradora

Ejecutar primero el seed inicial `database/seeds/datos_prueba.sql` si aún no fue cargado.
No repetirlo en una base donde ya existe. El nuevo seed necesita el catálogo de roles y
un administrador activo inicial; ese administrador inicial puede tener hash ficticio.

Desde `backend`, con las dependencias instaladas:

```powershell
node -e "console.log(require('bcryptjs').hashSync('AdminDemo-2026!', 10))"
```

Desde la raíz del proyecto:

```powershell
chcp 65001
$env:PGCLIENTENCODING = 'UTF8'
psql -X -U postgres -d proyectofinal_db -f database/seeds/datos_prueba_administrador.sql
```

Pegar únicamente el hash solicitado por el script. No confundirlo con la contraseña de postgres.
Cuenta: `administrador.demo@example.com`. Contraseña: `AdminDemo-2026!` únicamente si
se generó el hash con ese texto. Es una credencial pública exclusiva de desarrollo.
El archivo no guarda la contraseña ni el hash y no debe ejecutarse en producción.
No repetir para restablecer contraseña: rechaza cuentas existentes, sin promoverlas ni sobrescribirlas.
No crea cuentas PostgreSQL ni modifica sus contraseñas.

## Contrato SQL

Todas las funciones se ejecutan usando `plataforma_backend` y devuelven filas de `cursos`.
`listar_cursos_admin` devuelve un conjunto; las otras una fila.
Los marcadores `$1` son parámetros de `pg`, no valores para pegar directamente en psql.

| Operación | SQL | Parámetros |
|---|---|---|
| Crear | `SELECT * FROM public.crear_curso_admin($1,$2,$3,$4)` | actor, código, nombre, descripción |
| Listar | `SELECT * FROM public.listar_cursos_admin($1,$2,$3,$4)` | actor, estado o NULL, límite 1–100, desplazamiento ≥0 |
| Consultar uno | `SELECT * FROM public.obtener_curso_admin($1,$2)` | actor, curso |
| Editar | `SELECT * FROM public.actualizar_curso_admin($1,$2,$3,$4,$5)` | actor, curso, código, nombre, descripción |
| Activar | `SELECT * FROM public.cambiar_estado_curso_admin($1,$2,'ACTIVO')` | actor, curso |
| Archivar | `SELECT * FROM public.cambiar_estado_curso_admin($1,$2,'ARCHIVADO')` | actor, curso |

Listado: por ID descendente; estado NULL incluye los tres estados. Valores predeterminados:
50 registros y desplazamiento 0. No devuelve un total paginado.
Edición: reemplaza los tres campos requeridos; no es un PATCH que ignore campos ausentes.
Código: unicidad existente sensible a mayúsculas; no se introduce normalización a mayúsculas.
Las funciones eliminan espacios exteriores de código, nombre y descripción.

## Reglas

- Todas las operaciones exigen cuenta activa y asignación ADMINISTRADOR activa comprobadas en BD.
- El curso nace BORRADOR. La autoría y las fechas se determinan en BD.
- Se editan BORRADOR y ACTIVO. No se editan cursos ARCHIVADO.
- Transiciones: BORRADOR → ACTIVO; BORRADOR/ACTIVO → ARCHIVADO.
- Repetir el estado actual permitido no modifica la fecha. No hay regreso a BORRADOR ni reactivación.
- Archivar exige que no existan ediciones PLANIFICADA, ABIERTA o EN_CURSO.
- Las ediciones FINALIZADA y CANCELADA y los demás registros históricos se conservan.
- Activar el curso no publica sus módulos, temas o actividades.
- No hay DELETE físico: la baja lógica es ARCHIVADO. Debe declararse así en la evaluación del CRUD.
- El administrador de aplicación no puede eludir cupos, editar resultados ni borrar historial.
- Estas funciones no crean una auditoría de quién hizo cada edición: creado_por conserva al autor original.

## Seguridad y concurrencia

Express obtiene `actorId` del token verificado, nunca de `req.body` ni de un rol enviado por el cliente.
Debe comprobar la autorización administrativa antes de llamar y validar tipos, longitudes y campos permitidos.
La cuenta PostgreSQL compartida no verifica JWT: confía en el actor que identifica Express.
Las funciones vuelven a validar cuenta y asignación actuales, incluso si el token tiene un rol antiguo.

Las funciones son SECURITY DEFINER, pertenecen a `plataforma_operaciones`, tienen search_path
fijo y no son ejecutables por PUBLIC. La auxiliar `validar_administrador_cursos` no se concede al backend.
No se otorga membresía en el rol interno. El backend conserva sus lecturas anteriores;
estas funciones no implementan RLS ni sustituyen los filtros de autorización de otras consultas.

Edición y cambio de estado bloquean primero el curso y luego cuenta/asignación; la 004 también
coordina sobre el curso. Cambio de estado exige READ COMMITTED y bloquea ediciones existentes
al archivar. Todas las llamadas deben usar transacciones breves; una transacción explícita usa
un único cliente de `pool.connect()`, con COMMIT/ROLLBACK y liberación en finally.

La protección de archivado corresponde a estas operaciones. No es un trigger universal sobre
ediciones: una sesión administrativa que inserte o reactive ediciones debe bloquear el curso y
comprobar que no está archivado. El futuro CRUD de ediciones deberá seguir ese protocolo.
El backend actual no tiene escritura directa sobre ediciones. No se afirma haber probado
concurrencia entre conexiones con esta entrega.

## Integración con Express

Ejemplo del cuerpo de un servicio, después de autenticar y autorizar:

```javascript
const { rows } = await pool.query(
  'SELECT * FROM public.crear_curso_admin($1,$2,$3,$4)',
  [actorId, codigo, nombre, descripcion]
);
return rows[0];
```

Rutas propuestas para Porfirio, todavía NO implementadas por estos archivos:
POST /api/cursos, GET /api/cursos, GET /api/cursos/:id,
PUT /api/cursos/:id y PATCH /api/cursos/:id/estado. Las rutas aquí descritas son administrativas;
los listados de estudiantes necesitan su propio contrato y filtros.

| SQLSTATE | Tratamiento sugerido |
|---|---|
| 42501 | 403 si el actor no está autorizado; si es un permiso SQL faltante, error interno de configuración |
| 22023 | 400 por campos, estado o paginación inválidos |
| P0002 | 404 curso inexistente |
| 23505 | 409 código duplicado; comprobar la restricción |
| 55000 | 409 transición/edición incompatible con el estado o con ediciones pendientes |
| 25000 | Error interno: transacción con aislamiento no soportado |
| 40P01 / 40001 | Rollback y política acotada de reintento de la transacción completa |

No devolver SQL, trazas ni detalles internos al navegador. No hacer depender toda la API de
comparaciones de mensajes de error. Una conexión directa con permisos incorrectos también
puede producir 42501; debe distinguirse de la autorización del actor.

## Verificación y entrega

`pruebas_migracion_005.sql` verifica permisos, actor estudiante/NULL/inactivo, creación,
duplicados, campos vacíos/NULL, detalle/listado, paginación, edición, activación repetida,
archivado con edición pendiente, conservación de historial y bloqueo después de archivar.
También rechaza una asignación administrativa desactivada. Los fixtures se revierten.

La validación automatizada del paquete utiliza PostgreSQL embebido PGlite; no prueba
autenticación TCP, configuración local de psql, endpoints Express ni interfaz React.
Repetir el archivo en PostgreSQL local, guardar el mensaje final y comprobar por HTTP:
login admin → crear → consultar → editar → activar → archivar → consultar el historial.
Probar también que el estudiante recibe rechazo. No incluir tokens ni hashes en capturas.

Ejecución local de 005 y pruebas: confirmada por el responsable. Seed administrativo y login/me de ambas cuentas: confirmados tras configurar DB_USER=plataforma_backend. Estos son resultados reportados, no una inspección directa de su proceso Express.

Pendiente para el flujo de cursos del Avance 3: endpoints de Porfirio, verificación del usuario efectivo del pool y capturas del recorrido. La entrega semanal también requiere cerrar las métricas/consultas del motor; ese trabajo no forma parte de 005. Quedan fuera de este cambio progreso, métricas del motor,
CRUD de ediciones, reactivación de cursos y eliminación física.

## Instrucciones para agentes

Usar estas firmas y mantener la identidad autenticada. No sustituir funciones por escrituras
directas, otorgar permisos generales, modificar 001–004 ni cambiar el registro público para
crear administradores. No afirmar que el CRUD HTTP existe por contar con esta migración.
Conservar las reglas del contrato principal; esta guía añade el alcance de cursos de 005.


Diccionario y formato de intercambio: [DICCIONARIO_DATOS_BD.md](DICCIONARIO_DATOS_BD.md).
