// Ejecuta TODA la batería de QA y genera el reporte.
//
//   npm test                      → prepara la BD de QA, corre todo y genera el reporte
//   npm test -- --sin-preparar-bd → reutiliza la base de QA existente
//   npm test -- --sin-e2e         → omite el navegador (más rápido)
//
// Cada suite escribe un archivo JUnit en reportes/junit/ y su salida en evidencias/logs/.
//
// Antes de tocar nada, comprueba los requisitos (Node, psql, Python). Si falta
// alguno, se detiene SIN borrar las capturas ni el reporte anteriores.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { TESTS_DIR, ENGINE_DIR, LOGS_DIR, REPORTS_DIR, SCREENSHOTS_DIR, config, ensureDir } from "../config.mjs";
import { generarReporte } from "./generar_reporte.mjs";

const args = new Set(process.argv.slice(2));

// ------------------------------------------------------------ requisitos
const funciona = (cmd, cmdArgs) => spawnSync(cmd, cmdArgs, { encoding: "utf8" }).status === 0;
const problemas = [];

const [mayor, menor] = process.versions.node.split(".").map(Number);
if (mayor < 22 || (mayor === 22 && menor < 18)) {
  problemas.push(`Node.js ${process.versions.node} es muy antiguo: se necesita 22.18 o superior.\n    Instala la versión LTS desde https://nodejs.org, cierra VS Code y vuelve a abrirlo.`);
}

if (!funciona("psql", ["--version"])) {
  // En Windows, PostgreSQL se instala en C:\Program Files\PostgreSQL\<versión>\bin aunque no esté en el PATH.
  const base = "C:\\Program Files\\PostgreSQL";
  const bin = process.platform === "win32" && fs.existsSync(base)
    ? fs.readdirSync(base).sort((a, b) => Number(b) - Number(a)).map((v) => path.join(base, v, "bin"))
        .find((d) => fs.existsSync(path.join(d, "psql.exe")))
    : null;
  if (bin) {
    process.env.PATH = `${bin}${path.delimiter}${process.env.PATH}`;
    console.log(`(psql no estaba en el PATH; se usa ${bin})`);
  } else {
    problemas.push("No se encontró psql (PostgreSQL).\n    Instálalo desde https://www.postgresql.org/download/windows o agrega su carpeta bin al PATH.");
  }
}

// Python con pandas y pytest: prueba el de .env.test y luego python, py y python3.
const candidatos = [...new Set([process.env.PYTHON, "python", "py", "python3"].filter(Boolean))];
const python = candidatos.find((c) => funciona(c, ["-c", "import pandas, pytest"]));
if (python) {
  process.env.PYTHON = python; // lo heredan las pruebas y el backend (PYTHON_EXECUTABLE)
  config.python = python;
} else {
  const alguno = candidatos.find((c) => funciona(c, ["--version"]));
  problemas.push(alguno
    ? `Python (${alguno}) no tiene pandas o pytest.\n    Ejecuta: ${alguno} -m pip install -r tests/requirements.txt`
    : "No se encontró Python.\n    Instálalo desde https://www.python.org marcando \"Add python.exe to PATH\", reinicia VS Code y ejecuta: python -m pip install -r tests/requirements.txt");
}

if (problemas.length) {
  console.error("\nNo se ejecutaron las pruebas porque faltan requisitos:\n");
  for (const p of problemas) console.error(`  ✗ ${p}\n`);
  console.error("No se modificó ningún reporte ni captura. Corrige lo anterior y vuelve a ejecutar: npm test");
  process.exit(1);
}

const JUNIT_DIR = ensureDir(path.join(REPORTS_DIR, "junit"));
ensureDir(LOGS_DIR);

// Resultados limpios en cada ejecución.
for (const f of fs.readdirSync(JUNIT_DIR)) fs.rmSync(path.join(JUNIT_DIR, f));
if (!args.has("--sin-e2e") && fs.existsSync(SCREENSHOTS_DIR)) {
  for (const f of fs.readdirSync(SCREENSHOTS_DIR)) fs.rmSync(path.join(SCREENSHOTS_DIR, f));
}

