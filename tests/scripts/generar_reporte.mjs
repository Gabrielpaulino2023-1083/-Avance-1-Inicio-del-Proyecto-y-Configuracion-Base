// Cruza la matriz (matriz/casos.json) con los resultados JUnit (reportes/junit/*.xml)
// y las incidencias (matriz/incidencias.json). Genera:
//   reportes/resultados.json         → datos crudos
//   reportes/REPORTE_DE_PRUEBAS.md   → reporte legible en GitHub
//   matriz/MATRIZ_DE_PRUEBAS.md      → matriz completa con el último estado
//   matriz/matriz_casos_prueba.csv   → matriz para Excel
//   INCIDENCIAS.md                   → listado de incidencias con su estado
//
// Uso independiente: npm run reporte   (usa los últimos JUnit generados)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { TESTS_DIR, REPORTS_DIR, SCREENSHOTS_DIR, LOGS_DIR, ensureDir } from "../config.mjs";

const MATRIZ_DIR = path.join(TESTS_DIR, "matriz");
const JUNIT_DIR = path.join(REPORTS_DIR, "junit");
const ESTADOS = ["APROBADO", "FALLIDO", "BLOQUEADO"];
const ICONO = { APROBADO: "✅", FALLIDO: "❌", BLOQUEADO: "⛔" };

const readJson = (f) => JSON.parse(fs.readFileSync(f, "utf8"));
const decodeOnce = (s = "") =>
  s.replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(+n))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16)))
    .replace(/&amp;/g, "&");
// El reporter JUnit de Node puede escapar dos veces (&amp;quot;): se decodifica dos veces.
const decode = (s = "") => decodeOnce(decodeOnce(s));
const md = (s = "") => String(s).replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
const anchor = (id) => id.toLowerCase();

function attr(attrs, name) {
  const m = attrs.match(new RegExp(`\\b${name}="([^"]*)"`));
  return m ? decode(m[1]) : "";
}

// Lee todos los <testcase> de los archivos JUnit (formato de Node y de pytest).
// Archivo de log de cada suite (evidencia textual de la ejecución).
const LOG_DE_SUITE = {
  "unit_node.xml": "evidencias/logs/01_unitarias_node.log",
  "unit_motor.xml": "evidencias/logs/02_unitarias_motor.log",
  "motor_daniel.xml": "evidencias/logs/02b_pruebas_motor_daniel.log",
  "integration.xml": "evidencias/logs/03_integracion.log",
  "e2e.xml": "evidencias/logs/04_e2e.log",
};

function leerJUnit(externas = {}) {
  const resultados = [];
  if (!fs.existsSync(JUNIT_DIR)) return resultados;
  for (const file of fs.readdirSync(JUNIT_DIR).filter((f) => f.endsWith(".xml"))) {
    const xml = fs.readFileSync(path.join(JUNIT_DIR, file), "utf8");
    for (const m of xml.matchAll(/<testcase\b([^>]*?)(?:\/>|>([\s\S]*?)<\/testcase>)/g)) {
      const [, attrs, body = ""] = m;
      const name = attr(attrs, "name");
      // Pruebas del equipo que no llevan el ID en el nombre (p. ej. las de Daniel):
      // se relacionan con su caso por el campo "prueba_externa" de casos.json.
      const externo = externas[name];
      const idMatch = externo ? externo.match(/CP-([A-Z]+)-(\d+)/) : name.match(/CP[-_]([A-Z]+)[-_](\d+)/);
      if (!idMatch) continue;
      const failure = body.match(/<(failure|error)\b([^>]*?)(?:\/>|>([\s\S]*?)<\/\1>)/);
      const skipped = body.match(/<skipped\b([^>]*?)(?:\/>|>([\s\S]*?)<\/skipped>)/);
      let status = "pass";
      let message = "";
      if (failure) {
        status = "fail";
        message = attr(failure[2], "message") || decode(failure[3] || "");
      } else if (skipped) {
        status = "skip";
        message = attr(skipped[1], "message") || decode(skipped[2] || "");
      }
      resultados.push({
        id: `CP-${idMatch[1]}-${idMatch[2]}`,
        prueba: name,
        archivo: file,
        log: LOG_DE_SUITE[file] ?? "",
        status,
        mensaje: message.replace(/^Skipped:\s*/, "").trim(),
        tiempo: Number(attr(attrs, "time") || 0),
      });
    }
  }
  return resultados;
}

