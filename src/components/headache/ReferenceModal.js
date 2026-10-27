// src/components/headache/ReferenceModal.js
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  REF_PERIOD_DAYS,
  fill,
  firstRecordMonth,
  indexRecords,
  intlLocale,
  referenceComparison,
  todayKey,
  toDateKey,
} from "@/components/headache/data";

const parseKey = (key) => {
  const [y, m, d] = String(key).split("-").map(Number);
  return y && m && d ? new Date(y, m - 1, d) : null;
};
const keyOf = (d) => toDateKey(d.getFullYear(), d.getMonth(), d.getDate());

// Default: 90 days ago, so all three periods after the date are complete
function defaultRefKey() {
  const now = new Date();
  return keyOf(new Date(now.getFullYear(), now.getMonth(), now.getDate() - REF_PERIOD_DAYS * 3));
}

const minus = (n) => (n < 0 ? `−${Math.abs(n)}` : String(n)); // real minus sign

function formatters(locale) {
  const loc = intlLocale(locale);
  const pct = new Intl.NumberFormat(loc, { style: "percent", maximumFractionDigits: 0, signDisplay: "exceptZero" });
  const avg = new Intl.NumberFormat(loc, { maximumFractionDigits: 1 });
  const date = new Intl.DateTimeFormat(loc, { day: "numeric", month: "short", year: "numeric" });
  const range = (a, b) => (date.formatRange ? date.formatRange(a, b) : `${date.format(a)} – ${date.format(b)}`);
  // Intl rounds half away from zero, like Excel (−62.5 % → −63 %)
  return { pct: (v) => pct.format(v), avg: (v) => avg.format(v), range };
}

// Builds the three tables as plain data, used both on screen and for copying
function buildTables(cmp, t, locale) {
  const f = formatters(locale);
  const columns = [
    { id: "mild", text: t.CAL_MILD, color: COLORS.mild },
    { id: "moderate", text: t.CAL_MODERATE, color: COLORS.moderate },
    { id: "strong", text: t.CAL_STRONG, color: COLORS.strong },
    { id: "extreme", text: t.CAL_EXTREME, color: COLORS.extreme },
    { id: "headache", text: t.REF_HEADACHE_DAYS, strong: true },
    { id: "modPlus", text: t.REF_MOD_PLUS, strong: true },
    { id: "acute", text: t.CAL_ACUTE_MEDICATION },
  ];

  const periodLabel = (r) => {
    const from = r.index < 0 ? r.index * REF_PERIOD_DAYS : (r.index - 1) * REF_PERIOD_DAYS;
    return fill(t.REF_DAYS, { from: minus(from), to: minus(from + REF_PERIOD_DAYS) });
  };

  const periodRows = (rows) =>
    rows.map((r) => {
      const empty = r.registered === 0 || !r.started;
      const partial = !empty && !r.finished;
      return {
        label: periodLabel(r),
        sub: f.range(r.from, r.end),
        note: partial ? t.SUM_SO_FAR : null,
        muted: empty || partial, // not counted in the averages
        cells: columns.map((c) => (empty ? "–" : String(r[c.id]))),
        registered: r.started ? `${r.registered}/${REF_PERIOD_DAYS}` : "–",
      };
    });

  const before = periodRows(cmp.before);
  if (cmp.baseline) {
    before.push({
      label: t.REF_BASELINE,
      summary: true,
      cells: columns.map((c) => f.avg(cmp.baseline[c.id])),
      registered: "",
    });
  }

  const change = cmp.change.map((c) => ({
    label: c.first === c.last ? fill(t.REF_MONTH, { n: c.last }) : fill(t.REF_MONTHS, { from: c.first, to: c.last }),
    cells: columns.map((col) => (c.values[col.id] === null ? "–" : f.pct(c.values[col.id]))),
    raw: columns.map((col) => c.values[col.id]),
  }));

  return { columns, before, after: periodRows(cmp.after), change };
}

const escapeHtml = (s) =>
  String(s).replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]);

