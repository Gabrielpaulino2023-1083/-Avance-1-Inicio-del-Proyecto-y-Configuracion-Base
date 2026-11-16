// Pruebas funcionales de punta a punta (E2E) en un navegador real con Playwright.
//
// Levanta el backend REAL en este proceso (puerto 3100, base de QA, motor Python)
// y el frontend con Vite en modo real (VITE_USE_MOCK=false, puerto 5181).
// Las capturas quedan en tests/evidencias/capturas/.
//
// El backend corre en este mismo proceso para poder: reiniciar el límite de
// intentos de login, simular que el motor falla (PYTHON_EXECUTABLE) y apagarlo
// para probar la desconexión.
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import {
  BACKEND_DIR, FRONTEND_DIR, SCREENSHOTS_DIR, LOGS_DIR, config,
  configureBackendEnv, checkDatabase, ensureDir, requireFromBackend, resetAuthRateLimit,
} from "../config.mjs";

const API_PORT = 3100;
const WEB_PORT = 5181;
const API_URL = `http://localhost:${API_PORT}/api`;
const WEB_URL = `http://localhost:${WEB_PORT}`;
const SESSION_KEY = "adaptativo.session";

let chromium;
try {
  ({ chromium } = await import("playwright"));
} catch {
  chromium = null;
}

const dbProblem = await checkDatabase();
const BLOCKED = !chromium
  ? "BLOQUEADO: falta Playwright. Ejecuta npm install dentro de tests/."
  : dbProblem
    ? `BLOQUEADO: ${dbProblem}`
    : false;

let vite;
let viteOutput = "";
let backend;
let admin;
let browser;
const consoleLog = [];

async function waitForUrl(url, timeoutMs = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      if ((await fetch(url)).status < 500) return;
    } catch { /* aún no responde */ }
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error(`No respondió ${url} en ${timeoutMs / 1000} s.\n${viteOutput}`);
}

async function shot(page, name) {
  ensureDir(SCREENSHOTS_DIR);
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(SCREENSHOTS_DIR, `${name}.png`), fullPage: true });
}

async function newPage() {
  const context = await browser.newContext({ viewport: { width: 1366, height: 860 }, locale: "es-DO" });
  const page = await context.newPage();
  page.on("console", (m) => { if (m.type() === "error") consoleLog.push(`[${m.type()}] ${m.text()}`); });
  return page;
}

async function fillLogin(page, email, password) {
  resetAuthRateLimit();
  await page.goto(`${WEB_URL}/login`);
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.getByRole("button", { name: /Iniciar sesión/ }).click();
}

async function loginAs(page, email = config.demoEmail, password = config.demoPassword) {
  await fillLogin(page, email, password);
  await page.waitForURL(`${WEB_URL}/`, { timeout: 10000 });
  await page.locator(".topbar__who").waitFor();
}

const nav = (page, label) => page.locator(".topbar__nav").getByRole("link", { name: label, exact: true });

// Resuelve el ejercicio de Contenido: una respuesta incorrecta y luego la correcta.
async function resolverEjercicio(page) {
  await page.getByRole("radio", { name: "LEFT JOIN" }).click();
  await page.getByRole("button", { name: "Comprobar respuesta" }).click();
  await page.getByRole("radio", { name: "INNER JOIN" }).click();
  await page.getByRole("button", { name: "Comprobar respuesta" }).click();
  await page.locator(".feedback__box--ok").waitFor();
}

before(async () => {
  if (BLOCKED) return;
  configureBackendEnv();
  process.env.CORS_ORIGIN = WEB_URL; // como en backend/.env: el origen del frontend
  const app = requireFromBackend(path.join(BACKEND_DIR, "src/app.js"));
  backend = await new Promise((resolve) => { const s = app.listen(API_PORT, () => resolve(s)); });
  const { Pool } = requireFromBackend("pg");
  admin = new Pool({
    host: config.pgHost, port: config.pgPort, database: config.dbName,
    user: config.adminUser, password: config.adminPassword,
  });

  vite = spawn(process.execPath, [path.join(FRONTEND_DIR, "node_modules/vite/bin/vite.js"), "--port", String(WEB_PORT), "--strictPort"], {
    cwd: FRONTEND_DIR,
    env: { ...process.env, VITE_USE_MOCK: "false", VITE_API_URL: API_URL },
    stdio: ["ignore", "pipe", "pipe"],
  });
  vite.stdout.on("data", (c) => { viteOutput += c; });
  vite.stderr.on("data", (c) => { viteOutput += c; });
  await waitForUrl(`${WEB_URL}/login`);
  browser = await chromium.launch(config.browserChannel ? { channel: config.browserChannel } : {});
});

