# Contrato SQL — usuarios y roles BD-011-v1

Estado: implementación local y pruebas nativas aprobadas; pendiente de prueba local de Jeison, revisión e integración de backend. No hay cambios publicados en GitHub. Dependencia: 001–010 y seguridad.

## Superficie de operaciones

| Función | Actor / propósito |
|---|---|
| registrar_estudiante(nombre,apellido,email,hash) | Registro público sin actor; fija ESTUDIANTE y no acepta rol del cliente |
| crear_usuario_admin(actor,nombre,apellido,email,hash,rol) | Administrador activo crea un usuario con uno de los tres roles |
| listar_usuarios_admin(actor,activo,rol,busqueda,limite,desplazamiento) | Administrador; filtros opcionales, paginación estable por ID |
| obtener_usuario(actor,usuario) | Administrador consulta cualquiera; usuario activo con algún rol consulta solo su propia ficha |
| actualizar_usuario_admin(actor,usuario,nombre,apellido,email) | Administrador modifica los datos básicos, sin incluir hash, estado o rol en la misma llamada |
| actualizar_mi_perfil(actor,nombre,apellido) | Perfil propio; no cambia correo, estado o roles |
| cambiar_estado_usuario_admin(actor,usuario,activo) | Bloqueo/reactivación lógica; conserva datos académicos |
| asignar_rol_usuario(actor,usuario,rol) | Administrador agrega/reactiva una asignación compatible |
| desactivar_rol_usuario(actor,usuario,rol) | Administrador revoca una asignación sin borrar la fila |
| cambiar_rol_academico(actor,usuario,rol) | Cambio atómico ESTUDIANTE ↔ DOCENTE; conserva ADMINISTRADOR si existe |
| actualizar_hash_usuario(actor,usuario,hash) | Propio o administrador; backend debe autenticar/reautenticar según el caso |

[Firmas exactas y tipos](FIRMAS_USUARIOS_011.md). Nombres SQL, no endpoints HTTP. No se presupone que el frontend o el backend los utilicen todavía.

## Retorno sin credenciales

El tipo compuesto nuevo public.usuario_resumen_011 contiene:

| Campo | Tipo SQL | Observación |
|---|---|---|
| id | INTEGER | Identificador |
| nombre, apellido | VARCHAR(50) | Datos básicos |
| email | TEXT | Correo |
| activo | BOOLEAN | Estado de la cuenta |
| creado_en, actualizado_en | TIMESTAMPTZ | Serializar ISO 8601 con zona |
| roles_activos | TEXT[] | Asignaciones activas, aunque la cuenta esté bloqueada; vacío si no tiene ninguna |
| rol_principal | TEXT nullable | ADMINISTRADOR > DOCENTE > ESTUDIANTE; NULL sin roles activos |

No incluye password_hash. Los hashes tampoco forman parte de las respuestas administrativas, mensajes o logs de API. Cuenta inactiva con roles activos no tiene acceso efectivo.

## Datos y autenticación

Nombre/apellido: TEXT de entrada, recortados, no vacíos y máximo 50 caracteres. Email: normalizado con lower(btrim), máximo 254 y validación básica sin espacios con @ y dominio con punto; unicidad case-insensitive por el índice existente.

El hash se calcula y la contraseña se verifica en backend con bcryptjs, no en PostgreSQL. Las nuevas operaciones exigen estructura bcrypt $2a$/$2b$/$2y$ de 60 caracteres; no demuestran que el hash corresponda a una contraseña concreta. La política de fortaleza, longitud y costo de generación pertenece al backend. El costo actual del proyecto es 10. No aceptar un hash elegido por el cliente público.

No se modifican cuentas, correos, hashes ni notas al instalar. La función registrar_estudiante crea usuario y rol en una llamada atómica, asignado_por = su propio ID. El catálogo ESTUDIANTE debe existir. El usuario inicial administrador se prepara con el procedimiento/seed administrativo, nunca mediante un registro público con rol elegido.