// HTML (pastes as real tables into the patient record, Word or email) and tab-separated plain text
function buildCopy({ tables, t, refText }) {
  const sections = [
    { title: t.REF_BEFORE, rows: tables.before, withReg: true },
    { title: t.REF_AFTER, rows: tables.after, withReg: true },
    { title: t.REF_CHANGE, rows: tables.change, withReg: false },
  ];
  const head = (withReg) => [t.REF_PERIOD, ...tables.columns.map((c) => c.text), ...(withReg ? [t.REF_REGISTERED] : [])];
  const line = (r, withReg) => [
    r.note ? `${r.label} (${r.note})` : r.label,
    ...r.cells,
    ...(withReg ? [r.registered ?? ""] : []),
  ];

  const td = "border:1px solid #cbd5e1;padding:3px 8px;white-space:nowrap;";
  const cells = (row, tag, bold) =>
    row
      .map(
        (v, i) =>
          `<${tag} style="${td}text-align:${i === 0 ? "left" : "center"}${bold ? ";font-weight:bold" : ""}">${escapeHtml(v)}</${tag}>`
      )
      .join("");
  const html = [
    `<p><b>${escapeHtml(t.REF_DATE)}:</b> ${escapeHtml(refText)}</p>`,
    ...sections.map(
      (s) =>
        `<p><b>${escapeHtml(s.title)}</b></p><table style="border-collapse:collapse;font-variant-numeric:tabular-nums">` +
        `<thead><tr>${cells(head(s.withReg), "th")}</tr></thead>` +
        `<tbody>${s.rows.map((r) => `<tr>${cells(line(r, s.withReg), "td", r.summary)}</tr>`).join("")}</tbody></table>`
    ),
    `<p><i>${escapeHtml(t.REF_NOTE)}</i></p>`,
  ].join("");

  const text = [
    `${t.REF_DATE}: ${refText}`,
    ...sections.flatMap((s) => ["", s.title, head(s.withReg).join("\t"), ...s.rows.map((r) => line(r, s.withReg).join("\t"))]),
    "",
    t.REF_NOTE,
  ].join("\n");

  return { html, text };
}

