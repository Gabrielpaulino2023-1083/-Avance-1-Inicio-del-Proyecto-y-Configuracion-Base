// Motor adaptativo a través de la API: Express → PostgreSQL → Python → Express.
// Usa los datos del seed DEMO-SQL-007 (Jeison): SQL SELECT, SQL WHERE y SQL JOIN
// tienen promedios iniciales 91.67, 66.67 y 16.67 (alto, medio y bajo).
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import { checkDatabase } from "../config.mjs";
import { iniciarServidor, ordenUnico } from "../helpers/servidor.mjs";

const dbProblem = await checkDatabase();
const BLOCKED = dbProblem ? `BLOQUEADO: ${dbProblem}` : false;
let srv;
let E;
let insc; // inscripción del estudiante demo en DEMO-SQL-007
const temas = {}; // nombre → id

before(async () => {
  if (BLOCKED) return;
  srv = await iniciarServidor();
  E = await srv.sesion("ESTUDIANTE");
  const cursos = await srv.api("GET", "/api/mis-cursos", { token: E.token });
  insc = cursos.data.data.find((c) => c.codigo === "DEMO-SQL-007");
  const { rows } = await srv.admin.query(
    `SELECT t.id, t.nombre FROM temas t JOIN modulos m ON m.id = t.modulo_id
     WHERE m.curso_id = $1`, [insc.cursoId]);
  for (const r of rows) temas[r.nombre] = r.id;
});
after(async () => { if (!BLOCKED) await srv.cerrar(); });

const recomendacion = (temaId, token = E.token, inscripcionId = insc.inscripcionId) =>
  srv.api("POST", `/api/mis-inscripciones/${inscripcionId}/temas/${temaId}/recomendacion`, { token });

// Promedio real de los intentos calificados, leído directamente de PostgreSQL.
async function promedioEnBD(temaId) {
  const { rows } = await srv.admin.query(
    `SELECT ROUND(AVG(it.puntaje_obtenido * 100.0 / it.puntaje_maximo), 2)::float AS p
     FROM intentos it JOIN actividades a ON a.id = it.actividad_id
     WHERE it.inscripcion_id = $1 AND a.tema_id = $2 AND it.estado = 'CALIFICADO'`,
    [insc.inscripcionId, temaId]);
  return rows[0].p;
}