El backend conserva sus consultas actuales para verificar hashes. 011 no implementa recuperación por correo, enlaces de restablecimiento, sesiones ni envío de mensajes. actualizar_hash_usuario requiere en backend la comprobación de contraseña actual para uso propio o el flujo administrativo autorizado. No cambia por sí sola el estado de los JWT emitidos: acordar reautenticación/invalidez de sesiones en la capa de autenticación.

## Roles y transiciones

- Se permiten ADMINISTRADOR+ESTUDIANTE o ADMINISTRADOR+DOCENTE. ESTUDIANTE+DOCENTE activos simultáneamente se rechazan con 55000.
- asignar_rol_usuario no quita el rol contrario silenciosamente. Para pasar entre los dos académicos usar cambiar_rol_academico, que desactiva uno antes de activar el otro en la misma transacción.
- Agregar un rol ya activo es idempotente: no cambia su fecha ni autor. Reactivar uno inactivo conserva el ID de asignación y registra la fecha y actor actuales. No es una bitácora completa de cada período histórico.
- El cambio académico no elimina ADMINISTRADOR. Un DTO HTTP con un solo campo rol no debe interpretarse como reemplazar todas las asignaciones. Backend debe distinguir agregar/revocar un rol y cambiar el rol académico.
- Desactivar ESTUDIANTE se rechaza si hay un intento EN_CURSO, incluso vencido. Entregar/cerrar primero mediante el flujo existente. Las inscripciones y notas se conservan; no se retiran automáticamente ni se liberan sus cupos al cambiar el rol.
- Desactivar DOCENTE mediante la función también desactiva curso_editores y seccion_docentes del usuario. Reactivar el rol no reactiva asignaciones: se requiere nueva asignación autorizada en el bloque académico.
- Se puede dejar una cuenta sin roles activos; no puede acceder a obtener_usuario propio ni autenticarse con las consultas actuales. Un administrador podrá asignarle de nuevo un rol.
- La regla de exclusión académica está protegida por trigger, también para INSERT/UPDATE directos. Si ya hay conflictos al instalar, 011 se revierte y pide revisión; no desactiva roles automáticamente.

## Estado y conservación del historial

cambiar_estado_usuario_admin es baja lógica. No se publica una función de borrado físico de usuarios. Desactivar una cuenta conserva roles, inscripciones, intentos y asignaciones; se trata de una suspensión reversible. Al reactivarla conserva las asignaciones todavía activas. Para revocar permanentemente la docencia utilizar la operación de rol, que sí revoca sus asignaciones.

Es posible bloquear una cuenta con un intento abierto: una necesidad de suspensión no debe depender de que el estudiante termine. Las funciones actuales impiden que una cuenta inactiva siga respondiendo/entregando. Su eventual cierre de servicio forma parte del próximo bloque de intentos; no se inventa una calificación al desactivar la cuenta.

Debe quedar al menos un administrador efectivo: usuario activo con asignación ADMINISTRADOR activa. Triggers protegen la desactivación/borrado del último usuario o de su rol, incluidos UPDATE/DELETE masivos. La instalación vacía no crea administradores; la protección actúa al retirar uno existente. Una cuenta inactiva con rol ADMINISTRADOR no cuenta como reemplazo.

Los administradores pueden modificarse a sí mismos, pero no dejar al sistema sin administrador activo. El mantenimiento directo por superusuario sigue siendo una operación de confianza; no se previene que un superusuario deshabilite triggers o altere el esquema.

## Serialización y compatibilidad

011 agrega 21 funciones (11 públicas, 10 privadas), cuatro triggers y un tipo compuesto; no agrega tablas o columnas ni redefine firmas anteriores. Las operaciones usan SECURITY DEFINER con plataforma_operaciones, search_path fijo y auxiliares sin EXECUTE para backend/PUBLIC.

Las escrituras de usuarios y usuario_roles toman un advisory lock transaccional global (11011,1) desde BEFORE STATEMENT, antes de bloquear filas. Se exige READ COMMITTED. Esto serializa la administración de identidad y permite comprobar correctamente el último administrador y la alternancia bajo concurrencia. No afecta a una lectura ordinaria, pero sí a escrituras de perfiles, registros y mantenimiento de estas tablas.

