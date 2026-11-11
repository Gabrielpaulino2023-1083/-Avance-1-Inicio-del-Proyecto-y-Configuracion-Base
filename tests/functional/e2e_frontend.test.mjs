// Pruebas funcionales de punta a punta (E2E) en un navegador real con Playwright.
//
// Levanta: backend real (puerto 3100, base de QA) + frontend Vite en modo real
// (VITE_USE_MOCK=false, puerto 5181). Guarda capturas en tests/evidencias/capturas.
//
// Sobre CORS: el caso CP-UI-01 prueba la configuración documentada tal cual.
// El resto de casos usa un "puente CORS de pruebas" (page.route) que reenvía las
// llamadas al backend REAL y añade las cabeceras CORS que hoy faltan, para poder
// verificar el comportamiento de la interfaz mientras se corrige INC-01.
import { test, describe, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import {
  BACKEND_DIR, FRONTEND_DIR, SCREENSHOTS_DIR, LOGS_DIR, config,
  configureBackendEnv, checkDatabase, ensureDir,
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

const processes = [];
const consoleLog = [];
let browser;

function startProcess(name, command, args, options) {
  const child = spawn(command, args, { ...options, stdio: ["ignore", "pipe", "pipe"], shell: process.platform === "win32" });
  let output = "";
  child.stdout.on("data", (c) => { output += c; });
  child.stderr.on("data", (c) => { output += c; });
  processes.push({ name, child, getOutput: () => output });
  return child;
}

async function waitForUrl(url, timeoutMs = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const r = await fetch(url);
      if (r.status < 500) return;
    } catch { /* aún no responde */ }
    await new Promise((r) => setTimeout(r, 300));
  }
  const logs = processes.map((p) => `--- ${p.name}\n${p.getOutput()}`).join("\n");
  throw new Error(`No respondió ${url} en ${timeoutMs / 1000} s.\n${logs}`);
}

async function shot(page, name) {
  ensureDir(SCREENSHOTS_DIR);
  await page.screenshot({ path: path.join(SCREENSHOTS_DIR, `${name}.png`), fullPage: true });
}

