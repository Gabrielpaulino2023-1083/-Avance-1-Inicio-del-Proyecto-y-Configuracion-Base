# Evidencias del Avance 4

**Fecha:** 15 de noviembre de 2026 · **Entorno:** PostgreSQL local (`proyectofinal_db`), API en `localhost:3000` y frontend en `localhost:5173`.

**Versiones probadas:** backend `16984a5` y frontend `6a02462`. Los IDs corresponden al entorno local y pueden variar al reproducir la prueba.

## Recomendaciones por API

Sesión de estudiante demo (ID local `5`). Se envió una solicitud `POST /api/students/5/recommendation` con el nombre del tema en `topic`, usando los intentos calificados del seed.

### Cómo reproducir la prueba

1. Usar la base local `proyectofinal_db` con las migraciones aplicadas y los datos iniciales de `database/seeds/datos_prueba_integracion_resultados.sql`. Si el seed ya está cargado, no es necesario volver a ejecutarlo. Usar una base de prueba aparte si los resultados iniciales ya cambiaron.
2. Arrancar Express desde `backend`. Si en Windows la recomendación devuelve caracteres como `�`, iniciar el servidor con esta configuración de PowerShell:

   ```powershell
   $env:PYTHONIOENCODING = 'utf-8'
   npm start
   ```

   Si Express ya estaba en ejecución, reiniciarlo desde esa misma terminal. Esta configuración afecta la salida de Python; no requiere modificar PostgreSQL ni el seed.
3. Iniciar sesión como estudiante demo y solicitar una recomendación por cada tema de la tabla con el JSON `{"topic":"SQL JOIN"}`, cambiando el valor de `topic` para los otros dos casos. Usar el ID de la sesión del estudiante; el `5` es el ID local de esta evidencia.
4. Para reproducir la captura, arrancar React con `VITE_USE_MOCK=false` y `VITE_API_URL=http://localhost:3000/api`, abrir el ejercicio de SQL JOIN y solicitar la recomendación. Tomar la captura antes de calificar la evaluación pendiente de SQL JOIN: un intento adicional puede cambiar las cifras del seed.

### Resultados de referencia

| Caso | Tema | Acción esperada y observada | Dificultad | Dominio | Errores | Intentos promedio | Estado |
|---|---|---|---|---:|---:|---:|---|
| A4-REC-01 | SQL JOIN | `reinforce_topic` | `reduced` | 16.7 % | 10 | 2.0 | Aprobado |
| A4-REC-02 | SQL WHERE | `maintain_difficulty` | `current` | 66.7 % | 4 | 2.0 | Aprobado |
| A4-REC-03 | SQL SELECT | `increase_difficulty` | `increased` | 91.7 % | 1 | 2.0 | Aprobado |

`attempts` en la respuesta es el promedio de los números de intento, no el total. Este backend consulta por nombre de tema; la prueba no valida que Express utilice el filtro por inscripción y tema de la migración 008.

<details>
<summary>Respuestas JSON observadas</summary>

```json
[
  {
    "success": true,
    "recommendation": {
      "studentId": 5,
      "tema": "SQL JOIN",
      "accion": "reinforce_topic",
      "dificultad": "reduced",
      "recomendacion": "Se recomienda reforzar el tema SQL JOIN con explicaciones y ejercicios guiados.",
      "mastery": 16.7,
      "errors": 10,
      "attempts": 2
    }
  },
  {
    "success": true,
    "recommendation": {
      "studentId": 5,
      "tema": "SQL WHERE",
      "accion": "maintain_difficulty",
      "dificultad": "current",
      "recomendacion": "Se recomienda mantener el nivel de SQL WHERE y continuar evaluando el progreso.",
      "mastery": 66.7,
      "errors": 4,
      "attempts": 2
    }
  },
  {
    "success": true,
    "recommendation": {
      "studentId": 5,
      "tema": "SQL SELECT",
      "accion": "increase_difficulty",
      "dificultad": "increased",
      "recomendacion": "El estudiante muestra buen desempeño en SQL SELECT. Se recomienda probar ejercicios más difíciles.",
      "mastery": 91.7,
      "errors": 1,
      "attempts": 2
    }
  }
]
```