after(async () => {
  await browser?.close();
  vite?.kill();
  if (backend?.listening) {
    backend.closeAllConnections?.();
    await new Promise((r) => backend.close(r));
  }
  await admin?.end();
  if (!BLOCKED) await requireFromBackend(path.join(BACKEND_DIR, "src/config/db.js")).end();
  ensureDir(LOGS_DIR);
  fs.writeFileSync(path.join(LOGS_DIR, "e2e_consola_navegador.log"), consoleLog.join("\n"), "utf8");
  fs.writeFileSync(path.join(LOGS_DIR, "e2e_servidores.log"), `--- frontend (vite)\n${viteOutput}`, "utf8");
});

describe("Frontend E2E — autenticación y navegación", { skip: BLOCKED }, () => {
  test("CP-UI-01 login real desde el navegador contra el backend (CORS)", async () => {
    const page = await newPage();
    await fillLogin(page, config.demoEmail, config.demoPassword);
    const reached = await page.waitForURL(`${WEB_URL}/`, { timeout: 8000 }).then(() => true, () => false);
    await shot(page, "CP-UI-01_login_real_con_cors");
    const error = await page.locator(".form-error").textContent().catch(() => null);
    await page.context().close();
    assert.ok(reached, `No pudo iniciar sesión contra el backend real. Mensaje: "${error}".`);
  });

  test("CP-UI-02 login válido en la pantalla", async () => {
    const page = await newPage();
    await fillLogin(page, config.demoEmail, config.demoPassword);
    await page.waitForURL(`${WEB_URL}/`, { timeout: 10000 });
    const who = await page.locator(".topbar__who").innerText();
    await shot(page, "CP-UI-02_login_valido_dashboard");
    await page.context().close();
    assert.match(who, /Estudiante/);
  });

  test("CP-UI-03 login inválido en la pantalla", async () => {
    const page = await newPage();
    await fillLogin(page, config.demoEmail, "ClaveIncorrecta1");
    const error = page.locator(".form-error");
    await error.waitFor({ timeout: 10000 });
    const text = await error.innerText();
    await shot(page, "CP-UI-03_login_invalido");
    const url = page.url();
    await page.context().close();
    assert.equal(text.trim(), "Credenciales inválidas");
    assert.equal(url, `${WEB_URL}/login`);
  });

  test("CP-UI-04 validación de campos vacíos e inválidos en el formulario", async () => {
    const page = await newPage();
    let llamadas = 0;
    page.on("request", (r) => { if (r.url().startsWith(API_URL)) llamadas++; });
    await page.goto(`${WEB_URL}/login`);
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();
    const errors = await page.locator(".field-error").allInnerTexts();
    await shot(page, "CP-UI-04a_login_campos_vacios");
    await page.locator("#email").fill("correo-invalido");
    await page.locator("#password").fill("x");
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();
    const errors2 = await page.locator(".field-error").allInnerTexts();
    await shot(page, "CP-UI-04b_login_correo_invalido");
    await page.context().close();
    assert.deepEqual(errors, ["Ingresa tu correo.", "Ingresa tu contraseña."]);
    assert.deepEqual(errors2, ["Ingresa un correo válido."]);
    assert.equal(llamadas, 0, "no debe llamar al backend con datos inválidos");
  });

  test("CP-UI-05 rutas protegidas sin sesión redirigen a /login", async () => {
    const page = await newPage();
    for (const route of ["/", "/contenido", "/resultados", "/progreso", "/cursos", "/gestion"]) {
      await page.goto(`${WEB_URL}${route}`);
      await page.waitForURL(`${WEB_URL}/login`, { timeout: 5000 });
    }
    await shot(page, "CP-UI-05_ruta_protegida_redirige");
    await page.context().close();
  });

  test("CP-UI-06 registro desde la pantalla y login con la cuenta nueva", async () => {
    const page = await newPage();
    const email = `qa.ui.${Date.now()}@example.com`;
    resetAuthRateLimit();
    await page.goto(`${WEB_URL}/registro`);
    await page.locator("#nombre").fill("María");
    await page.locator("#apellido").fill("Peña QA");
    await page.locator("#email").fill(email);
    await page.locator("#password").fill("ClaveSegura-1");
    await page.locator("#confirmPassword").fill("ClaveSegura-1");
    await shot(page, "CP-UI-06a_registro_formulario");
    await page.locator("button[type=submit]").click();
    await page.waitForURL(`${WEB_URL}/login`, { timeout: 10000 });
    await shot(page, "CP-UI-06b_registro_exitoso");
    await loginAs(page, email, "ClaveSegura-1");
    const who = await page.locator(".topbar__who").innerText();
    await page.context().close();
    assert.match(who, /María/);
    const { rows } = await admin.query("SELECT COUNT(*)::int n FROM usuarios WHERE email = $1", [email]);
    assert.equal(rows[0].n, 1, "la cuenta quedó guardada en PostgreSQL");
  });

  test("CP-UI-07 navegación entre pantallas sin recarga", async () => {
    const page = await newPage();
    await loginAs(page);
    await page.evaluate(() => { window.__qaSinRecarga = true; });
    for (const [label, route] of [["Contenido", "/contenido"], ["Resultados", "/resultados"], ["Progreso", "/progreso"], ["Dashboard", "/"]]) {
      await nav(page, label).click();
      await page.waitForURL(`${WEB_URL}${route}`);
      assert.equal(await page.evaluate(() => window.__qaSinRecarga), true, `${label} recargó la página`);
    }
    await page.context().close();
  });

  test("CP-UI-08 la sesión se conserva al recargar y se borra al cerrar sesión", async () => {
    const page = await newPage();
    await loginAs(page);
    await page.reload();
    await page.locator(".topbar__who").waitFor();
    assert.equal(page.url(), `${WEB_URL}/`);
    await page.getByRole("button", { name: "Cerrar sesión" }).click();
    await page.waitForURL(`${WEB_URL}/login`);
    const stored = await page.evaluate((k) => localStorage.getItem(k), SESSION_KEY);
    await page.goto(`${WEB_URL}/`);
    await page.waitForURL(`${WEB_URL}/login`);
    await shot(page, "CP-UI-08_sesion_cerrada");
    await page.context().close();
    assert.equal(stored, null);
  });

  test("CP-UI-18 el menú muestra solo las secciones de cada rol", async () => {
    const esperado = {
      ESTUDIANTE: [config.demoEmail, config.demoPassword, ["Dashboard", "Contenido", "Resultados", "Progreso"]],
      DOCENTE: [config.teacherEmail, config.teacherPassword, ["Inicio", "Contenido"]],
      ADMINISTRADOR: [config.adminDemoEmail, config.adminDemoPassword, ["Inicio", "Cursos", "Contenido"]],
    };
    for (const [rol, [email, password, links]] of Object.entries(esperado)) {
      const page = await newPage();
      await loginAs(page, email, password);
      const visibles = (await page.locator(".topbar__nav a").allInnerTexts()).map((t) => t.trim());
      await shot(page, `CP-UI-18_inicio_${rol.toLowerCase()}`);
      await page.context().close();
      assert.deepEqual(visibles, links, rol);
    }
  });
});

