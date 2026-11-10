// Pruebas de integración: API Express real + PostgreSQL real (base de QA).
// Cubre login válido/inválido, CRUD disponible y persistencia.
//
// Requisito: npm run preparar-bd (crea la base de QA y la cuenta demo).
// Si la base no está disponible, los casos se marcan BLOQUEADO (skip), no fallidos.
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { spawn } from "node:child_process";
import {
  BACKEND_DIR, config, requireFromBackend, configureBackendEnv, checkDatabase,
} from "../config.mjs";

configureBackendEnv();
const jwt = requireFromBackend("jsonwebtoken");
const { Pool } = requireFromBackend("pg");

const dbProblem = await checkDatabase();
const BLOCKED = dbProblem ? `BLOQUEADO: ${dbProblem}` : false;

let server;
let baseUrl;
let admin; // conexión administrativa para verificar y preparar datos
const unique = () => `qa.${Date.now()}.${Math.random().toString(36).slice(2, 7)}@example.com`;

async function api(method, route, { body, token, raw } = {}) {
  const res = await fetch(`${baseUrl}${route}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: raw ?? (body === undefined ? undefined : JSON.stringify(body)),
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, data };
}

const login = (email, password) => api("POST", "/api/auth/login", { body: { email, password } });

async function registerUser(overrides = {}) {
  const user = { nombre: "QA", apellido: "Automatizado", email: unique(), password: "ClaveSegura-1", ...overrides };
  const res = await api("POST", "/api/auth/register", { body: user });
  return { user, res };
}

// Marca como BLOQUEADO un caso cuyo endpoint todavía no existe (404 "Ruta no encontrada").
function blockIfMissing(t, res, what) {
  if (res.status === 404 && res.data?.message === "Ruta no encontrada") {
    t.skip(`BLOQUEADO: ${what} no está implementado en el backend (404).`);
    return true;
  }
  return false;
}

before(async () => {
  if (BLOCKED) return;
  const app = requireFromBackend(path.join(BACKEND_DIR, "src/app.js"));
  await new Promise((resolve) => { server = app.listen(0, resolve); });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
  admin = new Pool({
    host: config.pgHost, port: config.pgPort, database: config.dbName,
    user: config.adminUser, password: config.adminPassword,
  });
});

after(async () => {
  if (BLOCKED) return;
  await new Promise((resolve) => server.close(resolve));
  await requireFromBackend(path.join(BACKEND_DIR, "src/config/db.js")).end();
  await admin.end();
});

describe("Login", { skip: BLOCKED }, () => {
  test("CP-LOG-01 login con credenciales válidas", async () => {
    const { status, data } = await login(config.demoEmail, config.demoPassword);
    assert.equal(status, 200);
    assert.equal(data.success, true);
    assert.equal(data.user.email, config.demoEmail);
    assert.equal(data.user.rol, "ESTUDIANTE");
    assert.equal(data.user.passwordHash, undefined);
    const payload = jwt.verify(data.token, config.jwtSecret);
    assert.equal(payload.id, data.user.id);
    assert.equal(payload.rol, "ESTUDIANTE");
    assert.ok(payload.exp - payload.iat === 2 * 60 * 60, "el token dura 2 horas");
  });

  test("CP-LOG-02 login sin distinguir mayúsculas y con espacios", async () => {
    const { status } = await login(`  ${config.demoEmail.toUpperCase()}  `, config.demoPassword);
    assert.equal(status, 200);
  });

  test("CP-LOG-03 login con contraseña incorrecta", async () => {
    const { status, data } = await login(config.demoEmail, "ClaveIncorrecta1");
    assert.equal(status, 401);
    assert.equal(data.message, "Credenciales inválidas");
    assert.equal(data.token, undefined);
  });

  test("CP-LOG-04 login con correo no registrado (mismo mensaje)", async () => {
    const { status, data } = await login("no.existe@example.com", "Cualquiera123");
    assert.equal(status, 401);
    assert.equal(data.message, "Credenciales inválidas");
  });

  test("CP-LOG-05 login con campos vacíos o ausentes", async () => {
    for (const body of [{ email: "", password: "" }, {}]) {
      const { status, data } = await api("POST", "/api/auth/login", { body });
      assert.equal(status, 400);
      assert.equal(data.message, "Datos inválidos");
      const campos = data.details.map((d) => d.campo).sort();
      assert.deepEqual(campos, ["email", "password"]);
    }
  });

  test("CP-LOG-06 login con JSON mal formado", async () => {
    const { status, data } = await api("POST", "/api/auth/login", { raw: '{"email": ' });
    assert.equal(status, 400);
    assert.equal(data.message, "JSON inválido");
  });

  test("CP-LOG-07 login con tipos de datos incorrectos", async () => {
    for (const body of [
      { email: config.demoEmail, password: 12345678 },
      { email: {}, password: "x" },
      [],
    ]) {
      const { status } = await api("POST", "/api/auth/login", { body });
      assert.equal(status, 400, `cuerpo ${JSON.stringify(body)}`);
    }
  });

  test("CP-LOG-08 usuario con hash ficticio del seed → 401 controlado", async () => {
    const { status } = await login("estudiante@example.com", "estudiante123");
    assert.equal(status, 401);
  });

  test("CP-LOG-09 cuenta desactivada no puede entrar ni usar su token", async () => {
    const { user, res } = await registerUser();
    assert.equal(res.status, 201);
    const { data } = await login(user.email, user.password);
    const oldToken = data.token;
    await admin.query("UPDATE usuarios SET activo = FALSE WHERE id = $1", [res.data.user.id]);

    assert.equal((await login(user.email, user.password)).status, 401);
    assert.equal((await api("GET", "/api/auth/me", { token: oldToken })).status, 401);
  });

  test("CP-LOG-10 /api/auth/me con token válido", async () => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const me = await api("GET", "/api/auth/me", { token: data.token });
    assert.equal(me.status, 200);
    assert.deepEqual(me.data.user, data.user);
    assert.equal(me.data.user.passwordHash, undefined);
  });

  test("CP-LOG-11 /me sin token, alterado, con otro secreto o vencido", async () => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const [h, p, s] = data.token.split(".");
    const tampered = `${h}.${Buffer.from(JSON.stringify({ id: 1, rol: "ADMINISTRADOR" })).toString("base64url")}.${s}`;
    const otherSecret = jwt.sign({ id: data.user.id, rol: "ADMINISTRADOR" }, "otro-secreto");
    const expired = jwt.sign({ id: data.user.id, rol: "ESTUDIANTE" }, config.jwtSecret, { expiresIn: -60 });
    void p;

    const headers = [undefined, `Basic ${data.token}`, `Bearer ${tampered}`, `Bearer ${otherSecret}`, `Bearer ${expired}`];
    for (const authorization of headers) {
      const res = await fetch(`${baseUrl}/api/auth/me`, { headers: authorization ? { authorization } : {} });
      assert.equal(res.status, 401, `cabecera: ${authorization?.slice(0, 20)}`);
    }
  });

  test("CP-LOG-12 intento de inyección SQL en el login", async () => {
    for (const [email, password] of [
      ["' OR '1'='1' --", "x"],
      ["admin@example.com'--", "x"],
      [config.demoEmail, "' OR '1'='1"],
      ["x'; DROP TABLE usuarios; --", "x"],
    ]) {
      const { status } = await login(email, password);
      assert.equal(status, 401, `email=${email}`);
    }
    const { rows } = await admin.query("SELECT COUNT(*)::int AS n FROM usuarios");
    assert.ok(rows[0].n > 0, "la tabla usuarios sigue existiendo");
  });
});

describe("CRUD de usuarios", { skip: BLOCKED }, () => {
  test("CP-CRUD-01 crear (registro) con datos válidos", async () => {
    const { user, res } = await registerUser({ nombre: "José", apellido: "Núñez" });
    assert.equal(res.status, 201);
    assert.equal(res.data.success, true);
    assert.equal(res.data.user.email, user.email);
    assert.equal(res.data.user.nombre, "José");
    assert.equal(res.data.user.rol, "ESTUDIANTE");
    assert.ok(Number.isInteger(res.data.user.id));
    assert.equal(res.data.user.passwordHash, undefined);
  });

  test("CP-CRUD-02 crear con correo duplicado (otra capitalización)", async () => {
    const { user } = await registerUser();
    const again = await api("POST", "/api/auth/register", {
      body: { ...user, email: user.email.toUpperCase() },
    });
    assert.equal(again.status, 409);
    assert.equal(again.data.message, "Ya existe un usuario con ese email");
  });

  test("CP-CRUD-03 crear con datos inválidos", async () => {
    const cases = [
      [{ email: "correo-sin-arroba" }, "email"],
      [{ password: "1234567" }, "password"],
      [{ password: "a".repeat(73) }, "password"],
      [{ nombre: "" }, "nombre"],
      [{ apellido: "x".repeat(51) }, "apellido"],
    ];
    for (const [override, campo] of cases) {
      const { res } = await registerUser(override);
      assert.equal(res.status, 400, JSON.stringify(override));
      assert.ok(res.data.details.some((d) => d.campo === campo), `debe señalar ${campo}`);
    }
  });

  test("CP-CRUD-04 el registro ignora un rol enviado por el cliente", async () => {
    const { user, res } = await registerUser({ rol: "ADMINISTRADOR" });
    assert.equal(res.status, 201);
    assert.equal(res.data.user.rol, "ESTUDIANTE");
    const { data } = await login(user.email, user.password);
    assert.equal(data.user.rol, "ESTUDIANTE");
  });

  test("CP-CRUD-05 leer el usuario recién creado", async () => {
    const { user } = await registerUser({ nombre: "Lectura", apellido: "Prueba" });
    const { data } = await login(user.email, user.password);
    const me = await api("GET", "/api/auth/me", { token: data.token });
    assert.equal(me.status, 200);
    assert.equal(me.data.user.nombre, "Lectura");
    assert.equal(me.data.user.apellido, "Prueba");
    assert.equal(me.data.user.email, user.email);
  });

  test("CP-CRUD-06 actualizar usuario / cambiar rol", async (t) => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const res = await api("PATCH", `/api/users/${data.user.id}/role`, { token: data.token, body: { rol: "DOCENTE" } });
    if (blockIfMissing(t, res, "PATCH /api/users/:id/role")) return;
    assert.equal(res.status, 403, "un estudiante no debe poder cambiar roles");
  });

  test("CP-CRUD-07 eliminar / desactivar usuario", async (t) => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const res = await api("DELETE", `/api/users/${data.user.id}`, { token: data.token });
    if (blockIfMissing(t, res, "DELETE /api/users/:id")) return;
    assert.equal(res.status, 403);
  });

  test("CP-CRUD-08 listar y consultar estudiantes", async (t) => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const list = await api("GET", "/api/students", { token: data.token });
    const one = await api("GET", `/api/students/${data.user.id}`, { token: data.token });
    if (blockIfMissing(t, one, "GET /api/students/:id") || blockIfMissing(t, list, "GET /api/students")) return;
    assert.equal(list.status, 403, "un estudiante no tiene students:list");
    assert.equal(one.status, 200);
  });

  test("CP-CRUD-09 operaciones académicas por HTTP", async (t) => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const candidates = [
      ["POST", "/api/enrollments"],
      ["POST", "/api/attempts"],
      ["GET", "/api/results"],
      ["GET", `/api/students/${data.user.id}/results`],
    ];
    const results = [];
    for (const [method, route] of candidates) {
      results.push(await api(method, route, { token: data.token, body: method === "POST" ? {} : undefined }));
    }
    if (results.every((r) => r.status === 404)) {
      t.skip("BLOQUEADO: no hay rutas HTTP para inscripción, intentos ni resultados. La lógica está probada a nivel SQL (CP-BD-01/02).");
      return;
    }
    assert.ok(results.some((r) => r.status !== 404));
  });
});

describe("Persistencia", { skip: BLOCKED }, () => {
  test("CP-PER-01 el registro se guarda en PostgreSQL de forma segura", async () => {
    const { user, res } = await registerUser();
    const { rows } = await admin.query(
      `SELECT u.email, u.password_hash, u.activo, r.codigo, ur.activo AS rol_activo
       FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id JOIN roles r ON r.id = ur.rol_id
       WHERE u.id = $1`,
      [res.data.user.id]
    );
    assert.equal(rows.length, 1, "un único rol asignado");
    assert.equal(rows[0].email, user.email);
    assert.notEqual(rows[0].password_hash, user.password, "la contraseña NO se guarda en texto plano");
    assert.match(rows[0].password_hash, /^\$2[aby]\$10\$.{53}$/, "hash bcrypt de costo 10");
    assert.equal(rows[0].activo, true);
    assert.equal(rows[0].codigo, "ESTUDIANTE");
    assert.equal(rows[0].rol_activo, true);
  });

  test("CP-PER-02 los datos sobreviven a un reinicio del backend", async () => {
    const { user, res } = await registerUser();
    assert.equal(res.status, 201);

    // Proceso nuevo e independiente: node backend/src/server.js
    const port = 3900 + Math.floor(Math.random() * 90);
    const child = spawn(process.execPath, ["src/server.js"], {
      cwd: BACKEND_DIR,
      env: { ...process.env, PORT: String(port), NODE_ENV: "test" },
      stdio: ["ignore", "pipe", "pipe"],
    });
    try {
      await new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error("El servidor no arrancó en 10 s")), 10000);
        let output = "";
        const onData = (chunk) => {
          output += chunk;
          if (output.includes("Servidor corriendo")) { clearTimeout(timer); resolve(); }
        };
        child.stdout.on("data", onData);
        child.stderr.on("data", onData);
        child.on("exit", (code) => { clearTimeout(timer); reject(new Error(`server.js terminó (${code}): ${output}`)); });
      });
      const r = await fetch(`http://127.0.0.1:${port}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: user.email, password: user.password }),
      });
      assert.equal(r.status, 200);
    } finally {
      child.removeAllListeners("exit");
      child.kill();
    }
  });

  test("CP-PER-03 un registro rechazado no deja datos a medias", async () => {
    const count = async () => {
      const { rows } = await admin.query(
        "SELECT (SELECT COUNT(*) FROM usuarios)::int AS u, (SELECT COUNT(*) FROM usuario_roles)::int AS r"
      );
      return rows[0];
    };
    const before = await count();
    await api("POST", "/api/auth/register", {
      body: { nombre: "Dup", apellido: "Dup", email: config.demoEmail, password: "ClaveSegura-1" },
    });
    await registerUser({ email: "invalido" });
    assert.deepEqual(await count(), before);
  });

  test("CP-PER-04 resultados persistidos del seed de integración", async () => {
    // Se consulta con la MISMA cuenta que usa el backend (rol limitado).
    const pool = requireFromBackend(path.join(BACKEND_DIR, "src/config/db.js"));
    const { rows } = await pool.query(
      `SELECT a.finalidad, r.promedio_porcentaje::float AS promedio, r.nota_academica_porcentaje::float AS nota
       FROM resultados_actividades r
       JOIN actividades a ON a.id = r.actividad_id
       JOIN inscripciones i ON i.id = r.inscripcion_id
       JOIN usuarios u ON u.id = i.estudiante_id
       WHERE lower(u.email) = lower($1)
       ORDER BY a.finalidad`,
      [config.demoEmail]
    );
    const evaluacion = rows.find((r) => r.finalidad === "EVALUACION");
    const practica = rows.find((r) => r.finalidad === "PRACTICA");
    assert.equal(practica.promedio, 50);
    assert.equal(practica.nota, null);
    assert.equal(evaluacion.promedio, 100);
    assert.equal(evaluacion.nota, 100);
  });
});

describe("API general", { skip: BLOCKED }, () => {
  test("CP-BE-09 health check y ruta inexistente", async () => {
    const health = await api("GET", "/api/health");
    assert.equal(health.status, 200);
    assert.equal(health.data.status, "ok");
    const missing = await api("GET", "/api/no-existe");
    assert.equal(missing.status, 404);
    assert.equal(missing.data.message, "Ruta no encontrada");
  });

  test("CP-MOT-11 backend llama al motor: POST /api/adaptive/analyze", async (t) => {
    const { data } = await login(config.demoEmail, config.demoPassword);
    const res = await api("POST", "/api/adaptive/analyze", {
      token: data.token,
      body: {
        student_id: data.user.id,
        topic: "SQL JOIN",
        interactions: [{ study_minutes: 20, errors: 6, attempts: 3, repetitions: 1, navigation_count: 5, score_percentage: 45 }],
      },
    });
    if (blockIfMissing(t, res, "POST /api/adaptive/analyze (integración backend → motor Python)")) return;
    assert.equal(res.status, 200);
    assert.equal(res.data.recommendation.action, "reinforce_topic");
  });
});
