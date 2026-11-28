# Pruebas (QA)

Matriz de casos de prueba, pruebas automatizadas, evidencias e incidencias de toda la aplicación.

## Resultado actual

| Casos | Aprobados | Fallidos |  Bloqueados |
|---:|---:|---:|---:|
| 147 | 145 | 0 | 2 |

- **Fallido:** se ejecutó y encontró un defecto.
- **Bloqueado:** todavía no se puede probar porque falta una integración (por ejemplo, un endpoint que no existe). No cuenta como fallo.

Cubre autenticación, roles y permisos, CRUD de cursos, módulos y temas contra PostgreSQL, los tres escenarios del motor por la API, un recorrido visual completo, estudiante sin intentos, datos inválidos, errores del motor y desconexión del backend. Incluye las pruebas SQL de `database/test/` (001–009) y las 20 pruebas del motor de `adaptive-engine/tests/`.

## Dónde está cada cosa

| Qué | Archivo |
|---|---|
| Matriz de casos (Excel): ID, requisito, pasos, datos, esperado, real, estado, evidencia | `matriz/matriz_casos_prueba.csv` |
| Matriz de casos (Markdown) | `matriz/MATRIZ_DE_PRUEBAS.md` |
| Reporte de resultados (con trazabilidad por requisito y re-pruebas) | `reportes/REPORTE_DE_PRUEBAS.md` |
| Incidencias | `INCIDENCIAS.md` |
| Capturas y logs | `evidencias/` |
| Pruebas | `unit/`, `integration/`, `functional/` |

## Instalación (una sola vez)

Necesitas Node.js 22 o superior, Python 3, PostgreSQL (con `psql` en el PATH) y Google Chrome.

Desde la raíz del proyecto:

```powershell
cd backend;  npm install; cd ..
cd frontend; npm install; cd ..
cd tests;    npm install; pip install -r requirements.txt
Copy-Item .env.test.example .env.test
```

En `tests/.env.test` pon la contraseña de `postgres` en `PG_ADMIN_PASSWORD`.

## Ejecutar

Desde la carpeta `tests`:

```powershell
npm test
```

Este comando crea la base de datos de pruebas (migraciones 001–009 y todos los seeds), ejecuta todas las pruebas y actualiza la matriz, el reporte y las incidencias. Tarda unos 3 minutos. La base de pruebas (`motor_adaptativo_qa`) es aparte: no toca tu base de desarrollo.

Usa las cuentas demo documentadas en `database/README.md` (estudiante, docente y administrador).

Otras opciones:

| Comando | Para qué |
|---|---|
| `npm test -- --sin-e2e` | Sin navegador (más rápido) |
| `npm run test:unit` | Solo pruebas unitarias |
| `npm run test:integration` | Solo pruebas de integración |
| `npm run test:e2e` | Solo pruebas en el navegador |
| `npm run test:motor-equipo` | Solo las pruebas del motor de Daniel |

## Agregar o actualizar casos

- Los casos están en `matriz/casos.json` y las incidencias en `matriz/incidencias.json`.
- Cada prueba empieza con el ID de su caso (por ejemplo `CP-LOG-01`), así el reporte las relaciona solo.
- Cuando se corrija una incidencia, cambia su `estado` en `incidencias.json` y vuelve a ejecutar `npm test`. El reporte indica si la re-prueba pasó.

## Problemas comunes

| Problema | Solución |
|---|---|
| `psql` no se reconoce | Agrega `C:\Program Files\PostgreSQL\16\bin` al PATH |
| Error de contraseña de `postgres` | Revisa `PG_ADMIN_PASSWORD` en `.env.test` |
| Casi todo sale bloqueado | PostgreSQL está apagado: inícialo en Servicios de Windows |
| `python` no funciona | Pon `PYTHON=py` en `.env.test` |