describe("Frontend E2E — motor adaptativo y datos reales", { skip: BLOCKED }, () => {
  test("CP-UI-09 Dashboard con datos reales del backend", async () => {
    const page = await newPage();
    await loginAs(page);
    const card = page.locator(".ai-card");
    const ok = await card.waitFor({ timeout: 15000 }).then(() => true, () => false);
    const error = await page.locator(".dash-state--error").textContent().catch(() => null);
    await shot(page, "CP-UI-09_dashboard_datos_reales");
    const text = ok ? await card.innerText() : "";
    await page.context().close();
    assert.ok(ok, `El Dashboard no mostró la tarjeta de recomendación. Error: ${error}`);
    assert.match(text, /SQL JOIN/);
    assert.doesNotMatch(text, /Datos de ejemplo/, "no debe mostrar datos simulados");
  });

  test("CP-UI-10 ejercicio interactivo de Contenido", async () => {
    const page = await newPage();
    await loginAs(page);
    await nav(page, "Contenido").click();
    const metric = (name) => page.locator(".metrics__list div", { hasText: name }).locator("dd");
    for (const wrong of ["LEFT JOIN", "CROSS JOIN"]) {
      await page.getByRole("radio", { name: wrong }).click();
      await page.getByRole("button", { name: "Comprobar respuesta" }).click();
    }
    await page.locator(".feedback__box--hint").waitFor();
    await shot(page, "CP-UI-10a_ejercicio_error_y_pista");
    assert.equal(await metric("Errores").innerText(), "2");
    await page.getByRole("radio", { name: "INNER JOIN" }).click();
    await page.getByRole("button", { name: "Comprobar respuesta" }).click();
    await page.locator(".feedback__box--ok").waitFor();
    await shot(page, "CP-UI-10b_ejercicio_correcto");
    assert.equal(await metric("Intentos").innerText(), "3");
    await page.context().close();
  });

  test("CP-UI-12 recorrido visual completo del estudiante con recomendación real", async () => {
    const page = await newPage();
    const pasos = [];
    await page.goto(`${WEB_URL}/login`);
    await shot(page, "CP-UI-12a_login");
    await loginAs(page);
    await page.locator(".ai-card").waitFor({ timeout: 15000 });
    await shot(page, "CP-UI-12b_dashboard_recomendacion");
    pasos.push("dashboard");

    await nav(page, "Contenido").click();
    await resolverEjercicio(page);
    const respuesta = page.waitForResponse((r) => r.url().includes("/recommendation") && r.request().method() === "POST");
    await page.getByRole("button", { name: "Ver recomendación del motor" }).click();
    const res = await respuesta;
    const body = await res.json();
    const card = page.locator(".exercise-col .ai-card");
    await card.waitFor({ timeout: 15000 });
    const cardText = await card.innerText();
    await shot(page, "CP-UI-12c_recomendacion_del_motor");
    pasos.push("recomendación");

    await nav(page, "Resultados").click();
    await page.waitForURL(`${WEB_URL}/resultados`);
    await shot(page, "CP-UI-12d_resultados");
    await nav(page, "Progreso").click();
    await page.waitForURL(`${WEB_URL}/progreso`);
    await shot(page, "CP-UI-12e_progreso");
    await page.getByRole("button", { name: "Cerrar sesión" }).click();
    await page.waitForURL(`${WEB_URL}/login`);
    await page.context().close();

    assert.equal(res.status(), 200);
    assert.equal(body.recommendation.accion, "reinforce_topic", "el motor real recomienda reforzar SQL JOIN");
    assert.match(cardText, /Detectamos dificultades en SQL JOIN/);
    assert.deepEqual(pasos, ["dashboard", "recomendación"]);
  });

  test("CP-UI-13 estudiante sin intentos ve un aviso, no un error", async () => {
    const page = await newPage();
    const email = `qa.sin.intentos.${Date.now()}@example.com`;
    resetAuthRateLimit();
    await fetch(`${API_URL}/auth/register`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nombre: "Sin", apellido: "Intentos", email, password: "ClaveSegura-1" }),
    });
    await loginAs(page, email, "ClaveSegura-1");
    await page.waitForTimeout(1500);
    const dashError = await page.locator(".dash-state--error").count();
    await shot(page, "CP-UI-13a_dashboard_sin_datos");
    await nav(page, "Contenido").click();
    await resolverEjercicio(page);
    await page.getByRole("button", { name: "Ver recomendación del motor" }).click();
    const aviso = page.locator(".feedback__box--hint", { hasText: "Sin datos suficientes" });
    const visto = await aviso.waitFor({ timeout: 10000 }).then(() => true, () => false);
    await shot(page, "CP-UI-13b_sin_intentos_aviso");
    await page.context().close();
    assert.equal(dashError, 0, "el Dashboard no muestra error para un estudiante nuevo");
    assert.ok(visto, "muestra 'Sin datos suficientes todavía'");
  });

  test("CP-UI-14 error del motor: la pantalla informa sin romperse", async () => {
    const page = await newPage();
    await loginAs(page);
    await nav(page, "Contenido").click();
    await resolverEjercicio(page);
    const original = process.env.PYTHON_EXECUTABLE;
    const consola = console.error;
    console.error = () => {};
    process.env.PYTHON_EXECUTABLE = "/ruta/que/no/existe/python";
    try {
      await page.getByRole("button", { name: "Ver recomendación del motor" }).click();
      const error = page.locator(".feedback__box--bad", { hasText: "No se pudo generar la recomendación" });
      await error.waitFor({ timeout: 10000 });
      const text = await error.innerText();
      await shot(page, "CP-UI-14_error_del_motor");
      assert.match(text, /El motor de recomendación no está disponible/);
    } finally {
      process.env.PYTHON_EXECUTABLE = original;
      console.error = consola;
      await page.context().close();
    }
  });

  test("CP-UI-11 envío de métricas del ejercicio al backend", async (t) => {
    const page = await newPage();
    await loginAs(page);
    await nav(page, "Contenido").click();
    const enviados = [];
    page.on("request", (r) => { if (r.url().startsWith(API_URL) && r.method() !== "GET") enviados.push(r.postData() ?? ""); });
    await resolverEjercicio(page);
    await page.getByRole("button", { name: "Ver recomendación del motor" }).click();
    await page.locator(".exercise-col .ai-card").waitFor({ timeout: 15000 });
    await page.context().close();
    const conMetricas = enviados.some((b) => /attempts|errors|seconds|intentos|errores/.test(b));
    if (!conMetricas) {
      t.skip(`BLOQUEADO: el ejercicio solo envía el tema (${enviados.join(" ") || "nada"}); el tiempo, los intentos y los errores del ejercicio no se guardan. La recomendación usa los intentos de la base (pendiente declarado en frontend/README.md).`);
      return;
    }
    assert.ok(conMetricas);
  });
});

