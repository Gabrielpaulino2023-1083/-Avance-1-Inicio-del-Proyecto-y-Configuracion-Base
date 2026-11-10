// Integración Node.js ↔ motor Python, tal como la describe adaptive-engine/INTEGRATION.md:
// Node ejecuta "python main.py --stdin", envía JSON por la entrada estándar y lee
// JSON de la salida estándar. Los errores deben salir como JSON por stderr con código ≠ 0.
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { ENGINE_DIR, config } from "../config.mjs";

function runEngine(args, input) {
  const r = spawnSync(config.python, ["main.py", ...args], {
    cwd: ENGINE_DIR,
    input,
    encoding: "utf8",
    env: { ...process.env, PYTHONIOENCODING: "utf-8" },
  });
  return { code: r.status, stdout: r.stdout ?? "", stderr: r.stderr ?? "", error: r.error };
}

// Comprueba que Python y pandas están disponibles; si no, los casos quedan BLOQUEADOS.
const probe = spawnSync(config.python, ["-c", "import pandas"], { encoding: "utf8" });
const BLOCKED = probe.status === 0
  ? false
  : `BLOQUEADO: no se pudo ejecutar "${config.python}" con pandas. Instala adaptive-engine/requirements.txt o ajusta PYTHON en tests/.env.test.`;

const studentJson = (overrides = {}) => JSON.stringify({
  student_id: 1,
  topic: "SQL JOIN",
  interactions: [{ study_minutes: 20, errors: 2, attempts: 2, repetitions: 1, navigation_count: 5, score_percentage: 75, ...overrides }],
});

// El error debe ser JSON {"error": "..."} y no un traceback de Python.
function assertJsonError(r) {
  assert.equal(r.code, 1, `código de salida esperado 1, recibido ${r.code}`);
  assert.equal(r.stdout.trim(), "", "no debe escribir en stdout");
  let parsed;
  assert.doesNotThrow(() => { parsed = JSON.parse(r.stderr); }, `stderr no es JSON:\n${r.stderr.slice(0, 300)}`);
  assert.equal(typeof parsed.error, "string");
  assert.ok(!r.stderr.includes("Traceback"), "no debe mostrar un traceback");
}

describe("Motor por línea de comandos", { skip: BLOCKED }, () => {
  for (const [label, overrides, action] of [
    ["bajo", { score_percentage: 45, errors: 6 }, "reinforce_topic"],
    ["medio", { score_percentage: 75, errors: 2 }, "maintain_difficulty"],
    ["alto", { score_percentage: 95, errors: 0, attempts: 1 }, "increase_difficulty"],
  ]) {
    test(`CP-MOT-09 --stdin escenario ${label} devuelve JSON legible por Node`, () => {
      const r = runEngine(["--stdin"], studentJson(overrides));
      assert.equal(r.code, 0, r.stderr);
      const out = JSON.parse(r.stdout);
      assert.equal(out.recommendation.action, action);
      assert.ok(out.recommendation.recommendation.includes("SQL JOIN"), "acentos y texto en UTF-8");
    });
  }

  test("CP-MOT-10 main.py en modo local se ejecuta sin errores críticos", () => {
    const r = runEngine([], undefined);
    assert.equal(r.code, 0, r.stderr);
    assert.match(r.stdout, /PERFIL DEL ESTUDIANTE/);
    assert.match(r.stdout, /RECOMENDACIÓN ADAPTATIVA/);
    assert.match(r.stdout, /reinforce_topic/);
  });

  test("CP-VAL-12 CLI con JSON mal formado", () => {
    assertJsonError(runEngine(["--stdin"], "{ esto no es json"));
  });

  test("CP-VAL-13 CLI con interacciones vacías", () => {
    const r = runEngine(["--stdin"], JSON.stringify({ student_id: 1, topic: "X", interactions: [] }));
    assertJsonError(r);
    assert.match(JSON.parse(r.stderr).error, /al menos una interacción/);
  });

  for (const raiz of ["[]", '"texto"', "5", "null"]) {
    test(`CP-VAL-14 CLI con raíz JSON que no es objeto: ${raiz}`, () => {
      assertJsonError(runEngine(["--stdin"], raiz));
    });
  }

  test("CP-VAL-15 CLI con Infinity en la entrada no rompe el JSON de salida", () => {
    const input = studentJson().replace('"study_minutes": 20', '"study_minutes": Infinity');
    assert.ok(input.includes("Infinity"));
    const r = runEngine(["--stdin"], input);
    if (r.code === 0) {
      assert.doesNotThrow(() => JSON.parse(r.stdout), `Node no puede leer la salida:\n${r.stdout.slice(0, 200)}`);
    } else {
      assertJsonError(r);
    }
  });
});