describe("Tres escenarios adaptativos por la API", { skip: BLOCKED }, () => {
  for (const [id, tema, accion, dificultad] of [
    ["CP-ADP-01", "SQL JOIN", "reinforce_topic", "reduced"],
    ["CP-ADP-02", "SQL WHERE", "maintain_difficulty", "current"],
    ["CP-ADP-03", "SQL SELECT", "increase_difficulty", "increased"],
  ]) {
    test(`${id} escenario ${tema} → ${accion}`, async () => {
      const r = await recomendacion(temas[tema]);
      assert.equal(r.status, 200, JSON.stringify(r.data));
      assert.equal(r.data.data.accion, accion);
      assert.equal(r.data.data.dificultad, dificultad);
      assert.ok(r.data.data.recomendacion.includes(tema), "el texto menciona el tema");
      // La ruta que usa el frontend (por nombre de tema) debe dar la misma acción.
      const porNombre = await srv.api("POST", `/api/students/${E.user.id}/recommendation`, {
        token: E.token, body: { topic: tema },
      });
      assert.equal(porNombre.status, 200);
      assert.equal(porNombre.data.recommendation.accion, accion);
    });
  }

  test("CP-ADP-04 la evidencia de la recomendación coincide con PostgreSQL", async () => {
    for (const tema of ["SQL JOIN", "SQL WHERE", "SQL SELECT"]) {
      const r = await recomendacion(temas[tema]);
      assert.equal(r.data.data.mastery, await promedioEnBD(temas[tema]), `promedio de ${tema}`);
      assert.ok(Number.isInteger(r.data.data.errors) && r.data.data.errors >= 0);
    }
  });

  test("CP-ADP-05 el Dashboard (progreso) recomienda reforzar el tema más débil", async () => {
    // El tema más débil se calcula en PostgreSQL: menor promedio de intentos calificados.
    const { rows } = await srv.admin.query(
      `SELECT t.nombre, AVG(it.puntaje_obtenido * 100.0 / it.puntaje_maximo) AS p
       FROM intentos it
       JOIN actividades a ON a.id = it.actividad_id
       JOIN temas t ON t.id = a.tema_id
       JOIN inscripciones i ON i.id = it.inscripcion_id
       WHERE i.estudiante_id = $1 AND it.estado = 'CALIFICADO'
       GROUP BY t.nombre ORDER BY p ASC`, [E.user.id]);
    const r = await srv.api("GET", `/api/students/${E.user.id}/progress`, { token: E.token });
    assert.equal(r.status, 200);
    const rec = r.data.progress.recomendacion;
    assert.equal(rec.tema, rows[0].nombre, `el tema con menor promedio es ${rows[0].nombre}`);
    assert.equal(rec.accion, "reinforce_topic");
    assert.equal(rec.prioridad, "alta");
  });

  test("CP-ADP-06 un intento nuevo cambia los datos que analiza el motor", async () => {
    const antes = (await recomendacion(temas["SQL JOIN"])).data.data;
    const acts = await srv.api("GET", `/api/mis-inscripciones/${insc.inscripcionId}/temas/${temas["SQL JOIN"]}/actividades`, { token: E.token });
    const evaluacion = acts.data.data.find((a) => a.finalidad === "EVALUACION");
    const start = await srv.api("POST", `/api/mis-inscripciones/${insc.inscripcionId}/actividades/${evaluacion.id}/intentos`, { token: E.token });
    assert.equal(start.status, 201, JSON.stringify(start.data));
    for (const p of start.data.data.preguntas) {
      const { rows } = await srv.admin.query(
        "SELECT id FROM opciones_respuestas WHERE pregunta_id = $1 AND es_correcta", [p.preguntaId]);
      await srv.api("PUT", `/api/mis-respuestas/${p.respuestaId}/opciones`, { token: E.token, body: { opciones: rows.map((x) => x.id) } });
    }
    const entrega = await srv.api("POST", `/api/mis-intentos/${start.data.data.intentoId}/entrega`, { token: E.token });
    assert.equal(entrega.data.data.porcentaje, 100);
    const despues = (await recomendacion(temas["SQL JOIN"])).data.data;
    assert.ok(despues.mastery > antes.mastery, `promedio ${antes.mastery} → ${despues.mastery}`);
    assert.equal(despues.mastery, await promedioEnBD(temas["SQL JOIN"]));
  });
});

