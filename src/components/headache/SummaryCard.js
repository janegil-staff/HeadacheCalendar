// src/components/headache/SummaryCard.js
"use client";

import { useEffect, useMemo, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, fill, indexRecords, intlLocale, monthStats } from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, MigraineIcon } from "@/components/headache/icons";
import LogModal from "@/components/headache/LogModal";

const MONTH_COUNT = 4; // current month + the three before it
const OPTIONS_KEY = "headache-summary-options";
const DEFAULT_OPTIONS = { textView: false, migraine: false, aura: false, cluster: false };

// Per-month numbers for the last MONTH_COUNT months, oldest first
function summaryRows(byDate) {
  const now = new Date();
  const rows = [];
  for (let i = MONTH_COUNT - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const s = monthStats(byDate, d.getFullYear(), d.getMonth());
    const [, mild, moderate, strong, extreme] = s.intensity;
    rows.push({
      year: d.getFullYear(),
      month: d.getMonth(),
      current: i === 0,
      headache: mild + moderate + strong + extreme,
      mild,
      moderate,
      strong,
      extreme,
      acute: s.acuteDays,
      migraine: s.migraine,
      aura: s.aura,
      cluster: s.cluster,
      registered: s.registered,
      // Same as the app's month intensity: strong and extreme both count 3
      sum: i === 0 ? null : mild + 2 * moderate + 3 * (strong + extreme),
    });
  }
  return rows;
}

// "Juli 2026" – or "Jul 26" when short (used in the table on phones)
function monthLabel(locale, year, month, short = false) {
  const loc = intlLocale(locale);
  const format = short ? { month: "short", year: "2-digit" } : { month: "long", year: "numeric" };
  const name = new Intl.DateTimeFormat(loc, format).format(new Date(year, month, 1));
  return name.charAt(0).toLocaleUpperCase(loc) + name.slice(1);
}

// Width of a string in a monospace font: CJK and full-width characters take two cells
const WIDE = /[ᄀ-ᅟ⺀-〾ぁ-㏿㐀-䶿一-鿿ꀀ-꓏가-힣豈-﫿︰-﹏＀-｠￠-￦]/u;
const textWidth = (s) => [...String(s)].reduce((n, ch) => n + (WIDE.test(ch) ? 2 : /\p{Mn}/u.test(ch) ? 0 : 1), 0);
const padEnd = (s, w) => s + " ".repeat(Math.max(0, w - textWidth(s)));
const padStart = (s, w) => " ".repeat(Math.max(0, w - textWidth(s))) + s;
const center = (s, w) => {
  const space = Math.max(0, w - textWidth(s));
  const left = Math.ceil(space / 2);
  return " ".repeat(left) + s + " ".repeat(space - left);
};
const escapeHtml = (s) =>
  String(s).replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]);

// Headings and rows of the text-view table: [month, value, value, …]
function tableData({ rows, columns, t, locale }) {
  return {
    head: [t.SUM_DAYS_WITH.replace(/[:：]\s*$/, ""), ...columns.map((c) => c.text)],
    body: rows.map((r) => [
      `${monthLabel(locale, r.year, r.month)}${r.current ? ` (${t.SUM_SO_FAR})` : ""}`,
      ...columns.map((c) => {
        const v = c.get(r);
        return v === null ? "-" : String(v);
      }),
    ]),
  };
}

// Plain text for pasting where tables aren't supported. Every value sits centred under its
// heading and the numbers in a column are right-aligned to each other (ones under ones):
//   Number of days with   | Headache | Mild | Moderate | … | Sum*
//   ----------------------+----------+------+----------+---+------
//   July 2026             |    13    |  1   |    6     | … |  31
function buildText({ intro, rows, columns, t, locale, footnote }) {
  const { head, body } = tableData({ rows, columns, t, locale });
  const widths = head.map((h, i) => Math.max(textWidth(h), ...body.map((row) => textWidth(row[i]))));
  const digits = head.map((_, i) => Math.max(...body.map((row) => textWidth(row[i]))));

  const cell = (value, i) => (i === 0 ? padEnd(value, widths[0]) : center(padStart(value, digits[i]), widths[i]));
  const line = (cells) => cells.map(cell).join(" | ").trimEnd();

  return [
    intro,
    "",
    line(head.map((h, i) => (i === 0 ? h : center(h, widths[i])))),
    widths.map((w) => "-".repeat(w)).join("-+-"),
    ...body.map(line),
    "",
    footnote,
  ].join("\n");
}

// The same table as HTML, so it pastes as a real table into the patient record, Word or email
function buildHtml({ intro, rows, columns, t, locale, footnote }) {
  const { head, body } = tableData({ rows, columns, t, locale });
  const td = "border:1px solid #cbd5e1;padding:3px 8px;";
  const cells = (row, tag) =>
    row
      .map((v, i) => `<${tag} style="${td}text-align:${i === 0 ? "left" : "center"};white-space:nowrap">${escapeHtml(v)}</${tag}>`)
      .join("");
  return [
    `<p>${escapeHtml(intro)}</p>`,
    `<table style="border-collapse:collapse;font-variant-numeric:tabular-nums">`,
    `<thead><tr>${cells(head, "th")}</tr></thead>`,
    `<tbody>${body.map((row) => `<tr>${cells(row, "td")}</tr>`).join("")}</tbody>`,
    `</table>`,
    `<p><i>${escapeHtml(footnote)}</i></p>`,
  ].join("");
}

