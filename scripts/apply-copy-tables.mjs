// scripts/apply-copy-tables.mjs
//
// Makes "Kopier" in "Før og etter referansedato" paste as real tables.
//
// What it does:
//   1. Creates src/lib/copyTables.(ts|js) with copyTsvAsTable(text).
//      It takes the tab-separated text the app already builds and puts BOTH
//      an HTML table (Word, Outlook, Gmail, Google Docs, Pages) and an
//      aligned plain-text table (Notepad, SMS, terminals) on the clipboard.
//   2. Finds the component(s) that copy the before/after section and swaps
//      navigator.clipboard.writeText(...) for copyTsvAsTable(...), adding the import.
//
// Usage (from the repo root):
//   node scripts/apply-copy-tables.mjs
//   node scripts/apply-copy-tables.mjs src/components/SomeFile.tsx   # patch a specific file

import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const SRC = path.join(ROOT, "src");
if (!fs.existsSync(SRC)) {
  console.error("✖ Run this from the repo root (no src/ folder found).");
  process.exit(1);
}

const isTs = fs.existsSync(path.join(ROOT, "tsconfig.json"));
const helperPath = path.join(SRC, "lib", isTs ? "copyTables.ts" : "copyTables.js");

// ---------------------------------------------------------------- helper file
const T = (ts) => (isTs ? ts : "");
const helper = `// src/lib/copyTables.${isTs ? "ts" : "js"}
// Turns tab-separated text into tables on the clipboard.
// - Lines with tabs are table rows; the first row of each block is the header.
// - Lines without tabs are titles/paragraphs (the line right before a table is its title).

type Block = { kind: "text"; text: string } | { kind: "table"; rows: string[][] };

function parse(text${T(": string")})${T(": Block[]")} {
  const blocks${T(": Block[]")} = [];
  for (const raw of text.replace(/\\r\\n/g, "\\n").split("\\n")) {
    const line = raw.replace(/\\s+$/, (m) => (m.includes("\\t") ? m.replace(/[^\\t]/g, "") : ""));
    if (line.includes("\\t")) {
      const cells = line.split("\\t").map((c) => c.trim());
      const last = blocks[blocks.length - 1];
      if (last && last.kind === "table") last.rows.push(cells);
      else blocks.push({ kind: "table", rows: [cells] });
    } else if (line.trim()) {
      blocks.push({ kind: "text", text: line.trim() });
    } else {
      blocks.push({ kind: "text", text: "" });
    }
  }
  // Pad every row to the header width
  for (const b of blocks) {
    if (b.kind !== "table") continue;
    const w = Math.max(...b.rows.map((r) => r.length));
    b.rows = b.rows.map((r) => [...r, ...Array(w - r.length).fill("")]);
  }
  return blocks;
}

const esc = (s${T(": string")}) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function toHtml(blocks${T(": Block[]")})${T(": string")} {
  const th = 'style="border:1px solid #999;padding:4px 8px;background:#eef3fb;text-align:center;font-weight:600;white-space:nowrap"';
  const tdL = 'style="border:1px solid #999;padding:4px 8px;text-align:left;white-space:nowrap"';
  const tdR = 'style="border:1px solid #999;padding:4px 8px;text-align:right;white-space:nowrap"';
  const out${T(": string[]")} = [];
  blocks.forEach((b, i) => {
    if (b.kind === "text") {
      if (!b.text) return;
      const isTitle = blocks[i + 1]?.kind === "table";
      out.push(
        isTitle
          ? \`<p style="margin:14px 0 6px;font-weight:600">\${esc(b.text)}</p>\`
          : \`<p style="margin:8px 0;font-size:12px">\${esc(b.text)}</p>\`
      );
      return;
    }
    const [head, ...body] = b.rows;
    out.push(
      '<table style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:13px">' +
        "<thead><tr>" + head.map((h) => \`<th \${th}>\${esc(h)}</th>\`).join("") + "</tr></thead>" +
        "<tbody>" +
        body
          .map((r) => "<tr>" + r.map((c, j) => \`<td \${j === 0 ? tdL : tdR}>\${esc(c)}</td>\`).join("") + "</tr>")
          .join("") +
        "</tbody></table>"
    );
  });
  return \`<div style="font-family:Arial,sans-serif">\${out.join("\\n")}</div>\`;
}

function toPlain(blocks${T(": Block[]")})${T(": string")} {
  const out${T(": string[]")} = [];
  for (const b of blocks) {
    if (b.kind === "text") {
      out.push(b.text);
      continue;
    }
    const widths = b.rows[0].map((_, i) => Math.max(...b.rows.map((r) => r[i].length)));
    const line = (r${T(": string[]")}) =>
      "| " + r.map((c, i) => (i === 0 ? c.padEnd(widths[i]) : c.padStart(widths[i]))).join(" | ") + " |";
    const sep = "|" + widths.map((w) => "-".repeat(w + 2)).join("|") + "|";
    const [head, ...body] = b.rows;
    out.push(line(head), sep, ...body.map(line));
  }
  return out.join("\\n").replace(/\\n{3,}/g, "\\n\\n").trim();
}

export async function copyTsvAsTable(text${T(": string")})${T(": Promise<void>")} {
  const blocks = parse(text);
  const html = toHtml(blocks);
  const plain = toPlain(blocks);

  if (typeof ClipboardItem !== "undefined" && navigator.clipboard?.write) {
    try {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([html], { type: "text/html" }),
          "text/plain": new Blob([plain], { type: "text/plain" }),
        }),
      ]);
      return;
    } catch {
      /* fall through to plain text */
    }
  }
  await navigator.clipboard.writeText(plain);
}
`;

