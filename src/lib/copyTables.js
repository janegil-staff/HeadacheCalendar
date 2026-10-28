// src/lib/copyTables.js
// Turns tab-separated text into tables on the clipboard.
// - Lines with tabs are table rows; the first row of each block is the header.
// - Lines without tabs are titles/paragraphs (the line right before a table is its title).

type Block = { kind: "text"; text: string } | { kind: "table"; rows: string[][] };

function parse(text) {
  const blocks = [];
  for (const raw of text.replace(/\r\n/g, "\n").split("\n")) {
    const line = raw.replace(/\s+$/, (m) => (m.includes("\t") ? m.replace(/[^\t]/g, "") : ""));
    if (line.includes("\t")) {
      const cells = line.split("\t").map((c) => c.trim());
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

const esc = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function toHtml(blocks) {
  const th = 'style="border:1px solid #999;padding:4px 8px;background:#eef3fb;text-align:center;font-weight:600;white-space:nowrap"';
  const tdL = 'style="border:1px solid #999;padding:4px 8px;text-align:left;white-space:nowrap"';
  const tdR = 'style="border:1px solid #999;padding:4px 8px;text-align:right;white-space:nowrap"';
  const out = [];
  blocks.forEach((b, i) => {
    if (b.kind === "text") {
      if (!b.text) return;
      const isTitle = blocks[i + 1]?.kind === "table";
      out.push(
        isTitle
          ? `<p style="margin:14px 0 6px;font-weight:600">${esc(b.text)}</p>`
          : `<p style="margin:8px 0;font-size:12px">${esc(b.text)}</p>`
      );
      return;
    }
    const [head, ...body] = b.rows;
    out.push(
      '<table style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:13px">' +
        "<thead><tr>" + head.map((h) => `<th ${th}>${esc(h)}</th>`).join("") + "</tr></thead>" +
        "<tbody>" +
        body
          .map((r) => "<tr>" + r.map((c, j) => `<td ${j === 0 ? tdL : tdR}>${esc(c)}</td>`).join("") + "</tr>")
          .join("") +
        "</tbody></table>"
    );
  });
  return `<div style="font-family:Arial,sans-serif">${out.join("\n")}</div>`;
}

function toPlain(blocks) {
  const out = [];
  for (const b of blocks) {
    if (b.kind === "text") {
      out.push(b.text);
      continue;
    }
    const widths = b.rows[0].map((_, i) => Math.max(...b.rows.map((r) => r[i].length)));
    const line = (r) =>
      "| " + r.map((c, i) => (i === 0 ? c.padEnd(widths[i]) : c.padStart(widths[i]))).join(" | ") + " |";
    const sep = "|" + widths.map((w) => "-".repeat(w + 2)).join("|") + "|";
    const [head, ...body] = b.rows;
    out.push(line(head), sep, ...body.map(line));
  }
  return out.join("\n").replace(/\n{3,}/g, "\n\n").trim();
}

export async function copyTsvAsTable(text) {
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
