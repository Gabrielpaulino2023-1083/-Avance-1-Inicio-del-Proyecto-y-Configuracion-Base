# Entrega local 010 — actividades, preguntas y opciones

Este paquete se copia sobre una copia del repositorio que ya contiene 001–009. No sustituye la carpeta database completa. No incluye cambios de backend/frontend ni se ha publicado en GitHub.

Las modificaciones del README, contrato y diccionario conservan el texto del commit base y agregan un suplemento 010. Revisar el diff si esos documentos cambiaron localmente después de ese commit.

## 1. Preparar una base de prueba

Usar una base independiente para la primera instalación y especialmente para concurrencia. Si ya tienes una base de revisión con 009, conserva sus datos y aplica solamente 010. No repetir 001–009 ni ejecutar el instalador de cero en una base existente.

Desde la raíz del repositorio, en PowerShell:

```powershell
# Solo si se necesita otra base NUEVA:
createdb -U postgres proyectofinal_revision_010
psql -X -U postgres -d proyectofinal_revision_010 -v ON_ERROR_STOP=1 -f database/test/instalar_revision_010.sql
```

El instalador reutiliza instalar_revision_009.sql de main y después aplica 010. Rechaza una base que ya tenga tablas públicas.

Para una base EXISTENTE con 009 y sin 010:

```powershell
$respaldo = Join-Path $env:TEMP ('pre010_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.dump')
pg_dump -U postgres -d proyectofinal_db -Fc -f $respaldo
if ($LASTEXITCODE -ne 0) { throw 'El respaldo falló; detenerse.' }
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -c "SELECT current_database(), version(); SELECT to_regprocedure('public.listar_candidatas_actividad(integer,integer,integer,integer)') AS dependencia_009, to_regprocedure('public.publicar_actividad(integer,integer)') AS funcion_010;"
# Continuar solo si 009 existe y 010 no se instaló todavía:
psql -X -U postgres -d proyectofinal_db -v ON_ERROR_STOP=1 -f database/migrations/010_gestion_actividades_cuestionarios.sql
if ($LASTEXITCODE -ne 0) { throw 'La migración falló; revisar antes de continuar.' }
```

Reemplazar el nombre de base si corresponde. 010 se aplica una sola vez. Si ya terminó correctamente, ejecutar solo pruebas. Si hay objetos parciales o de otra versión, revisar el error; no borrar objetos para forzar la instalación.

## 2. Pruebas SQL

No requieren seeds: crean fixtures propios y revierten sus filas; las secuencias pueden avanzar. Usar postgres, no el usuario de la aplicación. La prueba cambia internamente a plataforma_backend.

```powershell
psql -X -U postgres -d proyectofinal_revision_010 -v ON_ERROR_STOP=1 -f database/test/pruebas_migracion_010.sql
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas 010.' }
```

Esperado: mensajes OK 010, PRUEBAS 010 COMPLETADAS, rechazo de REPEATABLE READ y ROLLBACK. Un ERROR inesperado detiene el proceso. No ejecutar dentro de otra transacción abierta.

## 3. Seed opcional para pruebas manuales

Requiere un administrador activo y los usuarios demo docente/estudiante existentes con sus roles activos. En una base nueva, cargar primero los seeds correspondientes de main siguiendo sus instrucciones y prompts bcrypt. El seed 010 no crea cuentas ni modifica hashes.

```powershell
psql -X -U postgres -d proyectofinal_revision_010 -v ON_ERROR_STOP=1 -f database/seeds/datos_prueba_gestion_cuestionarios_010.sql
if ($LASTEXITCODE -ne 0) { throw 'Falló el seed.' }
psql -X -U postgres -d proyectofinal_revision_010 -v ON_ERROR_STOP=1 -f database/test/pruebas_seed_010.sql
```

Crea DEMO-CUESTIONARIOS-010, una sección, la doble asignación del docente, inscripción del estudiante, módulo/tema publicados y dos prácticas BAJA/MEDIA con una pregunta de dos opciones cada una. Sin intentos iniciales. Acepta `-v docente_email=... -v estudiante_email=...` en ambos archivos.

La reejecución conserva la demo existente: no borra contenido ni reinicia intentos. Si cambia su estructura puede rechazar la carga; no es un script de reparación. La prueba del seed describe el escenario inicial; si lo editas, no debes esperar que su validación inicial siga coincidiendo. No usar para datos de producción.

## 4. Concurrencia con bases separadas

Usar el parche de corrección y el lanzador de Windows. Copiar ejecutar_concurrencia_010_011.ps1 y comprobar_entorno_concurrencia.cjs junto a los scripts corregidos en database/test. El lanzador crea bases nuevas, comprueba las instalaciones y configura todas las variables; no depende de un nombre de base escrito en otro apartado.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\database\test\ejecutar_concurrencia_010_011.ps1 -Prueba 010
```

La política se aplica solo a ese proceso. Las credenciales PostgreSQL se piden con Get-Credential. Por defecto localhost:5432 y postgres; admite -Servidor, -Puerto y -Usuario.

La carrera 010 se ejecuta en una base nueva instalada solo hasta 010. No usar una base con 011 porque su protección del último administrador afecta a la limpieza de fixtures de 010. El lanzador conserva las bases existentes y restaura las variables de la terminal. Requiere pg instalado en backend.

Esperado: cuatro carreras y dos comprobaciones, con fixtures eliminados; los logs se guardan en database/test. La consulta pg_blocking_pids comprueba la espera antes de liberar la primera transacción.

## 5. Integración posterior

Leer docs/GESTION_CUESTIONARIOS_010.md y FIRMAS_010.md. Backend puede construir los endpoints después de validar este contrato; no se presupone que existan ahora. La cuenta Express sigue siendo plataforma_backend, nunca postgres. El docente necesita curso_editores y seccion_docentes activos.

Primero confirmar la prueba local y conservar la salida/version. Después preparar el PR para aprobación del equipo. Este paquete no ejecuta Git ni publica mensajes o código.