// What the "text view" shows on screen: the intro, a plain bordered table and the footnote
function TextTable({ intro, rows, columns, t, locale, footnote }) {
  const { head, body } = tableData({ rows, columns, t, locale });
  return (
    <div className="text-xs text-slate-700 sm:text-[13px]">
      <p className="leading-relaxed">{intro}</p>
      <div className="mt-3 overflow-x-auto">
        <table className="w-full border-collapse tabular-nums">
          <thead>
            <tr>
              {head.map((h, i) => (
                <th
                  key={i}
                  className={`border border-slate-300 bg-slate-50 px-2 py-1 font-semibold ${i === 0 ? "text-start" : "text-center"}`}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {body.map((row, r) => (
              <tr key={r}>
                {row.map((v, i) => (
                  <td
                    key={i}
                    className={`whitespace-nowrap border border-slate-300 px-2 py-1 ${i === 0 ? "text-start" : "text-center"}`}
                  >
                    {v}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="mt-3 italic text-slate-500">{footnote}</p>
    </div>
  );
}

function Checkbox({ checked, onChange, children }) {
  return (
    <label className="flex cursor-pointer items-center gap-3 py-1.5 text-sm text-slate-700">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 cursor-pointer rounded border-slate-300 accent-[#6a9be0]"
      />
      {children}
    </label>
  );
}

// "Summary" in the right sidebar: the last four months per month, as a table or as copyable text
export default function SummaryCard({ patient }) {
  const { t, locale } = useHeadacheText();
  const [options, setOptions] = useState(DEFAULT_OPTIONS);
  const [copied, setCopied] = useState(false);
  const [logOpen, setLogOpen] = useState(false);

  // Remember the doctor's choices in this browser
  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem(OPTIONS_KEY));
      if (saved) setOptions({ ...DEFAULT_OPTIONS, ...saved });
    } catch {}
  }, []);
  const setOption = (key, value) => {
    setOptions((o) => {
      const next = { ...o, [key]: value };
      try {
        localStorage.setItem(OPTIONS_KEY, JSON.stringify(next));
      } catch {}
      return next;
    });
    setCopied(false);
  };

  const rows = useMemo(() => summaryRows(indexRecords(patient?.records)), [patient]);
  const total = (key) => rows.reduce((n, r) => n + r[key], 0);
  const hasData = rows.some((r) => r.registered > 0);

  const intro = hasData
    ? fill(t.SUM_INTRO, { months: MONTH_COUNT, days: total("headache"), migraine: total("migraine"), acute: total("acute") })
    : t.SUM_NONE;
  const footnote = `*${t.SUM_SUM} = (${t.CAL_MILD} × 1) + (${t.CAL_MODERATE} × 2) + (${t.CAL_STRONG}/${t.CAL_EXTREME} × 3)`;

  // Columns in order; the three last ones are optional
  const columns = [
    { id: "headache", text: t.SUM_HEADACHE, get: (r) => r.headache, strong: true },
    { id: "mild", text: t.CAL_MILD, get: (r) => r.mild, color: COLORS.mild, open: true },
    { id: "moderate", text: t.CAL_MODERATE, get: (r) => r.moderate, color: COLORS.moderate },
    { id: "strong", text: t.CAL_STRONG, get: (r) => r.strong, color: COLORS.strong },
    { id: "extreme", text: t.CAL_EXTREME, get: (r) => r.extreme, color: COLORS.extreme, close: true },
    { id: "acute", text: t.CAL_ACUTE_MEDICATION, get: (r) => r.acute, icon: <AcuteIcon size={16} /> },
    options.migraine && { id: "migraine", text: t.CAL_MIGRAINE, get: (r) => r.migraine, icon: <MigraineIcon size={16} /> },
    options.aura && { id: "aura", text: t.CAL_AURA, get: (r) => r.aura, icon: <AuraIcon size={16} /> },
    options.cluster && { id: "cluster", text: t.CAL_CLUSTER, get: (r) => r.cluster, icon: <ClusterIcon size={16} /> },
    { id: "sum", text: `${t.SUM_SUM}*`, get: (r) => r.sum, strong: true },
  ].filter(Boolean);

  const text = buildText({ intro, rows, columns, t, locale, footnote });

  const copy = async () => {
    try {
      const html = buildHtml({ intro, rows, columns, t, locale, footnote });
      try {
        await navigator.clipboard.write([
          new ClipboardItem({
            "text/plain": new Blob([text], { type: "text/plain" }),
            "text/html": new Blob([html], { type: "text/html" }),
          }),
        ]);
      } catch {
        await navigator.clipboard.writeText(text); // browsers without rich clipboard support
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  return (
    <section className="rounded-3xl border border-white/70 bg-white/65 p-4 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:px-6 sm:py-5">
      <h2 className="mb-4 text-center font-serif text-xl font-bold text-[#4f7cc0]">{t.SUM_TITLE}</h2>

      <div className="rounded-2xl border border-slate-200/80 bg-white p-3 shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)] sm:p-4">
        {options.textView ? (
          <>
            <TextTable intro={intro} rows={rows} columns={columns} t={t} locale={locale} footnote={footnote} />
            <div className="mt-3 flex justify-end">
              <button
                type="button"
                onClick={copy}
                className="rounded-full bg-[#6a9be0] px-4 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
              >
                {copied ? `✓ ${t.SUM_COPIED}` : t.SUM_COPY}
              </button>
            </div>
          </>
        ) : (
          <>
            <p className="text-sm leading-relaxed text-slate-700">{intro}</p>

            {hasData && (
              <>
                <div className="-mx-1 mt-4 overflow-x-auto">
                  <table className="w-full border-collapse text-xs tabular-nums sm:text-sm">
                    <thead>
                      <tr className="border-b border-slate-200 text-[10px] font-semibold uppercase tracking-wide text-slate-500 sm:text-[11px]">
                        <th className="px-0.5 pb-2 text-start font-semibold sm:px-1">{t.SUM_DAYS_WITH}</th>
                        {columns.map((c) => (
                          <th key={c.id} title={c.text} className="px-0.5 pb-2 text-center font-semibold sm:px-1">
                            {c.color ? (
                              <span className="mx-auto block h-3 w-3 rounded-sm" style={{ backgroundColor: c.color }} />
                            ) : c.icon ? (
                              <span className="flex justify-center">{c.icon}</span>
                            ) : (
                              c.text
                            )}
                            {(c.color || c.icon) && <span className="sr-only">{c.text}</span>}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {rows.map((r) => (
                        <tr key={`${r.year}-${r.month}`}>
                          <td className="px-0.5 py-2 text-start text-slate-700 sm:px-1">
                            <span className="block whitespace-nowrap sm:hidden">{monthLabel(locale, r.year, r.month, true)}</span>
                            <span className="hidden whitespace-nowrap sm:block">{monthLabel(locale, r.year, r.month)}</span>
                            {r.current && <span className="block text-[11px] text-slate-400">{t.SUM_SO_FAR}</span>}
                          </td>
                          {columns.map((c) => {
                            const v = c.get(r);
                            const alert = c.id === "acute" && v >= 10; // ≥10 days/month: risk of medication-overuse headache
                            return (
                              <td
                                key={c.id}
                                className={`px-0.5 py-2 text-center sm:px-1 ${
                                  alert
                                    ? "font-bold text-red-600"
                                    : v === null || v === 0
                                      ? "text-slate-300"
                                      : c.strong
                                        ? "font-bold text-slate-800"
                                        : "text-slate-700"
                                }`}
                              >
                                {v === null ? "–" : v}
                              </td>
                            );
                          })}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* What the colour squares and icons stand for */}
                <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5 text-xs text-slate-500">
                  {columns
                    .filter((c) => c.color || c.icon)
                    .map((c) => (
                      <li key={c.id} className="flex items-center gap-1.5">
                        {c.color ? <span className="h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: c.color }} /> : c.icon}
                        {c.text}
                      </li>
                    ))}
                </ul>
                <p className="mt-3 text-xs italic text-slate-500">{footnote}</p>
              </>
            )}
          </>
        )}
      </div>

      <div className="mt-4 border-t border-slate-200/80 pt-3">
        <Checkbox checked={options.textView} onChange={(v) => setOption("textView", v)}>
          {t.SUM_TEXT_VIEW}
        </Checkbox>
        <Checkbox checked={options.migraine} onChange={(v) => setOption("migraine", v)}>
          {t.SUM_SHOW_MIGRAINE}
        </Checkbox>
        <Checkbox checked={options.aura} onChange={(v) => setOption("aura", v)}>
          {t.SUM_SHOW_AURA}
        </Checkbox>
        <Checkbox checked={options.cluster} onChange={(v) => setOption("cluster", v)}>
          {t.SUM_SHOW_CLUSTER}
        </Checkbox>
      </div>
      {/* Opens the log in a modal – same look as the Medication / Previously used medication panels */}
      <button
        type="button"
        onClick={() => setLogOpen(true)}
        aria-haspopup="dialog"
        className="mt-4 flex w-full items-center gap-3 rounded-2xl border border-slate-200/80 bg-white px-4 py-3 text-start shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)] transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
      >
        <span className="flex-1 text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{t.LOG_SHOW}</span>
        <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-[#6a9be0] px-1.5 text-[11px] font-bold text-white">
          {patient?.records?.length ?? 0}
        </span>
        <svg className="h-3.5 w-3.5 text-[#6a9be0] rtl:-scale-x-100" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
          <path d="M8 5v14l9-7z" />
        </svg>
      </button>

      <LogModal open={logOpen} onClose={() => setLogOpen(false)} patient={patient} />
    </section>
  );
}
