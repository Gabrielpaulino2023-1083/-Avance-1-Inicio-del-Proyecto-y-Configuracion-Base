// Configuración compartida por todos los scripts y pruebas de QA.
// Lee tests/.env.test (si existe) sin depender de paquetes externos.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

export const TESTS_DIR = path.dirname(fileURLToPath(import.meta.url));
export const ROOT_DIR = path.resolve(TESTS_DIR, "..");
export const BACKEND_DIR = path.join(ROOT_DIR, "backend");
export const FRONTEND_DIR = path.join(ROOT_DIR, "frontend");
export const ENGINE_DIR = path.join(ROOT_DIR, "adaptive-engine");
export const DATABASE_DIR = path.join(ROOT_DIR, "database");
export const EVIDENCE_DIR = path.join(TESTS_DIR, "evidencias");
export const SCREENSHOTS_DIR = path.join(EVIDENCE_DIR, "capturas");
export const LOGS_DIR = path.join(EVIDENCE_DIR, "logs");
export const REPORTS_DIR = path.join(TESTS_DIR, "reportes");

function loadEnvFile(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (!match) continue;
    const [, key, raw] = match;
    // Las variables ya definidas en la terminal tienen prioridad.
    if (process.env[key] === undefined) {
      process.env[key] = raw.replace(/^["']|["']$/g, "");
    }
  }
}

loadEnvFile(path.join(TESTS_DIR, ".env.test"));

const env = process.env;

export const config = {
  pgHost: env.PGHOST || "localhost",
  pgPort: Number(env.PGPORT || 5432),
  adminUser: env.PG_ADMIN_USER || "postgres",
  adminPassword: env.PG_ADMIN_PASSWORD || "",
  dbName: env.QA_DB_NAME || "motor_adaptativo_qa",
  appUser: env.APP_DB_PASSWORD ? env.APP_DB_USER || "plataforma_backend" : env.PG_ADMIN_USER || "postgres",
  appPassword: env.APP_DB_PASSWORD || env.PG_ADMIN_PASSWORD || "",
  jwtSecret: env.JWT_SECRET || "qa-secreto-local-no-usar-en-produccion",
  demoEmail: env.DEMO_EMAIL || "estudiante.demo@example.com",
  demoPassword: env.DEMO_PASSWORD || "DemoEquipo-2026!",
  python: env.PYTHON || (process.platform === "win32" ? "python" : "python3"),
  browserChannel: env.E2E_BROWSER_CHANNEL ?? "chrome",
};

// Permite usar los paquetes ya instalados en backend/ (pg, bcryptjs, jsonwebtoken)
// sin duplicarlos en tests/.
export const requireFromBackend = createRequire(path.join(BACKEND_DIR, "package.json"));

// Prepara las variables que lee backend/src/config antes de cargar la app.
export function configureBackendEnv() {
  process.env.NODE_ENV = "test";
  process.env.DB_HOST = config.pgHost;
  process.env.DB_PORT = String(config.pgPort);
  process.env.DB_NAME = config.dbName;
  process.env.DB_USER = config.appUser;
  process.env.DB_PASSWORD = config.appPassword;
  process.env.JWT_SECRET = config.jwtSecret;
}

// Comprueba si la base de QA responde. Devuelve null si todo va bien
// o un texto con el motivo del bloqueo.
export async function checkDatabase() {
  const { Client } = requireFromBackend("pg");
  const client = new Client({
    host: config.pgHost,
    port: config.pgPort,
    database: config.dbName,
    user: config.appUser,
    password: config.appPassword,
    connectionTimeoutMillis: 3000,
  });
  try {
    await client.connect();
    const { rows } = await client.query(
      "SELECT COUNT(*)::int AS n FROM usuarios WHERE lower(email) = lower($1)",
      [config.demoEmail]
    );
    if (rows[0].n === 0) {
      return "La base de QA existe pero no tiene la cuenta demo. Ejecuta: npm run preparar-bd";
    }
    return null;
  } catch (error) {
    return `Base de datos de QA no disponible (${error.message}). Ejecuta: npm run preparar-bd`;
  } finally {
    await client.end().catch(() => {});
  }
}

export function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}