fs.mkdirSync(path.dirname(helperPath), { recursive: true });
fs.writeFileSync(helperPath, helper);
console.log(`✔ Wrote ${path.relative(ROOT, helperPath)}`);

// ------------------------------------------------------- find target files
const WRITE_RE = /navigator\.clipboard\??\.writeText\(/g;
const MARKERS = [
  /referansedato/i,
  /REFERENCE_DATE/,
  /BEFORE_AFTER/i,
  /beforeAfter/i,
  /BeforeAfter/,
  /DIARY_BEFORE/i,
  /CHANGE_BEFORE/i,
  /averageBefore/i,
];

function walk(dir, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === "node_modules" || e.name.startsWith(".")) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (/\.(tsx?|jsx?)$/.test(e.name) && p !== helperPath) acc.push(p);
  }
  return acc;
}

let targets = process.argv.slice(2).map((f) => path.resolve(ROOT, f));
if (targets.length === 0) {
  targets = walk(SRC).filter((f) => {
    const s = fs.readFileSync(f, "utf8");
    return /navigator\.clipboard\??\.writeText\(/.test(s) && MARKERS.some((m) => m.test(s));
  });
}

if (targets.length === 0) {
  console.log(
    "\n⚠ Could not find the before/after copy code automatically.\n" +
      "  Run again with the component path, e.g.\n" +
      "  node scripts/apply-copy-tables.mjs src/components/ReferenceComparison.tsx"
  );
  process.exit(0);
}

// ------------------------------------------------------------- patch files
for (const file of targets) {
  let src = fs.readFileSync(file, "utf8");
  const count = (src.match(WRITE_RE) || []).length;
  if (count === 0) {
    console.log(`– ${path.relative(ROOT, file)}: no clipboard.writeText call, skipped`);
    continue;
  }

  src = src.replace(WRITE_RE, "copyTsvAsTable(");

  if (!/import\s*\{[^}]*copyTsvAsTable[^}]*\}\s*from/.test(src)) {
    let rel = path
      .relative(path.dirname(file), helperPath)
      .replace(/\\/g, "/")
      .replace(/\.(ts|js)$/, "");
    if (!rel.startsWith(".")) rel = "./" + rel;
    const importLine = `import { copyTsvAsTable } from "${rel}";\n`;

    const imports = [...src.matchAll(/^import[\s\S]*?from\s+["'][^"']+["'];?[^\S\n]*\n/gm)];
    if (imports.length) {
      const last = imports[imports.length - 1];
      const at = last.index + last[0].length;
      src = src.slice(0, at) + importLine + src.slice(at);
    } else {
      const directive = src.match(/^\s*["']use client["'];?\s*\n/);
      const at = directive ? directive[0].length : 0;
      src = src.slice(0, at) + importLine + src.slice(at);
    }
  }

  fs.writeFileSync(file, src);
  console.log(`✔ Patched ${path.relative(ROOT, file)} (${count} copy call${count > 1 ? "s" : ""})`);
}

console.log("\nDone. Check the result with: git diff");