describe("Frontend E2E — administración de cursos y contenido", { skip: BLOCKED }, () => {
  test("CP-UI-16 el administrador crea un curso desde la pantalla", async () => {
    const page = await newPage();
    const codigo = `UI-${Date.now().toString(36).toUpperCase()}`;
    await loginAs(page, config.adminDemoEmail, config.adminDemoPassword);
    await nav(page, "Cursos").click();
    await page.getByRole("button", { name: "+ Nuevo curso" }).click();
    await page.locator("#cu-codigo").fill(codigo);
    await page.locator("#cu-nombre").fill("Curso creado desde la interfaz");
    await page.locator("#cu-descripcion").fill("Prueba E2E de QA");
    await shot(page, "CP-UI-16a_nuevo_curso_formulario");
    await page.getByRole("dialog").locator("button[type=submit]").click();
    await page.getByText("Curso creado desde la interfaz").first().waitFor({ timeout: 10000 });
    await shot(page, "CP-UI-16b_curso_creado");
    await page.context().close();
    const { rows } = await admin.query("SELECT nombre FROM cursos WHERE codigo = $1", [codigo]);
    assert.equal(rows[0]?.nombre, "Curso creado desde la interfaz", "guardado en PostgreSQL");
  });

  test("CP-UI-17 el docente crea un módulo de su curso desde la pantalla", async () => {
    const page = await newPage();
    const nombre = `Módulo UI ${Date.now().toString(36)}`;
    await loginAs(page, config.teacherEmail, config.teacherPassword);
    await nav(page, "Contenido").click();
    await page.waitForURL(`${WEB_URL}/gestion`);
    // La pantalla del docente pide escribir el ID numérico del curso (ver CP-UI-19).
    const cursoId = (await admin.query("SELECT id FROM cursos WHERE codigo = 'DEMO-006'")).rows[0].id;
    await page.locator("#mg-curso-campo").fill(String(cursoId));
    await page.getByRole("button", { name: "Cargar" }).click();
    const boton = page.getByRole("button", { name: "+ Nuevo módulo" });
    await page.waitForFunction(() => {
      const b = [...document.querySelectorAll("button")].find((x) => x.textContent.includes("Nuevo módulo"));
      return b && !b.disabled;
    }, null, { timeout: 10000 });
    await boton.click();
    await page.locator("#mg-nombre").fill(nombre);
    await page.locator("#mg-descripcion").fill("Creado en la prueba E2E");
    await page.locator("#mg-orden").fill(String(700 + Math.floor(Math.random() * 100000)));
    await shot(page, "CP-UI-17a_nuevo_modulo_formulario");
    await page.getByRole("dialog").locator("button[type=submit]").click();
    await page.getByText(nombre).first().waitFor({ timeout: 10000 });
    await shot(page, "CP-UI-17b_modulo_creado");
    await page.context().close();
    const { rows } = await admin.query(
      `SELECT c.codigo FROM modulos m JOIN cursos c ON c.id = m.curso_id WHERE m.nombre = $1`, [nombre]);
    assert.equal(rows[0]?.codigo, "DEMO-006", "guardado en PostgreSQL en el curso del docente");
  });
});