function capturasDe(id) {
  if (!fs.existsSync(SCREENSHOTS_DIR)) return [];
  return fs.readdirSync(SCREENSHOTS_DIR).filter((f) => f.startsWith(`${id}_`) || f.startsWith(`${id}a_`) || f.startsWith(`${id}b_`) || f.startsWith(`${id}c_`) || f.startsWith(`${id}d_`)).sort();
}

function limpiar(msg) {
  return msg.replace(/\x1b\[[0-9;]*m/g, "").replace(/\s+/g, " ").trim().slice(0, 400);
}

export function generarReporte({ inicio = null, fin = new Date(), omitidas = [] } = {}) {
  const matriz = readJson(path.join(MATRIZ_DIR, "casos.json"));
  const { incidencias } = readJson(path.join(MATRIZ_DIR, "incidencias.json"));
  const externas = Object.fromEntries(
    matriz.casos.filter((c) => c.prueba_externa).map((c) => [c.prueba_externa, c.id]));
  const junit = leerJUnit(externas);

  // ---- estado de cada caso
  const casos = matriz.casos.map((c) => {
    const pruebas = junit.filter((r) => r.id === c.id);
    let estado;
    let motivo = "";
    const fallos = pruebas.filter((p) => p.status === "fail");
    const bloqueos = pruebas.filter((p) => p.status === "skip");
    if (pruebas.length === 0) {
      estado = "BLOQUEADO";
      motivo = omitidas.includes(c.tipo)
        ? "No ejecutado en esta corrida (suite omitida)."
        : "Sin resultado: la suite no pudo ejecutarse en este entorno. Revisar evidencias/logs/.";
    } else if (fallos.length) {
      estado = "FALLIDO";
      motivo = `${fallos.length} de ${pruebas.length} verificaciones fallaron. ${limpiar(fallos[0].mensaje)}`;
    } else if (bloqueos.length) {
      estado = "BLOQUEADO";
      motivo = limpiar(bloqueos[0].mensaje);
    } else {
      estado = "APROBADO";
      motivo = pruebas.length > 1 ? `${pruebas.length} verificaciones aprobadas.` : "";
    }
    const incs = incidencias.filter((i) => i.casos.includes(c.id)).map((i) => i.id);
    const capturas = capturasDe(c.id);
    const logs = [...new Set(pruebas.map((p) => p.log).filter(Boolean))];
    return {
      ...c,
      responsable: matriz.responsables[c.modulo] ?? "—",
      estado,
      motivo,
      incidencias: incs,
      capturas,
      evidencia: [...capturas.map((f) => `evidencias/capturas/${f}`), ...logs],
      pruebas: pruebas.map(({ prueba, status, mensaje, archivo }) => ({ prueba, status, mensaje: limpiar(mensaje), archivo })),
    };
  });

  const resumen = { total: casos.length, APROBADO: 0, FALLIDO: 0, BLOQUEADO: 0 };
  for (const c of casos) resumen[c.estado]++;
  const porModulo = {};
  for (const c of casos) {
    porModulo[c.modulo] ??= { APROBADO: 0, FALLIDO: 0, BLOQUEADO: 0, total: 0 };
    porModulo[c.modulo][c.estado]++;
    porModulo[c.modulo].total++;
  }

  const porRequisito = {};
  for (const c of casos) {
    porRequisito[c.requisito] ??= { APROBADO: 0, FALLIDO: 0, BLOQUEADO: 0, total: 0, casos: [] };
    porRequisito[c.requisito][c.estado]++;
    porRequisito[c.requisito].total++;
    porRequisito[c.requisito].casos.push(c.id);
  }

  // ---- seguimiento automático de incidencias (re-prueba de casos corregidos)
  const incEstado = incidencias.map((i) => {
    const relacionados = casos.filter((c) => i.casos.includes(c.id));
    const todosAprobados = relacionados.length > 0 && relacionados.every((c) => c.estado === "APROBADO");
    let verificacion = relacionados.map((c) => `${c.id}: ${c.estado}`).join(", ");
    if (todosAprobados && !/Verificada/.test(i.estado)) verificacion += " → las pruebas ya pasan: se puede marcar como Verificada.";
    if (!todosAprobados && /Verificada/.test(i.estado)) verificacion += " → ATENCIÓN: marcada como Verificada pero sus pruebas no pasan (posible regresión).";
    return { ...i, verificacion, todosAprobados };
  });

  const fecha = fin.toLocaleString("es-DO", { dateStyle: "long", timeStyle: "short" });
  const duracion = inicio ? `${((fin - inicio) / 1000).toFixed(0)} s` : "—";
  const totalPruebas = junit.length;
  const evid = (c) => (c.evidencia.length ? c.evidencia : ["—"]);

  // Resultado real legible: en los fallidos se usa lo "obtenido" de su incidencia.
  const real = (c) => {
    if (c.estado === "APROBADO") return `Coincide con el esperado.${c.motivo ? ` ${c.motivo}` : ""}`;
    const inc = incEstado.find((i) => c.incidencias.includes(i.id));
    if (c.estado === "FALLIDO" && inc) return `${inc.obtenido} (ver ${inc.id})`;
    return c.motivo;
  };
  ensureDir(REPORTS_DIR);
  fs.writeFileSync(
    path.join(REPORTS_DIR, "resultados.json"),
    JSON.stringify({ generado: fin.toISOString(), resumen, porModulo, porRequisito, totalPruebasAutomatizadas: totalPruebas, casos, incidencias: incEstado }, null, 2),
    "utf8"
  );

  // ---------------------------------------------------------------- REPORTE
  const pct = (n) => `${((n / resumen.total) * 100).toFixed(0)} %`;
  const L = [];
  L.push(`# Reporte de pruebas — ${matriz.proyecto}`, "");
  L.push(`**Fecha de ejecución:** ${fecha} · **Duración:** ${duracion} · **Casos:** ${resumen.total} · **Verificaciones automatizadas:** ${totalPruebas}`, "");
  L.push("> Archivo generado automáticamente con `npm test` (carpeta `tests/`). No editarlo a mano.", "");
  L.push("## Resumen", "");
  L.push("| Estado | Casos | % |", "|---|---:|---:|");
  for (const e of ESTADOS) L.push(`| ${ICONO[e]} ${e} | ${resumen[e]} | ${pct(resumen[e])} |`);
  L.push(`| **Total** | **${resumen.total}** | 100 % |`, "");
  L.push("**Criterio:** un caso es BLOQUEADO cuando no puede ejecutarse por falta de integración (endpoint o pantalla pendiente). No se cuenta como fallo.", "");

  L.push("## Trazabilidad por requisito", "");
  L.push("| Requisito | Descripción | ✅ | ❌ | ⛔ | Casos |", "|---|---|---:|---:|---:|---|");
  for (const [r, desc] of Object.entries(matriz.requisitos)) {
    const v = porRequisito[r];
    if (!v) { L.push(`| ${r} | ${md(desc)} | 0 | 0 | 0 | — |`); continue; }
    L.push(`| ${r} | ${md(desc)} | ${v.APROBADO} | ${v.FALLIDO} | ${v.BLOQUEADO} | ${v.casos.join(", ")} |`);
  }
  L.push("", "## Por módulo y responsable", "");
  L.push("| Módulo | Responsable | ✅ | ❌ | ⛔ | Total |", "|---|---|---:|---:|---:|---:|");
  for (const [m, v] of Object.entries(porModulo)) {
    L.push(`| ${m} | ${matriz.responsables[m] ?? "—"} | ${v.APROBADO} | ${v.FALLIDO} | ${v.BLOQUEADO} | ${v.total} |`);
  }

  L.push("", "## Re-pruebas de incidencias corregidas", "");
  const corregidas = incEstado.filter((i) => /Verificada|Resuelta/.test(i.estado));
  if (!corregidas.length) L.push("Ninguna incidencia corregida en esta versión.", "");
  else {
    L.push("| Incidencia | Título | Estado | Resultado de la re-prueba |", "|---|---|---|---|");
    for (const i of corregidas) L.push(`| ${i.id} | ${md(i.titulo)} | ${i.estado} | ${md(i.verificacion)} |`);
    L.push("");
  }

  L.push("## Casos fallidos", "");
  const fallidos = casos.filter((c) => c.estado === "FALLIDO");
  if (!fallidos.length) L.push("Ninguno.", "");
  else {
    L.push("| Caso | Requisito | Título | Incidencia | Responsable | Resultado real |", "|---|---|---|---|---|---|");
    for (const c of fallidos) L.push(`| [${c.id}](#${anchor(c.id)}) | ${c.requisito} | ${md(c.titulo)} | ${c.incidencias.join(", ") || "—"} | ${md(c.responsable)} | ${md(real(c))} |`);
    L.push("");
  }
  L.push("## Casos bloqueados", "");
  const bloqueados = casos.filter((c) => c.estado === "BLOQUEADO");
  if (!bloqueados.length) L.push("Ninguno.", "");
  else {
    L.push("| Caso | Título | Motivo del bloqueo | Incidencia |", "|---|---|---|---|");
    for (const c of bloqueados) L.push(`| [${c.id}](#${anchor(c.id)}) | ${md(c.titulo)} | ${md(c.motivo)} | ${c.incidencias.join(", ") || "—"} |`);
    L.push("");
  }
  L.push("## Incidencias", "");
  L.push("Detalle completo con pasos de reproducción en [`tests/INCIDENCIAS.md`](../INCIDENCIAS.md).", "");
  L.push("| ID | Título | Tipo | Severidad | Responsable | Estado |", "|---|---|---|---|---|---|");
  for (const i of incEstado) L.push(`| ${i.id} | ${md(i.titulo)} | ${i.tipo} | ${i.severidad} | ${md(i.responsable)} | ${i.estado} |`);
  L.push("", "## Detalle de todos los casos", "");
  for (const c of casos) {
    L.push(`### ${c.id}`, "");
    L.push(`**${ICONO[c.estado]} ${c.estado}** — ${c.titulo}`, "");
    L.push(`- **Requisito:** ${c.requisito} — ${matriz.requisitos[c.requisito] ?? ""}`);
    L.push(`- **Módulo / área:** ${c.modulo} · ${c.area} · ${c.tipo} · prioridad ${c.prioridad}`);
    L.push(`- **Responsable:** ${c.responsable}`);
    L.push(`- **Pasos:** ${c.pasos}`);
    L.push(`- **Datos:** ${c.datos}`);
    L.push(`- **Resultado esperado:** ${c.esperado}`);
    L.push(`- **Resultado real:** ${real(c)}`);
    if (c.estado === "FALLIDO") L.push(`- **Detalle técnico:** ${c.motivo}`);
    if (c.incidencias.length) L.push(`- **Incidencias:** ${c.incidencias.join(", ")}`);
    L.push(`- **Evidencia:** ${evid(c).map((e) => (e === "—" ? e : `[${path.basename(e)}](../${e})`)).join(" · ")}`);
    if (c.pruebas.length > 1) {
      L.push(`- **Verificaciones (${c.pruebas.length}):**`);
      for (const p of c.pruebas) L.push(`  - ${p.status === "pass" ? "✅" : p.status === "fail" ? "❌" : "⛔"} \`${p.prueba}\``);
    }
    L.push("");
  }
  fs.writeFileSync(path.join(REPORTS_DIR, "REPORTE_DE_PRUEBAS.md"), L.join("\n"), "utf8");

  // ---------------------------------------------------------------- MATRIZ MD + CSV

  const M = [];
  M.push(`# Matriz de casos de prueba — ${matriz.proyecto}`, "");
  M.push(`Versión ${matriz.version_matriz}. Fuente editable: \`tests/matriz/casos.json\`. Último estado: ${fecha}.`, "");
  M.push("Estados: " + Object.entries(matriz.estados).map(([k, v]) => `**${k}** — ${v}`).join(" "), "");
  M.push("Requisitos: " + Object.entries(matriz.requisitos).map(([k, v]) => `**${k}** ${v}`).join(" · "), "");
  M.push("| ID | Requisito | Caso | Pasos | Datos | Resultado esperado | Resultado real | Estado | Evidencia | Responsable |");
  M.push("|---|---|---|---|---|---|---|---|---|---|");
  for (const c of casos) {
    M.push(`| ${c.id} | ${c.requisito} | ${md(c.titulo)} | ${md(c.pasos)} | ${md(c.datos)} | ${md(c.esperado)} | ${md(real(c))} | ${ICONO[c.estado]} ${c.estado} | ${md(evid(c).map((e) => path.basename(e)).join(", "))} | ${md(c.responsable)} |`);
  }
  fs.writeFileSync(path.join(MATRIZ_DIR, "MATRIZ_DE_PRUEBAS.md"), M.join("\n") + "\n", "utf8");

  const csvCell = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
  const header = ["ID", "Requisito", "Caso", "Pasos", "Datos", "Resultado esperado", "Resultado real", "Estado", "Evidencia",
    "Módulo", "Área", "Tipo", "Prioridad", "Responsable", "Incidencias"];
  const rows = casos.map((c) => [c.id, `${c.requisito} ${matriz.requisitos[c.requisito] ?? ""}`.trim(), c.titulo, c.pasos, c.datos,
    c.esperado, real(c), c.estado, evid(c).join(" "), c.modulo, c.area, c.tipo, c.prioridad, c.responsable, c.incidencias.join(" ")]);
  // BOM + ';' para que Excel en español lo abra con acentos y columnas correctas.
  fs.writeFileSync(
    path.join(MATRIZ_DIR, "matriz_casos_prueba.csv"),
    "﻿" + [header, ...rows].map((r) => r.map(csvCell).join(";")).join("\r\n"),
    "utf8"
  );

  // ---------------------------------------------------------------- INCIDENCIAS.md
  const I = [];
  I.push(`# Listado de incidencias — ${matriz.proyecto}`, "");
  I.push(`Generado el ${fecha} a partir de \`tests/matriz/incidencias.json\`. Para cambiar el estado de una incidencia, editar ese JSON y volver a ejecutar \`npm test\`: la columna "Última verificación" se actualiza sola con el resultado de la re-prueba.`, "");
  I.push("| ID | Título | Tipo | Severidad | Responsable | Estado | Casos |", "|---|---|---|---|---|---|---|");
  for (const i of incEstado) I.push(`| [${i.id}](#${anchor(i.id)}) | ${md(i.titulo)} | ${i.tipo} | ${i.severidad} | ${md(i.responsable)} | ${i.estado} | ${i.casos.join(", ")} |`);
  I.push("", "**Tipos:** *Defecto* = el código hace algo distinto de lo esperado. *Integración pendiente* = falta una pieza; sus casos quedan BLOQUEADOS, no fallidos.", "");
  I.push("**Estados:** Abierta → En progreso → Resuelta (pendiente de verificar) → Verificada (QA repitió el caso y pasó). *Pendiente de desarrollo* = integración aún no construida.", "");
  for (const i of incEstado) {
    I.push(`## ${i.id}`, "", `### ${i.titulo}`, "");
    I.push(`| Campo | Valor |`, `|---|---|`);
    I.push(`| Tipo | ${i.tipo} |`, `| Severidad | ${i.severidad} |`, `| Módulo | ${i.modulo} |`, `| Responsable | ${md(i.responsable)} |`);
    I.push(`| Estado de resolución | **${i.estado}** |`, `| Casos asociados | ${i.casos.join(", ")} |`, `| Última verificación | ${md(i.verificacion)} |`, "");
    if (i.historial) I.push(`**Historial.** ${i.historial}`, "");
    I.push(`**Descripción.** ${i.descripcion}`, "");
    I.push(`**Pasos para reproducir.** ${i.pasos}`, "");
    I.push(`**Resultado esperado.** ${i.esperado}`, "");
    I.push(`**Resultado obtenido.** ${i.obtenido}`, "");
    I.push(`**Evidencia.** ${i.evidencia.map((e) => `[${e}](${e})`).join(" · ")}`, "");
    I.push(`**Corrección sugerida.** ${i.sugerencia}`, "");
  }
  fs.writeFileSync(path.join(TESTS_DIR, "INCIDENCIAS.md"), I.join("\n"), "utf8");

  return resumen;
}

// Permite ejecutar este archivo directamente: node scripts/generar_reporte.mjs
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  ensureDir(LOGS_DIR);
  const r = generarReporte();
  console.log(`Casos: ${r.total} | Aprobados: ${r.APROBADO} | Fallidos: ${r.FALLIDO} | Bloqueados: ${r.BLOQUEADO}`);
}
