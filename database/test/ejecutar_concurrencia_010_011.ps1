param(
    [string]$Servidor = 'localhost',
    [int]$Puerto = 5432,
    [string]$Usuario = 'postgres',
    [ValidateSet('010', '011', 'Ambas')][string]$Prueba = 'Ambas'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$raizProyecto = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
foreach ($comando in @('createdb', 'psql', 'node')) {
    if (-not (Get-Command $comando -ErrorAction SilentlyContinue)) {
        throw "No se encontro $comando en PATH."
    }
}
$versiones = if ($Prueba -eq 'Ambas') { @('010', '011') } else { @($Prueba) }
foreach ($version in $versiones) {
    foreach ($archivo in @("instalar_revision_$version.sql", "pruebas_concurrencia_$version.cjs", 'comprobar_entorno_concurrencia.cjs')) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $archivo))) {
            throw "Falta database/test/$archivo. Copiar el parche y conservar los archivos anteriores."
        }
    }
}
$credencialPrueba = Get-Credential -UserName $Usuario -Message 'Cuenta administradora de PostgreSQL para bases NUEVAS de prueba'
if ($null -eq $credencialPrueba) { throw 'No se proporcionaron credenciales.' }
$Usuario = $credencialPrueba.UserName
$variables = @('DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASSWORD','PGPASSWORD','BD010_VALIDACION_AISLADA','BD011_VALIDACION_AISLADA')
$anteriores = @{}
foreach ($nombre in $variables) { $anteriores[$nombre] = [Environment]::GetEnvironmentVariable($nombre, 'Process') }
$marca = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + ([Guid]::NewGuid().ToString('N').Substring(0,6))
$resultados = @()
Push-Location $raizProyecto
try {
    $env:DB_HOST = $Servidor
    $env:DB_PORT = [string]$Puerto
    $env:DB_USER = $Usuario
    $env:DB_PASSWORD = $credencialPrueba.GetNetworkCredential().Password
    $env:PGPASSWORD = $env:DB_PASSWORD
    foreach ($version in $versiones) {
        $baseNuevaPrueba = "proyectofinal_test${version}_$marca"
        $logSalida = Join-Path $PSScriptRoot "concurrencia_${version}_$marca.log"
        $logError = Join-Path $PSScriptRoot "concurrencia_${version}_${marca}_error.log"
        try {
            Write-Host "Prueba $version. Nueva base: $baseNuevaPrueba; servidor: ${Servidor}:$Puerto"
            & createdb -h $Servidor -p $Puerto -U $Usuario $baseNuevaPrueba
            if ($LASTEXITCODE -ne 0) { throw 'Fallo createdb; no se intenta instalar ni probar.' }
            $instalador = Join-Path $PSScriptRoot "instalar_revision_$version.sql"
            & psql -X -h $Servidor -p $Puerto -U $Usuario -d $baseNuevaPrueba -v ON_ERROR_STOP=1 -f $instalador
            if ($LASTEXITCODE -ne 0) { throw 'Fallo la instalacion; no se ejecuta la prueba sobre una base incompleta.' }
            $env:DB_NAME = $baseNuevaPrueba
            [Environment]::SetEnvironmentVariable("BD${version}_VALIDACION_AISLADA", 'SI', 'Process')
            $scriptPrueba = Join-Path $PSScriptRoot "pruebas_concurrencia_$version.cjs"
            $nodeExe = (Get-Command node).Source
            # Las comillas conservan las rutas con espacios en Windows PowerShell 5.1.
            $argumento = '"' + $scriptPrueba + '"'
            $proceso = Start-Process -FilePath $nodeExe -ArgumentList $argumento -NoNewWindow -Wait -PassThru -RedirectStandardOutput $logSalida -RedirectStandardError $logError
            if (Test-Path -LiteralPath $logSalida) { Get-Content -LiteralPath $logSalida | Write-Host }
            if ((Test-Path -LiteralPath $logError) -and ((Get-Item -LiteralPath $logError).Length -gt 0)) { Get-Content -LiteralPath $logError | Write-Host }
            if ($proceso.ExitCode -ne 0) { throw "Prueba rechazada/fallida. Consultar $logSalida y $logError" }
            $resultados += [PSCustomObject]@{ Prueba=$version; Estado='APROBADA'; Base=$baseNuevaPrueba; Log=$logSalida }
        } catch {
            Write-Host "Prueba ${version}: $($_.Exception.Message)" -ForegroundColor Red
            $resultados += [PSCustomObject]@{ Prueba=$version; Estado='REVISAR'; Base=$baseNuevaPrueba; Log=$logError }
        }
    }
} finally {
    foreach ($nombre in $variables) { [Environment]::SetEnvironmentVariable($nombre, $anteriores[$nombre], 'Process') }
    $credencialPrueba = $null
    Pop-Location
}
$resultados | Format-Table -AutoSize
Write-Host 'Las bases de prueba se conservan. No se borraron bases existentes ni se tocaron sus migraciones.'
if (@($resultados | Where-Object { $_.Estado -ne 'APROBADA' }).Count -gt 0) { throw 'Hay pruebas por revisar. Compartir sus logs, sin credenciales.' }