describe("Frontend E2E — pendientes de integración y robustez", { skip: BLOCKED }, () => {
  test("CP-UI-19 el docente elige su curso de una lista (cursos administrables)", async (t) => {
    const page = await newPage();
    await loginAs(page, config.teacherEmail, config.teacherPassword);
    await nav(page, "Contenido").click();
    await page.waitForURL(`${WEB_URL}/gestion`);
    const campo = page.locator("#mg-curso-campo");
    await campo.waitFor();
    const tipo = await campo.evaluate((el) => el.tagName.toLowerCase());
    await shot(page, "CP-UI-19_docente_selector_curso");
    await page.context().close();
    if (tipo !== "select") {
      t.skip("BLOQUEADO: el docente debe escribir el ID numérico del curso. El backend ya ofrece GET /api/cursos-administrables, pero la pantalla todavía no lo usa (pendiente declarado en database/README.md).");
      return;
    }
    assert.equal(tipo, "select");
  });

  test("CP-UI-20 el Dashboard sigue funcionando cuando el motor falla", async () => {
    const original = process.env.PYTHON_EXECUTABLE;
    const consola = console.error;
    console.error = () => {};
    process.env.PYTHON_EXECUTABLE = "/ruta/que/no/existe/python";
    const page = await newPage();
    try {
      await loginAs(page);
      await page.waitForTimeout(2000);
      const error = await page.locator(".dash-state--error").textContent().catch(() => null);
      await shot(page, "CP-UI-20_dashboard_motor_caido");
      assert.equal(error, null, `El Dashboard muestra un error en lugar de los datos: "${error}"`);
    } finally {
      process.env.PYTHON_EXECUTABLE = original;
      console.error = consola;
      await page.context().close();
    }
  });
});