function run(title, command, commandArgs, logName, cwd = TESTS_DIR) {
  console.log(`\n━━━ ${title} ━━━`);
  const started = Date.now();
  const r = spawnSync(command, commandArgs, {
    cwd,
    encoding: "utf8",
    env: { ...process.env, FORCE_COLOR: "0", PYTHONIOENCODING: "utf-8" },
    maxBuffer: 64 * 1024 * 1024,
  });
  const output = `${r.stdout ?? ""}${r.stderr ?? ""}${r.error ? `\n${r.error.message}` : ""}`;
  fs.writeFileSync(path.join(LOGS_DIR, `${logName}.log`), output, "utf8");
  const summary = output.split("\n").filter((l) => /^ℹ (tests|pass|fail|skipped)|(passed|failed|skipped).* in \d/.test(l));
  console.log(summary.length ? summary.join("\n") : output.split("\n").slice(-5).join("\n"));
  console.log(`(${((Date.now() - started) / 1000).toFixed(1)} s, salida completa en evidencias/logs/${logName}.log)`);
  return r.status;
}

// Lista los archivos *.test.mjs de una carpeta (en orden), sin depender de patrones glob.
function archivosDePrueba(carpeta) {
  const out = [];
  const recorrer = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) recorrer(full);
      else if (e.name.endsWith(".test.mjs")) out.push(path.relative(TESTS_DIR, full));
    }
  };
  recorrer(path.join(TESTS_DIR, carpeta));
  return out;
}

const nodeSuite = (carpeta, junit, extra = []) => [
  "--test", ...extra,
  "--test-reporter=spec", "--test-reporter-destination=stdout",
  "--test-reporter=junit", `--test-reporter-destination=${path.join(JUNIT_DIR, junit)}`,
  ...archivosDePrueba(carpeta),
];

const inicio = new Date();

if (!args.has("--sin-preparar-bd")) {
  run("Preparando la base de datos de QA", process.execPath, ["scripts/preparar_bd.mjs"], "00_preparar_bd");
}

run("Pruebas unitarias — backend y frontend", process.execPath, nodeSuite("unit", "unit_node.xml"), "01_unitarias_node");

run(
  "Pruebas unitarias — motor adaptativo (pytest)",
  config.python,
  ["-m", "pytest", "unit/motor", "-v", "-p", "no:cacheprovider", "--color=no", `--junitxml=${path.join(JUNIT_DIR, "unit_motor.xml")}`],
  "02_unitarias_motor"
);

// Las 6 pruebas del motor que escribió Daniel (adaptive-engine/tests), tal como él las ejecuta.
run(
  "Pruebas del motor del equipo — adaptive-engine/tests (Daniel)",
  config.python,
  ["-m", "pytest", "tests", "-v", "-p", "no:cacheprovider", "--color=no", `--junitxml=${path.join(JUNIT_DIR, "motor_daniel.xml")}`],
  "02b_pruebas_motor_daniel",
  ENGINE_DIR
);

run(
  "Pruebas de integración — API, motor CLI y SQL",
  process.execPath,
  nodeSuite("integration", "integration.xml", ["--test-concurrency=1"]),
  "03_integracion"
);

if (!args.has("--sin-e2e")) {
  run("Pruebas funcionales E2E — navegador", process.execPath, nodeSuite("functional", "e2e.xml"), "04_e2e");
}

const resumen = generarReporte({ inicio, fin: new Date(), omitidas: args.has("--sin-e2e") ? ["Funcional (E2E)"] : [] });
console.log("\n━━━ RESUMEN ━━━");
console.log(`Casos: ${resumen.total} | Aprobados: ${resumen.APROBADO} | Fallidos: ${resumen.FALLIDO} | Bloqueados: ${resumen.BLOQUEADO}`);
console.log("Reporte: tests/reportes/REPORTE_DE_PRUEBAS.md · Matriz: tests/matriz/matriz_casos_prueba.csv");
// Código 1 si hay fallos, para poder usarlo en CI.
process.exitCode = resumen.FALLIDO > 0 ? 1 : 0;
