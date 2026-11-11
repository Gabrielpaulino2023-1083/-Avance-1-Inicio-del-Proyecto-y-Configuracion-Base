// Crea desde cero la base de QA usando SOLO los archivos del repositorio,
// en el orden que indica database/README.md (sección 4):
//   001 → 002 → 003 → security/001 → 004 → seeds → seed de integración.
//
// Uso:  npm run preparar-bd
// Requiere psql en el PATH y la cuenta administrativa de tests/.env.test.
import { spawnSync } from "node:child_process";
import path from "node:path";
import fs from "node:fs";
import { config, DATABASE_DIR, requireFromBackend, LOGS_DIR, ensureDir } from "../config.mjs";

const bcrypt = requireFromBackend("bcryptjs");

if (!/_qa$/.test(config.dbName)) {
  console.error(`Por seguridad, QA_DB_NAME debe terminar en _qa (recibido: ${config.dbName}).`);
  process.exit(1);
}

const baseEnv = {
  ...process.env,
  PGHOST: config.pgHost,
  PGPORT: String(config.pgPort),
  PGUSER: config.adminUser,
  PGPASSWORD: config.adminPassword,
  PGCLIENTENCODING: "UTF8",
};

const log = [];

function psql(args, { input, db = config.dbName, label } = {}) {
  const result = spawnSync("psql", ["-X", "-v", "ON_ERROR_STOP=1", "-d", db, ...args], {
    env: baseEnv,
    input,
    encoding: "utf8",
  });
  log.push(`### ${label ?? args.join(" ")}\n${result.stdout ?? ""}${result.stderr ?? ""}`);
  if (result.error) {
    throw new Error(`No se pudo ejecutar psql: ${result.error.message}. ¿Está instalado y en el PATH?`);
  }
  if (result.status !== 0) {
    throw new Error(`Falló "${label}":\n${result.stderr}`);
  }
  return result.stdout;
}

const step = (msg) => console.log(`  • ${msg}`);

try {
  console.log(`Preparando la base de QA "${config.dbName}" en ${config.pgHost}:${config.pgPort}`);

  step("Recreando la base de datos de QA");
  psql(["-c", `DROP DATABASE IF EXISTS ${config.dbName} WITH (FORCE)`], { db: "postgres", label: "DROP DATABASE" });
  psql(["-c", `CREATE DATABASE ${config.dbName} ENCODING 'UTF8' TEMPLATE template0`], {
    db: "postgres",
    label: "CREATE DATABASE",
  });

  const files = [
    "migrations/001_estructura_academica_inicial.sql",
    "migrations/002_modulos_temas.sql",
    "migrations/003_actividades_intentos_respuestas.sql",
    "security/001_roles_permisos.sql",
    "migrations/004_inscripcion_estudiantes.sql",
    "seeds/datos_prueba.sql",
    "seeds/datos_prueba_modulos_temas.sql",
  ];
  for (const file of files) {
    step(`Aplicando database/${file}`);
    psql(["-f", path.join(DATABASE_DIR, file)], { label: file });
  }

  // El seed de integración pide el hash con \prompt; se lo enviamos por la entrada estándar.
  step("Cargando seed de integración (cuenta demo con hash bcrypt real)");
  const hash = bcrypt.hashSync(config.demoPassword, 10);
  psql(["-f", path.join(DATABASE_DIR, "seeds/datos_prueba_actividades_intentos.sql")], {
    input: `${hash}\n`,
    label: "seeds/datos_prueba_actividades_intentos.sql",
  });

  if (config.appUser !== config.adminUser) {
    step(`Asignando la contraseña de QA al rol ${config.appUser} (APP_DB_PASSWORD)`);
    const escaped = config.appPassword.replace(/'/g, "''");
    psql(["-c", `ALTER ROLE ${config.appUser} PASSWORD '${escaped}'`], { label: "ALTER ROLE (password oculto)" });
  }

  const counts = psql(
    [
      "-tAc",
      `SELECT (SELECT COUNT(*) FROM pg_tables WHERE schemaname='public') || ' tablas, ' ||
              (SELECT COUNT(*) FROM pg_views WHERE schemaname='public') || ' vista(s), ' ||
              (SELECT COUNT(*) FROM usuarios) || ' usuarios'`,
    ],
    { label: "conteo de objetos" }
  ).trim();
  console.log(`\nBase de QA lista: ${counts}.`);
  console.log(`Cuenta demo: ${config.demoEmail}`);
} catch (error) {
  console.error(`\nERROR: ${error.message}`);
  process.exitCode = 1;
} finally {
  ensureDir(LOGS_DIR);
  fs.writeFileSync(path.join(LOGS_DIR, "preparar_bd.log"), log.join("\n\n"), "utf8");
}