function Table({ title, columns, rows, showRegistered, isChange, t }) {
  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white p-3 shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)] sm:p-4">
      <h3 className="mb-2 text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{title}</h3>
      <div className="-mx-1 overflow-x-auto">
        <table className="w-full border-collapse text-xs tabular-nums sm:text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-[10px] font-semibold uppercase tracking-wide text-slate-500 sm:text-[11px]">
              <th className="px-1.5 pb-2 text-start font-semibold">{t.REF_PERIOD}</th>
              {columns.map((c) => (
                <th key={c.id} className="px-1.5 pb-2 text-center align-bottom font-semibold">
                  {c.color && <span className="mx-auto mb-1 block h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: c.color }} />}
                  {c.text}
                </th>
              ))}
              {showRegistered && <th className="px-1.5 pb-2 text-center align-bottom font-semibold">{t.REF_REGISTERED}</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {rows.map((r, i) => (
              <tr key={i} className={r.summary ? "border-t-2 border-slate-200 bg-slate-50/80" : ""}>
                <td className={`px-1.5 py-2 text-start ${r.summary ? "font-semibold text-slate-800" : "text-slate-700"}`}>
                  <span className="block whitespace-nowrap">{r.label}</span>
                  {r.sub && <span className="block whitespace-nowrap text-[11px] text-slate-400">{r.sub}</span>}
                  {r.note && <span className="block text-[11px] text-slate-400">{r.note}</span>}
                </td>
                {r.cells.map((v, j) => {
                  const col = columns[j];
                  let cls = r.muted || v === "–" ? "text-slate-300" : col.strong || r.summary ? "font-bold text-slate-800" : "text-slate-700";
                  if (isChange && r.raw[j] !== null) {
                    // Fewer days with headache or medication is an improvement. More mild days can be
                    // either (attacks shifting down from moderate), so that column stays neutral.
                    const tone = col.id === "mild" || r.raw[j] === 0 ? "text-slate-600" : r.raw[j] < 0 ? "text-emerald-700" : "text-red-600";
                    cls = `font-semibold ${tone}`;
                  }
                  return (
                    <td key={j} className={`whitespace-nowrap px-1.5 py-2 text-center ${cls}`}>
                      {v}
                    </td>
                  );
                })}
                {showRegistered && (
                  <td className={`whitespace-nowrap px-1.5 py-2 text-center ${r.muted ? "text-slate-300" : "text-slate-500"}`}>
                    {r.registered}
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

// Before / after a reference date (e.g. the start of a treatment), in a modal over the dashboard
export default function ReferenceModal({ open, onClose, patient }) {
  const { t, locale, dir } = useHeadacheText();
  const [refKey, setRefKey] = useState(defaultRefKey);
  const [copied, setCopied] = useState(false);
  const closeRef = useRef(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  });

  // Lock page scroll while open, focus the close button, Esc closes
  useEffect(() => {
    if (!open) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e) => e.key === "Escape" && onCloseRef.current();
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = firstRecordMonth(patient?.records);
  const minKey = first ? toDateKey(first.year, first.month, 1) : undefined;
  const ref = parseKey(refKey);

  const tables = useMemo(
    () => (ref ? buildTables(referenceComparison(byDate, ref), t, locale) : null),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [byDate, refKey, t, locale]
  );

  if (!open) return null;

  const refText = ref ? new Intl.DateTimeFormat(intlLocale(locale), { dateStyle: "long" }).format(ref) : "";

  const copy = async () => {
    if (!tables) return;
    const { html, text } = buildCopy({ tables, t, refText });
    try {
      try {
        await navigator.clipboard.write([
          new ClipboardItem({
            "text/plain": new Blob([text], { type: "text/plain" }),
            "text/html": new Blob([html], { type: "text/html" }),
          }),
        ]);
      } catch {
        await navigator.clipboard.writeText(text);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  // Rendered on <body>: the summary card's backdrop blur would otherwise trap a fixed overlay inside the card
  return createPortal(
    <div
      dir={dir}
      lang={locale}
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-2 backdrop-blur-sm sm:p-6"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="ref-modal-title"
        className="flex h-full max-h-full w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-[#eef4fc] shadow-2xl"
      >
        <div className="flex items-center justify-between gap-3 border-b border-white/80 bg-white/80 px-4 py-3 sm:px-6">
          <h2 id="ref-modal-title" className="font-serif text-xl font-bold text-[#4f7cc0] sm:text-2xl">
            {t.REF_TITLE}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            aria-label={t.ABOUT_CLOSE}
            title={t.ABOUT_CLOSE}
            className="rounded-lg p-2 text-slate-600 transition hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>

        <div className="flex-1 space-y-4 overflow-y-auto overscroll-contain px-3 py-4 sm:px-6 sm:py-6">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <label className="block">
              <span className="block text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{t.REF_DATE}</span>
              <input
                type="date"
                value={refKey}
                min={minKey}
                max={todayKey()}
                onChange={(e) => {
                  setRefKey(e.target.value);
                  setCopied(false);
                }}
                className="mt-1 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-sm text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
              />
              <span className="mt-1 block text-xs text-slate-500">{t.REF_DATE_HELP}</span>
            </label>
            {tables && (
              <button
                type="button"
                onClick={copy}
                className="rounded-full bg-[#6a9be0] px-4 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
              >
                {copied ? `✓ ${t.SUM_COPIED}` : t.SUM_COPY}
              </button>
            )}
          </div>

          {tables && (
            <>
              <Table title={t.REF_BEFORE} columns={tables.columns} rows={tables.before} showRegistered t={t} />
              <Table title={t.REF_AFTER} columns={tables.columns} rows={tables.after} showRegistered t={t} />
              <Table title={t.REF_CHANGE} columns={tables.columns} rows={tables.change} isChange t={t} />
              <p className="text-xs italic leading-relaxed text-slate-500">{t.REF_NOTE}</p>
            </>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
}