describe("Casos límite del motor por la API", { skip: BLOCKED }, () => {
  test("CP-ADP-07 estudiante sin intentos", async () => {
    const nuevo = await srv.nuevoEstudiante();
    const rec = await srv.api("POST", `/api/students/${nuevo.id}/recommendation`, { token: nuevo.token, body: { topic: "SQL JOIN" } });
    assert.equal(rec.status, 404);
    assert.match(rec.data.message, /no tiene intentos calificados/);
    const resumen = await srv.api("GET", `/api/students/${nuevo.id}`, { token: nuevo.token });
    assert.equal(resumen.status, 200);
    assert.equal(resumen.data.student.cursosActivos, 0);
    const progreso = await srv.api("GET", `/api/students/${nuevo.id}/progress`, { token: nuevo.token });
    assert.equal(progreso.status, 200);
    assert.equal(progreso.data.progress.recomendacion, null);

    // Tema publicado sin intentos dentro de un curso inscrito.
    const A = await srv.sesion("ADMINISTRADOR");
    const moduloId = (await srv.admin.query("SELECT modulo_id FROM temas WHERE id = $1", [temas["SQL JOIN"]])).rows[0].modulo_id;
    const t = await srv.api("POST", `/api/modulos/${moduloId}/temas`, {
      token: A.token, body: { nombre: "Tema QA sin intentos", descripcion: "Sin actividades", orden: ordenUnico(), estado: "PUBLICADO" },
    });
    assert.equal(t.status, 201, JSON.stringify(t.data));
    const sinIntentos = await recomendacion(t.data.data.id);
    assert.equal(sinIntentos.status, 404);
    assert.match(sinIntentos.data.message, /Aún no tienes intentos/);
    await srv.api("PATCH", `/api/temas/${t.data.data.id}/estado`, { token: A.token, body: { estado: "BORRADOR" } });
    await srv.api("DELETE", `/api/temas/${t.data.data.id}`, { token: A.token });
  });

  test("CP-ADP-08 datos inválidos en las rutas del motor", async () => {
    const otro = await srv.nuevoEstudiante();
    const casos = [
      ["POST", `/api/students/${E.user.id}/recommendation`, {}, E.token, 400],
      ["POST", `/api/students/${E.user.id}/recommendation`, { topic: "" }, E.token, 400],
      ["POST", `/api/students/${E.user.id}/recommendation`, { topic: "x".repeat(101) }, E.token, 400],
      ["POST", "/api/students/abc/recommendation", { topic: "SQL JOIN" }, E.token, 400],
      ["POST", "/api/students/0/recommendation", { topic: "SQL JOIN" }, E.token, 400],
      ["POST", `/api/mis-inscripciones/abc/temas/${temas["SQL JOIN"]}/recomendacion`, undefined, E.token, 400],
      ["POST", `/api/mis-inscripciones/${insc.inscripcionId}/temas/-1/recomendacion`, undefined, E.token, 400],
      // La inscripción de otra persona no se puede usar.
      ["POST", `/api/mis-inscripciones/${insc.inscripcionId}/temas/${temas["SQL JOIN"]}/recomendacion`, undefined, otro.token, 403],
      ["POST", `/api/students/${E.user.id}/recommendation`, { topic: "SQL JOIN" }, otro.token, 403],
      ["POST", `/api/students/${E.user.id}/recommendation`, { topic: "SQL JOIN" }, undefined, 401],
    ];
    const errores = [];
    for (const [m, ruta, body, token, esperado] of casos) {
      const r = await srv.api(m, ruta, { body, token });
      if (r.status !== esperado) errores.push(`${ruta} ${JSON.stringify(body)} → ${r.status} (esperado ${esperado})`);
    }
    assert.deepEqual(errores, []);
  });

  test("CP-ADP-09 errores del motor: Python ausente o motor que falla → 502", async () => {
    const original = process.env.PYTHON_EXECUTABLE;
    const consola = console.error;
    console.error = () => {}; // el backend registra el fallo; se silencia en la prueba
    try {
      // Python no instalado / ruta mal configurada, y un ejecutable que no es Python (el motor falla).
      for (const ejecutable of ["/ruta/que/no/existe/python", process.execPath]) {
        process.env.PYTHON_EXECUTABLE = ejecutable;
        const r = await recomendacion(temas["SQL JOIN"]);
        assert.equal(r.status, 502, `${ejecutable}: ${r.status}`);
        assert.equal(r.data.message, "El motor de recomendación no está disponible");
        assert.ok(!/Traceback|python|stack/i.test(JSON.stringify(r.data)), "no filtra detalles internos");
        // El resto del Dashboard sigue funcionando sin recomendación.
        const prog = await srv.api("GET", `/api/students/${E.user.id}/progress`, { token: E.token });
        assert.equal(prog.status, 200);
        assert.equal(prog.data.progress.recomendacion, null);
      }
    } finally {
      process.env.PYTHON_EXECUTABLE = original;
      console.error = consola;
    }
    assert.equal((await recomendacion(temas["SQL JOIN"])).status, 200, "se recupera al volver Python");
  });
});
