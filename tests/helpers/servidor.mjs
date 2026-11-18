// Utilidades compartidas por las pruebas de integración de la API:
// levanta el backend real en este mismo proceso (puerto libre), da una
// conexión administrativa a PostgreSQL para verificar la persistencia y
// ofrece atajos para iniciar sesión con las cuentas demo.
import path from "node:path";
import {
  BACKEND_DIR, config, requireFromBackend, configureBackendEnv, resetAuthRateLimit,
} from "../config.mjs";

export async function iniciarServidor() {
  configureBackendEnv();
  const app = requireFromBackend(path.join(BACKEND_DIR, "src/app.js"));
  const { Pool } = requireFromBackend("pg");
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const admin = new Pool({
    host: config.pgHost, port: config.pgPort, database: config.dbName,
    user: config.adminUser, password: config.adminPassword,
  });

  async function api(method, route, { body, token, raw } = {}) {
    if (/^\/api\/auth\/(login|register)/.test(route)) resetAuthRateLimit();
    const res = await fetch(`${baseUrl}${route}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: raw ?? (body === undefined ? undefined : JSON.stringify(body)),
    });
    return { status: res.status, data: await res.json().catch(() => null) };
  }

  const sesiones = {};
  async function sesion(rol) {
    if (sesiones[rol]) return sesiones[rol];
    const cred = {
      ESTUDIANTE: [config.demoEmail, config.demoPassword],
      ADMINISTRADOR: [config.adminDemoEmail, config.adminDemoPassword],
      DOCENTE: [config.teacherEmail, config.teacherPassword],
    }[rol];
    const r = await api("POST", "/api/auth/login", { body: { email: cred[0], password: cred[1] } });
    if (r.status !== 200) throw new Error(`No se pudo iniciar sesión como ${rol}: ${r.status}`);
    sesiones[rol] = { token: r.data.token, user: r.data.user };
    return sesiones[rol];
  }

  async function nuevoEstudiante() {
    const user = {
      nombre: "QA", apellido: "Sin Intentos",
      email: `qa.${Date.now()}.${Math.random().toString(36).slice(2, 7)}@example.com`,
      password: "ClaveSegura-1",
    };
    const reg = await api("POST", "/api/auth/register", { body: user });
    const log = await api("POST", "/api/auth/login", { body: { email: user.email, password: user.password } });
    return { ...user, id: reg.data.user.id, token: log.data.token };
  }

  async function cerrar() {
    await new Promise((resolve) => server.close(resolve));
    await requireFromBackend(path.join(BACKEND_DIR, "src/config/db.js")).end();
    await admin.end();
  }

  return { api, admin, sesion, nuevoEstudiante, cerrar, baseUrl };
}

// Número de orden alto y único para no chocar con el contenido de los seeds
// (orden es único por curso o por módulo).
export const ordenUnico = () => 500 + Math.floor(Math.random() * 1_000_000);
