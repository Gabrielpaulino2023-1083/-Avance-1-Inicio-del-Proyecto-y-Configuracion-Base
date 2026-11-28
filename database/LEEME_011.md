# Entrega local 011 — usuarios y roles / INC-09

Fecha documental: 27 de noviembre de 2026. Dependencia: paquete 010 instalado y sus archivos presentes en el repositorio local. Base de revisión de GitHub: main a8accad8f494c5050564e9dbd97535479e98d407. No se publica nada en GitHub ni se modifica backend/frontend.

Se confirmaron las pruebas funcionales de 010 y 011 y ambas suites concurrentes. La comprobación de 011 se hizo en proyectofinal_revision010_20261127_201103. No repetir las migraciones en una base ya validada.

## Para una base que todavía tenga solo 010

Copiar los archivos del paquete conservando los anteriores; no reemplazar la carpeta database completa. Los documentos existentes incluidos conservan el contenido de la entrega 010 y agregan un suplemento 011. Revisar el diff si se editaron entretanto.

Desde la raíz del repositorio, en PowerShell:

```powershell
$basePrueba = 'proyectofinal_revision010_20261127_201103'
psql -X -U postgres -d $basePrueba -v ON_ERROR_STOP=1 -c "SELECT current_database(), version(); SELECT to_regprocedure('public.publicar_actividad(integer,integer)') AS dependencia_010, to_regprocedure('public.registrar_estudiante(text,text,text,text)') AS funcion_011;"
# Aplicar solo si 010 existe y 011 NO esta instalada:
psql -X -U postgres -d $basePrueba -v ON_ERROR_STOP=1 -f database/migrations/011_usuarios_roles.sql
if ($LASTEXITCODE -ne 0) { throw 'La migracion 011 fallo. Revisar antes de continuar.' }
psql -X -U postgres -d $basePrueba -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_011.sql
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas 011.' }
```

Esperado: OK 011, PRUEBAS 011 COMPLETADAS, rechazo esperado de REPEATABLE READ y ROLLBACK. Las pruebas no necesitan seeds; crean fixtures, prueban con plataforma_backend y revierten sus filas. Las secuencias pueden avanzar.

011 se instala una sola vez. Si ya está aplicada, ejecutar solo pruebas. Si la prevalidación encuentra ESTUDIANTE y DOCENTE activos para una misma persona, la migración se revierte y no elige qué rol quitar: revisar esos casos antes de repetirla.

Para otra base de revisión, cambiar el nombre. Antes de aplicar a la habitual: generar un respaldo con pg_dump y comprobar que solo falta 011. No ejecutar el instalador de cero en una base existente.

## Instalación nueva opcional

```powershell
$baseNueva = 'proyectofinal_revision011_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
createdb -U postgres $baseNueva
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la base.' }
psql -X -U postgres -d $baseNueva -v ON_ERROR_STOP=1 -f database/test/instalar_revision_011.sql
if ($LASTEXITCODE -ne 0) { throw 'Fallo la instalacion.' }
```

El instalador llama al de 010 y luego aplica 011, sin seeds y sin el cierre opcional de permisos. Requiere los archivos 001–010, seguridad y los instaladores anteriores. Para uso real cargar los seeds oficiales por separado; los fixtures de pruebas no sirven para login.

## Concurrencia con una base nueva sin usuarios

Usar el parche de corrección y el lanzador, que crea una base nueva hasta 011 sin seeds, configura DB_NAME y BD011_VALIDACION_AISLADA y comprueba sus funciones antes de crear fixtures. Ya no depende de $baseNueva del apartado opcional.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\database\test\ejecutar_concurrencia_010_011.ps1 -Prueba 011
```

Requiere los scripts corregidos y su helper juntos en database/test y pg instalado en backend. Se piden credenciales PostgreSQL mediante Get-Credential; por defecto localhost:5432 y postgres, configurables con -Servidor, -Puerto y -Usuario. La política de ejecución se aplica solo al proceso.

Esperado: cinco carreras y cuatro comprobaciones. Los fixtures quedan en esa base aislada: no se desactiva la protección del último administrador para limpiarlos. Cada ejecución crea otra base independiente. No se reinstala sobre desarrollo y las variables de la terminal se restauran al terminar.

## NO ejecutar todavía el cierre del registro directo

security/002_cerrar_registro_directo.sql es una segunda fase separada. Retira los INSERT que userModel.create todavía necesita. Solo se ejecutará después de sustituir ese código por registrar_estudiante y comprobar registro/login en el backend.

El contrato y el ejemplo de adaptación están en docs/USUARIOS_ROLES_011.md y docs/ejemplos/registro_controlado_011.cjs. La confirmación de la variable del script no comprueba por sí sola que la API se haya migrado.