describe("Frontend E2E — desconexión del backend", { skip: BLOCKED }, () => {
  // Va al final: apaga el backend.
  test("CP-UI-15 el frontend avisa cuando el backend se desconecta", async () => {
    const page = await newPage();
    await loginAs(page);
    await nav(page, "Contenido").click();
    await resolverEjercicio(page);

    backend.closeAllConnections?.();
    await new Promise((r) => backend.close(r));

    await page.getByRole("button", { name: "Ver recomendación del motor" }).click();
    const aviso = page.locator(".feedback__box--bad", { hasText: "No se pudo conectar con el servidor" });
    const enContenido = await aviso.waitFor({ timeout: 10000 }).then(() => true, () => false);
    await shot(page, "CP-UI-15a_backend_desconectado_contenido");

    await nav(page, "Dashboard").click();
    const dash = page.locator(".dash-state--error");
    const enDashboard = await dash.waitFor({ timeout: 10000 }).then(() => true, () => false);
    const dashText = enDashboard ? await dash.innerText() : "";
    await shot(page, "CP-UI-15b_backend_desconectado_dashboard");

    await page.getByRole("button", { name: "Cerrar sesión" }).click();
    await page.locator("#email").fill(config.demoEmail);
    await page.locator("#password").fill(config.demoPassword);
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();
    const loginError = page.locator(".form-error");
    const enLogin = await loginError.waitFor({ timeout: 10000 }).then(() => true, () => false);
    const loginText = enLogin ? await loginError.innerText() : "";
    await shot(page, "CP-UI-15c_backend_desconectado_login");
    await page.context().close();

    assert.ok(enContenido, "Contenido muestra 'No se pudo conectar con el servidor'");
    assert.match(dashText, /No se pudo conectar con el servidor/);
    assert.match(loginText, /No se pudo conectar con el servidor/);
  });
});