Mantener transacciones cortas: calcular bcrypt antes de entrar; no llamar a Python, red o interfaz mientras se mantiene el lock. No mezclar SELECT FOR UPDATE previos sobre identidad con escrituras en un orden distinto. Manejar errores transaccionales/deadlocks mediante rollback y reintento completo cuando sea seguro. No se certifica cada combinación posible de todo el sistema; las carreras concretas están en el reporte.

La migración preserva las filas y las definiciones previas, pero **sí añade nuevas restricciones de comportamiento** a sus escrituras. Un script que asignaba simultáneamente ESTUDIANTE y DOCENTE deberá corregirse. No deshabilitar triggers para pasar las pruebas.

## Transición del registro: dos fases

**Fase A, incluida en 011:** agrega registrar_estudiante y las operaciones administrativas; mantiene los INSERT limitados que userModel.create actual usa. El registro existente sigue operativo. Durante esta fase la selección ESTUDIANTE del registro antiguo continúa dependiendo del código del backend; no afirmar que un INSERT SQL arbitrario de ese rol compartido esté limitado a ese código de rol.

**Fase B, posterior a la adaptación de backend:** ejecutar security/002_cerrar_registro_directo.sql. Retira INSERT de usuarios/usuario_roles para backend/PUBLIC y verifica que no queden permisos por columna o heredados. El registro público entonces usa únicamente registrar_estudiante. Esta fase forma parte del cierre de permisos, no del instalador automático.

```powershell
# SOLO despues de adaptar y comprobar el registro desde backend:
psql -X -U postgres -d TU_BASE -v ON_ERROR_STOP=1 -v registro_backend_migrado=true -f database/security/002_cerrar_registro_directo.sql
psql -X -U postgres -d TU_BASE -v ON_ERROR_STOP=1 -f database/test/pruebas_cierre_registro_011.sql
```

La variable es una confirmación operativa; el script no inspecciona el código Node. Si se ejecuta antes del cambio de userModel.create, el registro antiguo deja de funcionar. No volver a aplicar el script antiguo de seguridad después del cierre, pues volvería a conceder esos INSERT.

[Ejemplo de adaptación de create](ejemplos/registro_controlado_011.cjs). No reemplaza todo userModel.js; conservar findByEmail/findById. El objeto de retorno debe mantener rol para el DTO actual a partir de rol_principal. El ejemplo no modifica ni despliega el backend.

## Cambios que Porfirio debe considerar en INC-09

1. Construir rutas administrativas usando estas funciones y actor obtenido del JWT verificado.
2. Mantener separados DTOs de perfil, estado, asignación y cambio académico. No aceptar password_hash, asignado_por o actor del body público.
3. Mapear 22023→400, 42501→403, P0002→404, 23505→409 y 55000→409 según su contrato de errores. 25000 es configuración transaccional del servidor, no un error de formulario.
4. Representar DELETE de usuario como baja lógica mediante cambiar_estado_usuario_admin; no borrar filas para cumplir un nombre de ruta.
5. Adaptar el registro y comprobarlo antes de aplicar la fase B. Las lecturas de autenticación no cambian por 011.
6. **Revalidar cuenta y roles en la autorización de cada petición.** En main a8accad8, verifyToken solo verifica el JWT y requireRole/requirePermission usan req.user.rol del token. Un JWT emitido antes de bloquear o cambiar roles conserva ese claim hasta expirar. Las funciones nuevas consultan permisos actuales, pero eso no vuelve seguros automáticamente todos los endpoints antiguos que solo confían en el claim.
7. Comprobar JWT ya emitido después de bloquear cuenta y después de revocar ADMINISTRADOR; probar también cuenta sin roles. No basta con probar un nuevo login o /me.

## Límites y pruebas

No se implementan endpoints, recuperación por correo, auditoría completa de cambios de identidad ni gestión pública de editores/secciones. El registro sigue usando la cuenta limitada, no postgres. El modelo compartido no incorpora RLS ni validación de JWT en PostgreSQL.

[Validación y evidencias](../test/RESULTADO_VALIDACION_011.md). La ejecución SQL y de concurrencia no certifica todavía la integración HTTP de INC-09 o el cierre de sesiones del backend.