</details>

### A4-REC-04 — Sin resultados calificados

Con la misma sesión se envió:

```json
{"topic":"QA-AVANCE4-SIN-INTENTOS"}
```

**Resultado esperado y observado: HTTP 404.**

```json
{"success":false,"message":"El estudiante no tiene intentos calificados en ese tema"}
```

El nombre se eligió como un tema inexistente. El endpoint actual no distingue ese caso de un tema existente sin intentos calificados. Se verificó la respuesta de la API, no el manejo del mensaje en React.

## A4-UI-01 — Tarjeta de SQL JOIN en React

**Aprobado.** En `6a02462` la tarjeta mostró **16.7 % de dominio**, **10 errores acumulados** y **2.0 intentos promedio**, coincidiendo con la API. También mostró la recomendación de reforzar el tema y la dificultad reducida.

![Tarjeta SQL JOIN: dominio 16.7 %, 10 errores y 2.0 intentos promedio](./recomendacion_sql_join.png)

Esta captura demuestra la visualización de una recomendación real basada en intentos del seed. No demuestra que una evaluación hecha en React se haya guardado o calificado en PostgreSQL.

## CRUD de cursos por API

Curso de prueba: `QA-A4-20261115-012204` (ID local `14`).

| Caso | Rol | Solicitud | Resultado observado | Estado |
|---|---|---|---|---|
| A4-CUR-01 | Administrador | `POST /api/cursos` | `success: true`; curso creado en borrador | Aprobado |
| A4-CUR-02 | Administrador | `GET /api/cursos/14` | `success: true`; devolvió el curso creado | Aprobado |
| A4-CUR-03 | Administrador | `PUT /api/cursos/14` | `success: true`; nombre cambiado a «Curso temporal QA editado» | Aprobado |
| A4-CUR-04 | Administrador | `PATCH /api/cursos/14/estado` con `{"estado":"ARCHIVADO"}` | `success: true`; estado confirmado en PostgreSQL | Aprobado |
| A4-CUR-05 | Docente | `POST /api/cursos` con un código distinto, terminado en `-DOC` | HTTP 403; no se creó el curso | Aprobado |

Consulta de verificación:

```sql
SELECT id, codigo, nombre, estado
FROM public.cursos
WHERE codigo IN ('QA-A4-20261115-012204', 'QA-A4-20261115-012204-DOC');
```

```text
 id |        codigo         |          nombre           |  estado
----+-----------------------+---------------------------+-----------
 14 | QA-A4-20261115-012204 | Curso temporal QA editado | ARCHIVADO
(1 row)
```

## CRUD de módulos y temas por API — resultado observado

En el backend `16984a5`, con el docente autorizado en `DEMO-006`, se observó que la API permitió crear, consultar, editar, publicar, devolver a borrador y eliminar los módulos y temas temporales. El listado reflejó los cambios de `totalTemas` y conservó el módulo original tras la limpieza.

La API rechazó con HTTP 409 la eliminación de un tema publicado y la de un módulo que todavía tenía temas. También rechazó con HTTP 403 la creación de un módulo por un estudiante y la consulta y creación de módulos por el docente en un curso donde no era editor.

Este apartado resume las salidas compartidas durante la prueba. No se adjuntan capturas ni transcripciones de esas solicitudes, y el CRUD desde React no quedó verificado con esta prueba.

## Pendientes de integración

- Completar y calificar una evaluación desde React, confirmar que el intento nuevo se guardó en PostgreSQL y verificar que influye en la recomendación.
- Verificar por HTTP el selector de cursos del docente cuando Express lo conecte a `listar_cursos_administrables` de 008.
- Confirmar que Express consulta interacciones por inscripción y tema cuando se conecte el contrato de 008.
