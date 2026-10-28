// scripts/apply-reference-copy-table.mjs
//
// "Før og etter referansedato" → Kopier: the plain-text copy becomes an aligned table
// (| Periode | Lett | … |) instead of tab-separated text. The HTML copy is unchanged.
//
// Usage (from the repo root): node scripts/apply-reference-copy-table.mjs

import fs from "node:fs";

const FILE = "src/components/headache/ReferenceModal.js";
let src = fs.readFileSync(FILE, "utf8");

if (src.includes("function textTable(")) {
  console.log("✔ Already applied, nothing to do.");
  process.exit(0);
}

const OLD = "    ...sections.flatMap((s) => [\"\", s.title, head(s.withReg).join(\"\\t\"), ...s.rows.map((r) => line(r, s.withReg).join(\"\\t\"))]),";
const NEW = "    ...sections.flatMap((s) => [\"\", s.title, ...textTable(head(s.withReg), s.rows.map((r) => line(r, s.withReg)))]),";
if (!src.includes(OLD)) {
  console.error("✖ Could not find the tab-separated copy line in " + FILE + ". Has the file changed?");
  process.exit(1);
}
src = src.replace(OLD, NEW);

const HELPERS = "// Width of a string in a monospace font: combining marks take no space, CJK/fullwidth take two\nconst textWidth = (s) =>\n  [...String(s)].reduce((w, ch) => {\n    if (/\\p{M}/u.test(ch)) return w;\n    const cp = ch.codePointAt(0);\n    const wide =\n      (cp >= 0x1100 && cp <= 0x115f) ||\n      (cp >= 0x2e80 && cp <= 0xa4cf) ||\n      (cp >= 0xac00 && cp <= 0xd7a3) ||\n      (cp >= 0xf900 && cp <= 0xfaff) ||\n      (cp >= 0xfe30 && cp <= 0xfe4f) ||\n      (cp >= 0xff00 && cp <= 0xff60) ||\n      (cp >= 0xffe0 && cp <= 0xffe6);\n    return w + (wide ? 2 : 1);\n  }, 0);\n\nconst pad = (s, width, alignLeft) => {\n  const space = \" \".repeat(Math.max(0, width - textWidth(s)));\n  return alignLeft ? s + space : space + s;\n};\n\n// Plain-text table with aligned columns, for places that don't accept HTML (journal systems, Notepad, SMS)\n//   | Periode         | Lett | Moderat | \u2026 |\n//   |-----------------|------|---------|---|\n//   | Dag \u221260 til \u221230 |    1 |       4 | \u2026 |\nfunction textTable(header, rows) {\n  const all = [header, ...rows].map((r) => r.map((v) => String(v ?? \"\")));\n  const widths = header.map((_, i) => Math.max(...all.map((r) => textWidth(r[i] ?? \"\"))));\n  const row = (r) => `| ${widths.map((w, i) => pad(r[i] ?? \"\", w, i === 0)).join(\" | \")} |`;\n  const rule = `|${widths.map((w) => \"-\".repeat(w + 2)).join(\"|\")}|`;\n  return [row(all[0]), rule, ...all.slice(1).map(row)];\n}\n";
const anchor = "function Table(";
if (!src.includes(anchor)) {
  console.error("✖ Could not find function Table( in " + FILE);
  process.exit(1);
}
src = src.replace(anchor, HELPERS + "\n" + anchor);

fs.writeFileSync(FILE, src);
console.log("✔ Patched " + FILE);
