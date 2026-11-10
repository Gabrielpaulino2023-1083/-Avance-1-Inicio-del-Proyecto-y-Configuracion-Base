// Consolida en la matriz las pruebas SQL que ya existían en database/test/.
// Se ejecutan con psql sobre la base de QA, como cuenta administrativa.
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { DATABASE_DIR, LOGS_DIR, config, checkDatabase, ensureDir } from "../config.mjs";

const psqlAvailable = spawnSync("psql", ["--version"], { encoding: "utf8" }).status === 0;
const dbProblem = psqlAvailable ? await checkDatabase() : "psql no está instalado o no está en el PATH";
const BLOCKED = dbProblem ? `BLOQUEADO: ${dbProblem}` : false;

function runSql(file, { stopOnError = true } = {}) {
  const r = spawnSync(
    "psql",
    ["-X", ...(stopOnError ? ["-v", "ON_ERROR_STOP=1"] : []), "-d", config.dbName, "-f", path.join(DATABASE_DIR, "test", file)],
    {
      encoding: "utf8",
      env: {
        ...process.env,
        PGHOST: config.pgHost, PGPORT: String(config.pgPort),
        PGUSER: config.adminUser, PGPASSWORD: config.adminPassword,
        PGCLIENTENCODING: "UTF8", LC_MESSAGES: "C",
      },
    }
  );
  const output = `${r.stdout}\n${r.stderr}`;
  ensureDir(LOGS_DIR);
  fs.writeFileSync(path.join(LOGS_DIR, `sql_${file.replace(".sql", "")}.log`), output, "utf8");
  return { code: r.status, output };
}

// Errores "reales" (descarta los avisos de transacción abortada que siguen al primero).
const realErrors = (output) =>
  output.split("\n").filter((l) => /ERROR:/.test(l) && !/current transaction is aborted|transacción actual está abortada/.test(l));

describe("Pruebas SQL existentes del repositorio", { skip: BLOCKED }, () => {
  test("CP-BD-01 regresión de la migración 003", () => {
    const { code, output } = runSql("pruebas_migracion_003.sql");
    assert.equal(code, 0, output.slice(-800));
    assert.match(output, /PRUEBAS 003 COMPLETADAS/);
    assert.match(output, /ROLLBACK/);
  });

  test("CP-BD-02 pruebas de la migración 004 (inscripción)", () => {
    const { code, output } = runSql("pruebas_migracion_004.sql");
    assert.equal(code, 0, output.slice(-800));
    for (let i = 1; i <= 7; i++) assert.match(output, new RegExp(`OK ${i}:`));
    assert.match(output, /PRUEBAS 004 COMPLETADAS/);
  });

  test("CP-BD-03 restricciones de integridad: 5 rechazos esperados", () => {
    const { output } = runSql("pruebas_restricciones.sql", { stopOnError: false });
    const errors = realErrors(output);
    assert.equal(errors.length, 5, errors.join("\n"));
  });

  test("CP-BD-04 orden de módulos y temas: 4 rechazos esperados", () => {
    const { output } = runSql("pruebas_temas_modulos.sql", { stopOnError: false });
    const errors = realErrors(output);
    assert.equal(errors.length, 4, errors.join("\n"));
  });

  test("CP-BD-05 permisos del rol plataforma_backend", () => {
    const { code, output } = runSql("pruebas_permisos.sql");
    assert.equal(code, 0, output);
    // Fila de resultados de psql: " f | f | f | t"
    const row = output.split("\n").find((l) => /^\s*[tf]\s*\|/.test(l));
    assert.ok(row, output);
    assert.deepEqual(row.split("|").map((v) => v.trim()), ["f", "f", "f", "t"]);
  });
});