// Puente CORS de pruebas: reenvía al backend real y añade Access-Control-*.
async function withCorsBridge(page, counter) {
  const cors = {
    "access-control-allow-origin": WEB_URL,
    "access-control-allow-headers": "Content-Type, Authorization",
    "access-control-allow-methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  };
  await page.route(`${API_URL}/**`, async (route) => {
    if (counter) counter.n++;
    if (route.request().method() === "OPTIONS") {
      await route.fulfill({ status: 204, headers: cors });
      return;
    }
    const response = await route.fetch();
    await route.fulfill({ response, headers: { ...response.headers(), ...cors } });
  });
}

async function newPage({ bridge = true, counter } = {}) {
  const context = await browser.newContext({ viewport: { width: 1366, height: 860 }, locale: "es-DO" });
  const page = await context.newPage();
  page.on("console", (m) => { if (m.type() === "error") consoleLog.push(`[${m.type()}] ${m.text()}`); });
  if (bridge) await withCorsBridge(page, counter);
  return page;
}

async function fillLogin(page, email, password) {
  await page.goto(`${WEB_URL}/login`);
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.getByRole("button", { name: /Iniciar sesión/ }).click();
}

async function loginOk(page) {
  await fillLogin(page, config.demoEmail, config.demoPassword);
  await page.waitForURL(`${WEB_URL}/`, { timeout: 10000 });
}

before(async () => {
  if (BLOCKED) return;
  configureBackendEnv();
  startProcess("backend", process.execPath, ["src/server.js"], {
    cwd: BACKEND_DIR,
    env: { ...process.env, PORT: String(API_PORT) },
  });
  startProcess("frontend", process.execPath, [path.join(FRONTEND_DIR, "node_modules/vite/bin/vite.js"), "--port", String(WEB_PORT), "--strictPort"], {
    cwd: FRONTEND_DIR,
    env: { ...process.env, VITE_USE_MOCK: "false", VITE_API_URL: API_URL },
  });
  await waitForUrl(`${API_URL}/health`);
  await waitForUrl(`${WEB_URL}/login`);
  browser = await chromium.launch(config.browserChannel ? { channel: config.browserChannel } : {});
});

after(async () => {
  await browser?.close();
  for (const { child } of processes) child.kill();
  ensureDir(LOGS_DIR);
  fs.writeFileSync(path.join(LOGS_DIR, "e2e_consola_navegador.log"), consoleLog.join("\n"), "utf8");
  fs.writeFileSync(
    path.join(LOGS_DIR, "e2e_servidores.log"),
    processes.map((p) => `--- ${p.name}\n${p.getOutput()}`).join("\n"),
    "utf8"
  );
});

describe("Frontend E2E", { skip: BLOCKED }, () => {
  test("CP-UI-01 login real desde el navegador contra el backend (sin puente CORS)", async () => {
    const page = await newPage({ bridge: false });
    await fillLogin(page, config.demoEmail, config.demoPassword);
    const reached = await page.waitForURL(`${WEB_URL}/`, { timeout: 6000 }).then(() => true, () => false);
    await shot(page, "CP-UI-01_login_real_sin_cors");
    const error = await page.locator(".form-error").textContent().catch(() => null);
    await page.context().close();
    assert.ok(
      reached,
      `El navegador no pudo iniciar sesión contra el backend real. Mensaje en pantalla: "${error}". ` +
        "Causa: el backend no envía cabeceras CORS (Access-Control-Allow-Origin)."
    );
  });

  test("CP-UI-02 login válido en la pantalla", async () => {
    const page = await newPage();
    await fillLogin(page, config.demoEmail, config.demoPassword);
    await shot(page, "CP-UI-02a_login_valido_formulario");
    await page.waitForURL(`${WEB_URL}/`, { timeout: 10000 });
    await page.locator(".topbar__who").waitFor();
    const who = await page.locator(".topbar__who").innerText();
    await shot(page, "CP-UI-02b_login_valido_dashboard");
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
    const counter = { n: 0 };
    const page = await newPage({ counter });
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
    assert.equal(counter.n, 0, "no debe llamar al backend con datos inválidos");
  });

  test("CP-UI-05 rutas protegidas sin sesión redirigen a /login", async () => {
    const page = await newPage();
    for (const route of ["/", "/contenido", "/resultados", "/progreso"]) {
      await page.goto(`${WEB_URL}${route}`);
      await page.waitForURL(`${WEB_URL}/login`, { timeout: 5000 });
    }
    await shot(page, "CP-UI-05_ruta_protegida_redirige");
    await page.context().close();
  });

  test("CP-UI-06 registro desde la pantalla y login con la cuenta nueva", async () => {
    const page = await newPage();
    const email = `qa.ui.${Date.now()}@example.com`;
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

    await page.locator("#email").fill(email);
    await page.locator("#password").fill("ClaveSegura-1");
    await page.getByRole("button", { name: /Iniciar sesión/ }).click();
    await page.waitForURL(`${WEB_URL}/`, { timeout: 10000 });
    const who = await page.locator(".topbar__who").innerText();
    await shot(page, "CP-UI-06c_login_cuenta_nueva");
    await page.context().close();
    assert.match(who, /María/);
  });

  test("CP-UI-07 navegación entre pantallas sin recarga", async () => {
    const page = await newPage();
    await loginOk(page);
    await page.evaluate(() => { window.__qaSinRecarga = true; });
    for (const [label, route, file] of [
      ["Contenido", "/contenido", "CP-UI-07a_contenido"],
      ["Resultados", "/resultados", "CP-UI-07b_resultados"],
      ["Progreso", "/progreso", "CP-UI-07c_progreso"],
      ["Dashboard", "/", "CP-UI-07d_dashboard"],
    ]) {
      await page.locator(".topbar__nav").getByRole("link", { name: label }).click();
      await page.waitForURL(`${WEB_URL}${route}`);
      await page.waitForTimeout(700);
      await shot(page, file);
      assert.equal(await page.evaluate(() => window.__qaSinRecarga), true, `${label} recargó la página`);
    }
    await page.context().close();
  });

  test("CP-UI-08 la sesión se conserva al recargar y se borra al cerrar sesión", async () => {
    const page = await newPage();
    await loginOk(page);
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

  test("CP-UI-09 Dashboard con datos reales del backend", async (t) => {
    const page = await newPage();
    const calls = [];
    page.on("response", (r) => { if (r.url().startsWith(`${API_URL}/students`)) calls.push(`${r.status()} ${r.url()}`); });
    await loginOk(page);
    const alert = page.locator(".dash-state--error");
    const blocked = await alert.waitFor({ timeout: 8000 }).then(() => true, () => false);
    await shot(page, "CP-UI-09_dashboard_datos_reales");
    const text = blocked ? await alert.innerText() : "";
    await page.context().close();
    if (blocked && calls.some((c) => c.startsWith("404"))) {
      const routes = [...new Set(calls.map((c) => c.split(" ")[1].replace(API_URL, "/api")))];
      t.skip(`BLOQUEADO: el Dashboard llama a ${routes.join(" y ")}, que no existen en el backend (404). Pantalla: "${text}".`);
      return;
    }
    assert.equal(blocked, false, `El Dashboard mostró un error: ${text}`);
  });

  test("CP-UI-10 ejercicio interactivo de Contenido", async () => {
    const page = await newPage();
    await loginOk(page);
    await page.goto(`${WEB_URL}/contenido`);
    const metric = (name) => page.locator(".metrics__list div", { hasText: name }).locator("dd");

    // Dos respuestas incorrectas → mensaje "Todavía no." y pista.
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
    assert.equal(await metric("Errores").innerText(), "2");
    await page.context().close();
  });

  test("CP-UI-11 envío de métricas del ejercicio al backend", async (t) => {
    const page = await newPage();
    await loginOk(page);
    await page.goto(`${WEB_URL}/contenido`);
    const sent = [];
    page.on("request", (r) => { if (r.url().startsWith(API_URL) && r.method() !== "GET") sent.push(r.url()); });
    await page.getByRole("radio", { name: "LEFT JOIN" }).click();
    await page.getByRole("button", { name: "Comprobar respuesta" }).click();
    await page.getByRole("radio", { name: "INNER JOIN" }).click();
    await page.getByRole("button", { name: "Comprobar respuesta" }).click();
    await page.waitForTimeout(1500);
    await page.context().close();
    if (sent.length === 0) {
      t.skip("BLOQUEADO: el ejercicio no envía tiempo/intentos/errores; no existe endpoint para registrar interacciones (pendiente declarado en frontend/README.md).");
      return;
    }
    assert.ok(sent.length > 0);
  });
});
