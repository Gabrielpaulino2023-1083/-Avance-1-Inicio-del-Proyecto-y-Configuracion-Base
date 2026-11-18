// Autenticación, roles y permisos sobre la API real y PostgreSQL.
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import { config, checkDatabase, resetAuthRateLimit } from "../config.mjs";
import { iniciarServidor } from "../helpers/servidor.mjs";

const dbProblem = await checkDatabase();
const BLOCKED = dbProblem ? `BLOQUEADO: ${dbProblem}` : false;
let srv;

before(async () => { if (!BLOCKED) srv = await iniciarServidor(); });
after(async () => { if (!BLOCKED) await srv.cerrar(); });

describe("Autenticación, roles y permisos", { skip: BLOCKED }, () => {
  test("CP-ROL-01 cada cuenta demo inicia sesión con su rol", async () => {
    for (const [rol, email] of [
      ["ESTUDIANTE", config.demoEmail],
      ["ADMINISTRADOR", config.adminDemoEmail],
      ["DOCENTE", config.teacherEmail],
    ]) {
      const s = await srv.sesion(rol);
      assert.equal(s.user.rol, rol);
      assert.equal(s.user.email, email);
      const me = await srv.api("GET", "/api/auth/me", { token: s.token });
      assert.equal(me.data.user.rol, rol);
    }
  });

  test("CP-ROL-02 matriz de permisos por rol en las rutas protegidas", async () => {
    const E = await srv.sesion("ESTUDIANTE");
    const A = await srv.sesion("ADMINISTRADOR");
    const D = await srv.sesion("DOCENTE");
    // [método, ruta, cuerpo, esperado para ESTUDIANTE, DOCENTE, ADMINISTRADOR]
    // Para escrituras se envía un cuerpo inválido: 400 significa "pasó el control de permisos".
    const matriz = [
      ["GET", "/api/cursos", undefined, 403, 403, 200],
      ["POST", "/api/cursos", {}, 403, 403, 400],
      ["GET", "/api/cursos-administrables", undefined, 403, 200, 200],
      ["POST", "/api/modulos", {}, 403, 400, 400],
      ["GET", "/api/mis-cursos", undefined, 200, 403, 403],
    ];
    const errores = [];
    for (const [method, route, body, ...esperado] of matriz) {
      for (const [i, s] of [E, D, A].entries()) {
        const r = await srv.api(method, route, { token: s.token, body });
        if (r.status !== esperado[i]) errores.push(`${s.user.rol} ${method} ${route}: ${r.status} (esperado ${esperado[i]})`);
      }
      const anon = await srv.api(method, route, { body });
      if (anon.status !== 401) errores.push(`sin token ${method} ${route}: ${anon.status} (esperado 401)`);
    }
    assert.deepEqual(errores, []);
  });

  test("CP-ROL-03 acceso a datos de un estudiante según el rol", async () => {
    const E = await srv.sesion("ESTUDIANTE");
    const A = await srv.sesion("ADMINISTRADOR");
    const D = await srv.sesion("DOCENTE");
    const otro = await srv.nuevoEstudiante();
    const ruta = `/api/students/${E.user.id}`;
    assert.equal((await srv.api("GET", ruta, { token: E.token })).status, 200, "el estudiante ve su propio resumen");
    assert.equal((await srv.api("GET", ruta, { token: otro.token })).status, 403, "otro estudiante no puede");
    assert.equal((await srv.api("GET", ruta, { token: D.token })).status, 403, "un docente que no le da clase no puede");
    assert.equal((await srv.api("GET", ruta, { token: A.token })).status, 200, "el administrador puede");
    assert.equal((await srv.api("GET", `/api/students/${A.user.id}`, { token: A.token })).status, 404, "un id que no es estudiante → 404");
  });

  test("CP-ROL-04 el docente solo edita el contenido de sus cursos", async () => {
    const D = await srv.sesion("DOCENTE");
    const propios = await srv.api("GET", "/api/cursos-administrables", { token: D.token });
    assert.deepEqual(propios.data.data.map((c) => c.codigo), ["DEMO-006"]);
    const ajeno = await srv.admin.query("SELECT id FROM cursos WHERE codigo = 'CALC-PRUEBA'");
    const r = await srv.api("POST", "/api/modulos", {
      token: D.token,
      body: { cursoId: ajeno.rows[0].id, nombre: "Intruso", descripcion: "No debería crearse", orden: 900 },
    });
    assert.equal(r.status, 403);
    const { rows } = await srv.admin.query("SELECT COUNT(*)::int n FROM modulos WHERE nombre = 'Intruso'");
    assert.equal(rows[0].n, 0, "no se guardó nada en la base");
  });

  test("CP-ROL-05 usuario con varios roles recibe el de mayor jerarquía", async () => {
    const u = await srv.nuevoEstudiante();
    await srv.admin.query(
      `INSERT INTO usuario_roles (usuario_id, rol_id, asignado_por)
       SELECT $1, id, $1 FROM roles WHERE codigo = 'DOCENTE'`, [u.id]);
    const r = await srv.api("POST", "/api/auth/login", { body: { email: u.email, password: u.password } });
    assert.equal(r.status, 200);
    assert.equal(r.data.user.rol, "DOCENTE");
  });

  test("CP-SEG-01 límite de 10 intentos de login por IP cada 15 minutos", async () => {
    resetAuthRateLimit();
    const codes = [];
    for (let i = 0; i < 11; i++) {
      const r = await fetch(`${srv.baseUrl}/api/auth/login`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "fuerza.bruta@example.com", password: `intento${i}` }),
      });
      codes.push(r.status);
      if (i === 10) {
        const body = await r.json();
        assert.match(body.message, /Demasiados intentos/);
      }
    }
    resetAuthRateLimit();
    assert.deepEqual(codes, [...Array(10).fill(401), 429]);
  });

  test("CP-SEG-02 las respuestas no exponen datos sensibles", async () => {
    const E = await srv.sesion("ESTUDIANTE");
    const resumen = await srv.api("GET", `/api/students/${E.user.id}`, { token: E.token });
    const texto = JSON.stringify(resumen.data);
    assert.ok(!/password|hash/i.test(texto), "sin contraseña ni hash");
    const r = await srv.api("POST", "/api/auth/login", { body: { email: config.demoEmail, password: "malo" } });
    assert.ok(!/SELECT|pg_|stack/i.test(JSON.stringify(r.data)), "los errores no filtran SQL ni trazas");
  });
});
