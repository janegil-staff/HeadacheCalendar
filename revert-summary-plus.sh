#!/usr/bin/env bash
# revert-summary-plus.sh
# Undoes summary-plus.sh – back to the summary and log as they were before:
#  - SummaryCard.js and HeadacheLog.js restored to the earlier versions
#  - DayDetails.js shows duration in minutes again, durationLabel() removed from data.js
#  - the texts summary-plus.sh added are removed from texts.js
# Run from the project root:  bash revert-summary-plus.sh
set -euo pipefail

if [ ! -f src/components/headache/SummaryCard.js ]; then
  echo "✗ src/components/headache/SummaryCard.js not found – run this from the project root." >&2
  exit 1
fi

cat > src/components/headache/SummaryCard.js <<'FILE_END'
// src/components/headache/SummaryCard.js
"use client";

import { useEffect, useMemo, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, fill, indexRecords, intlLocale, monthStats } from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, MigraineIcon } from "@/components/headache/icons";

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

// Plain text with aligned columns, like the old summary – for pasting into the patient record
function buildText({ intro, rows, columns, t, locale, footnote }) {
  const label = (r) => `${monthLabel(locale, r.year, r.month)}${r.current ? ` (${t.SUM_SO_FAR})` : ""}:`;
  const labelWidth = Math.max(t.SUM_DAYS_WITH.length, ...rows.map((r) => label(r).length)) + 3;

  const cells = columns.map((c) => {
    const head = `${c.open ? "(" : ""}${c.text}${c.close ? ")" : ""}`;
    const values = rows.map((r) => {
      const v = c.get(r);
      return v === null ? "-" : String(v);
    });
    const width = Math.max(head.length, ...values.map((v) => v.length + (c.open || c.close ? 1 : 0)));
    const cell = (v) => {
      if (c.open) return `(${v.padStart(width - 1)}`;
      if (c.close) return `${v.padStart(width - 1)})`;
      return v.padStart(width);
    };
    return { head: head.padStart(width), cells: values.map(cell) };
  });

  const lines = [
    intro,
    "",
    t.SUM_DAYS_WITH.padEnd(labelWidth) + cells.map((c) => c.head).join("   "),
    ...rows.map((r, i) => label(r).padEnd(labelWidth) + cells.map((c) => c.cells[i]).join("   ")),
    "",
    footnote,
  ];
  return lines.join("\n");
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
      await navigator.clipboard.writeText(text);
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
            <pre className="overflow-x-auto whitespace-pre font-mono text-[10.5px] leading-relaxed text-slate-700 sm:text-[11.5px]">{text}</pre>
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
    </section>
  );
}
FILE_END
echo "✓ src/components/headache/SummaryCard.js"

if [ -f src/components/headache/HeadacheLog.js ]; then
cat > src/components/headache/HeadacheLog.js <<'FILE_END'
// src/components/headache/HeadacheLog.js
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  EFFECT_KEYS,
  INTENSITY,
  formatUnit,
  hasAcute,
  indexRecords,
  intensityOf,
  intlLocale,
  medicineName,
  recordsInLastDays,
  toDateKey,
} from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, FaceIcon, MigraineIcon, PeriodIcon } from "@/components/headache/icons";

const PAGE_SIZE = 60;
const TIMELINE_DAYS = 90;
const LEVEL_COLORS = [COLORS.none, COLORS.mild, COLORS.moderate, COLORS.strong, COLORS.extreme];
const EFFECT_STYLE = {
  1: "bg-red-50 text-red-700 ring-red-200",
  2: "bg-amber-50 text-amber-700 ring-amber-200",
  3: "bg-emerald-50 text-emerald-700 ring-emerald-200",
};

const parseDate = (key) => {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
};
const daysBetween = (a, b) => Math.round((b - a) / 86400000);

// "20 minutter", "4 timer", "4,5 timer"
function durationText(locale, minutes) {
  const m = Number(minutes) || 0;
  if (m <= 0) return null;
  if (m < 60) return formatUnit(locale, Math.round(m), "minute");
  return formatUnit(locale, Math.round((m / 60) * 2) / 2, "hour");
}

const acuteList = (patient, r) =>
  (r.acuteMedicines ?? []).map((id, i) => ({
    name: medicineName(patient, id),
    times: (r.acuteMedicinesUsedTimes ?? [])[i] ?? 1,
  }));
const preventiveList = (patient, r) =>
  (r.preventiveMedicines ?? []).map((m) => (typeof m === "number" ? medicineName(patient, m) : String(m)));

function Stat({ label, value, tone = "default" }) {
  const color = { default: "text-slate-800", good: "text-emerald-600", alert: "text-red-600", accent: "text-[#4f7cc0]" }[tone];
  return (
    <div className="min-w-0">
      <p className="truncate text-[10px] font-bold uppercase tracking-[0.12em] text-slate-500">{label}</p>
      <p className={`mt-0.5 truncate text-lg font-bold ${color}`}>{value}</p>
    </div>
  );
}

function Chip({ icon, children, className = "bg-slate-100 text-slate-700" }) {
  return (
    <span className={`inline-flex items-center gap-1 whitespace-nowrap rounded-full py-0.5 pe-2 ps-1 text-[11px] font-semibold ${className}`}>
      {icon}
      {children}
    </span>
  );
}

function ScoreBox({ value, label }) {
  return (
    <div className="flex min-w-[4.5rem] flex-col items-center justify-center rounded-xl border border-slate-200 bg-slate-50 px-3 py-2">
      <span className="flex h-7 items-center text-lg font-bold text-slate-800">{value}</span>
      <span className="mt-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500">{label}</span>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div className="min-w-0">
      <h4 className="mb-2 text-[10px] font-bold uppercase tracking-[0.12em] text-slate-500">{title}</h4>
      {children}
    </div>
  );
}

// One registration: a summary line that opens into the full details
function Entry({ patient, record: r, open, onToggle, t, locale, showNotes }) {
  const loc = intlLocale(locale);
  const level = intensityOf(r);
  const date = parseDate(r.date);
  const acute = acuteList(patient, r);
  const preventive = preventiveList(patient, r);
  const duration = durationText(locale, r.durationMinutes);
  const note = showNotes ? r.note?.trim() : "";
  const effectKey = acute.length ? EFFECT_KEYS[r.effect] : null;
  const panelId = `log-${r.date}`;

  const flags = [
    r.isMigraine && <Chip key="m" icon={<MigraineIcon size={14} />} className="bg-violet-50 text-violet-700">{t.CAL_MIGRAINE}</Chip>,
    r.hasAura && <Chip key="a" icon={<AuraIcon size={14} />} className="bg-amber-50 text-amber-700">{t.CAL_AURA}</Chip>,
    r.hasClusterHeadache && <Chip key="c" icon={<ClusterIcon size={14} />} className="bg-purple-50 text-purple-700">{t.CAL_CLUSTER}</Chip>,
    r.hasPeriod && <Chip key="p" icon={<PeriodIcon size={14} />} className="bg-pink-50 text-pink-700">{t.CAL_PERIOD}</Chip>,
  ].filter(Boolean);

  return (
    <li className={`overflow-hidden rounded-2xl border bg-white/90 shadow-sm transition ${open ? "border-[#9dbdf0]" : "border-slate-200/80"}`}>
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={open}
        aria-controls={panelId}
        className="flex w-full items-stretch gap-3 px-3 py-3 text-start hover:bg-blue-50/40 sm:px-4"
      >
        <span className="w-1 shrink-0 rounded-full" style={{ backgroundColor: LEVEL_COLORS[level] }} />

        <span className="min-w-0 flex-1">
          <span className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <span className="min-w-[6.5rem]">
              <span className="block text-sm font-bold text-[#4f7cc0]">
                {new Intl.DateTimeFormat(loc, { day: "numeric", month: "numeric", year: "numeric" }).format(date)}
              </span>
              <span className="block text-[11px] capitalize text-slate-400">
                {new Intl.DateTimeFormat(loc, { weekday: "long" }).format(date)}
              </span>
            </span>

            <span className="inline-flex items-center gap-1.5 text-sm font-semibold text-slate-700">
              <FaceIcon face={INTENSITY[level].face} size={20} />
              {t[INTENSITY[level].key]}
            </span>

            {level > 0 && (
              <span className="flex gap-4">
                <span>
                  <span className="block text-[10px] font-bold uppercase tracking-wide text-slate-400">{t.CAL_ATTACKS}</span>
                  <span className="block text-sm font-bold text-slate-700">{r.attacks ?? 0}</span>
                </span>
                {duration && (
                  <span>
                    <span className="block text-[10px] font-bold uppercase tracking-wide text-slate-400">{t.CAL_DURATION}</span>
                    <span className="block whitespace-nowrap text-sm font-bold text-slate-700">{duration}</span>
                  </span>
                )}
              </span>
            )}

            {(flags.length > 0 || acute.length > 0 || note) && (
              <span className="flex flex-wrap items-center gap-1.5">
                {flags}
                {acute.length > 0 && (
                  <Chip icon={<AcuteIcon size={14} />} className="bg-red-50 text-red-700">
                    {acute.length}
                  </Chip>
                )}
                {note && (
                  <span className="rounded-full bg-blue-50 px-1.5 py-0.5 text-[11px]" aria-label={t.CAL_NOTE}>
                    💬
                  </span>
                )}
              </span>
            )}
          </span>

          {note && !open && <span className="mt-2 block truncate text-xs italic text-slate-500">“{note}”</span>}
        </span>

        <svg
          className={`mt-1 h-4 w-4 shrink-0 text-slate-400 transition-transform ${open ? "rotate-180" : ""}`}
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M5.3 7.3a1 1 0 0 1 1.4 0L10 10.6l3.3-3.3a1 1 0 1 1 1.4 1.4l-4 4a1 1 0 0 1-1.4 0l-4-4a1 1 0 0 1 0-1.4z" />
        </svg>
      </button>

      {open && (
        <div id={panelId} className="border-t border-slate-100 bg-slate-50/50 px-4 py-4 sm:px-5">
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            <Section title={t.LOG_INTENSITY}>
              <div className="flex flex-wrap gap-2">
                <ScoreBox value={<FaceIcon face={INTENSITY[level].face} size={24} />} label={t[INTENSITY[level].key]} />
                {level > 0 && <ScoreBox value={r.attacks ?? 0} label={t.CAL_ATTACKS} />}
                {level > 0 && duration && <ScoreBox value={<span className="text-sm">{duration}</span>} label={t.CAL_DURATION} />}
              </div>
            </Section>

            <Section title={t.CAL_ACUTE_MEDICATION}>
              {acute.length ? (
                <>
                  <ul className="space-y-1">
                    {acute.map((m, i) => (
                      <li key={i} className="flex items-center gap-1.5 text-sm text-slate-700">
                        <AcuteIcon size={14} />
                        {m.name}
                        {m.times > 1 && <span className="text-slate-500">× {m.times}</span>}
                      </li>
                    ))}
                  </ul>
                  {effectKey && (
                    <span className={`mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ${EFFECT_STYLE[r.effect]}`}>
                      {t[effectKey]}
                    </span>
                  )}
                </>
              ) : (
                <p className="text-sm text-slate-400">{t.DASH_NONE}</p>
              )}
            </Section>

            <Section title={t.CAL_PREVENTIVE}>
              {preventive.length ? (
                <p className="text-sm text-slate-700">{preventive.join(", ")}</p>
              ) : (
                <p className="text-sm text-slate-400">{t.DASH_NONE}</p>
              )}
            </Section>
          </div>

          {flags.length > 0 && <div className="mt-4 flex flex-wrap gap-1.5">{flags}</div>}

          {note && (
            <div className="mt-4">
              <Section title={t.CAL_NOTE}>
                <p className="whitespace-pre-wrap rounded-xl border-s-4 border-[#6a9be0] bg-white px-3 py-2 text-sm italic text-slate-700">“{note}”</p>
              </Section>
            </div>
          )}

          {r.wasAddedLater && <p className="mt-3 text-xs text-slate-400">{t.CAL_REGISTERED_LATER}</p>}
        </div>
      )}
    </li>
  );
}

// The log page: key numbers, a 90-day timeline, search and every registration as a dropdown
export default function HeadacheLog({ patient }) {
  const { t, locale } = useHeadacheText();
  const loc = intlLocale(locale);
  const showNotes = !!patient?.shareNotes;

  const [query, setQuery] = useState("");
  const [openDates, setOpenDates] = useState(() => new Set());
  const [limit, setLimit] = useState(PAGE_SIZE);
  const [copied, setCopied] = useState(false);

  const records = useMemo(
    () => (patient?.records ?? []).filter((r) => r?.date).sort((a, b) => b.date.localeCompare(a.date)),
    [patient]
  );
  const byDate = useMemo(() => indexRecords(records), [records]);

  // ---- key numbers
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const lastHeadache = records.find((r) => intensityOf(r) > 0);
  const since = lastHeadache ? daysBetween(parseDate(lastHeadache.date), today) : null;
  const last30 = recordsInLastDays(byDate, 30);
  const headache30 = last30.filter((r) => intensityOf(r) > 0).length;
  const acute30 = last30.filter(hasAcute).length;

  // ---- timeline: the last 90 days, oldest first
  const timeline = Array.from({ length: TIMELINE_DAYS }, (_, i) => {
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - (TIMELINE_DAYS - 1 - i));
    const key = toDateKey(d.getFullYear(), d.getMonth(), d.getDate());
    return { key, date: d, record: byDate.get(key) };
  });

  const q = query.trim().toLowerCase();
  const matches = (r) => {
    if (!q) return true;
    const text = [
      ...acuteList(patient, r).map((m) => m.name),
      ...preventiveList(patient, r),
      showNotes ? r.note ?? "" : "",
    ]
      .join(" ")
      .toLowerCase();
    return text.includes(q);
  };
  const shown = records.filter(matches);
  const visible = shown.slice(0, limit);
  const hasMore = shown.length > limit;

  // Load the next entries automatically when the end of the list comes into view
  const endRef = useRef(null);
  useEffect(() => {
    const el = endRef.current;
    if (!el || !hasMore) return;
    const observer = new IntersectionObserver(
      (entries) => entries[0].isIntersecting && setLimit((n) => n + PAGE_SIZE),
      { rootMargin: "600px 0px" } // start a bit before the bottom is reached
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [hasMore, limit]);

  // Acute medication days per month (all registrations) – flags months at risk of medication overuse
  const acuteByMonth = useMemo(() => {
    const map = new Map();
    for (const r of records) if (hasAcute(r)) map.set(r.date.slice(0, 7), (map.get(r.date.slice(0, 7)) ?? 0) + 1);
    return map;
  }, [records]);

  const toggle = (date) =>
    setOpenDates((s) => {
      const next = new Set(s);
      next.has(date) ? next.delete(date) : next.add(date);
      return next;
    });

  // Tab-separated, so it pastes as a table into the patient record or a spreadsheet
  const copy = async () => {
    const dateFmt = new Intl.DateTimeFormat(loc, { day: "numeric", month: "numeric", year: "numeric" });
    const head = [
      t.LOG_DATE, t.LOG_INTENSITY, t.CAL_ATTACKS, t.CAL_DURATION, t.CAL_MIGRAINE, t.CAL_AURA, t.CAL_CLUSTER,
      t.CAL_MEDICATION, t.LOG_EFFECT, ...(showNotes ? [t.CAL_NOTE] : []),
    ];
    const lines = shown.map((r) => {
      const level = intensityOf(r);
      const acute = acuteList(patient, r);
      return [
        dateFmt.format(parseDate(r.date)),
        t[INTENSITY[level].key],
        level > 0 ? (r.attacks ?? 0) : "",
        level > 0 ? durationText(locale, r.durationMinutes) ?? "" : "",
        r.isMigraine ? t.CAL_MIGRAINE : "-",
        r.hasAura ? t.CAL_AURA : "-",
        r.hasClusterHeadache ? t.CAL_CLUSTER : "-",
        acute.map((m) => `${m.name}${m.times > 1 ? ` × ${m.times}` : ""}`).join(", ") || "-",
        acute.length && EFFECT_KEYS[r.effect] ? t[EFFECT_KEYS[r.effect]] : "-",
        ...(showNotes ? [(r.note?.trim() || "-").replace(/\s+/g, " ")] : []),
      ].join("\t");
    });
    try {
      await navigator.clipboard.writeText([head.join("\t"), ...lines].join("\n"));
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  // Entries with a month heading in front of each new month
  const list = [];
  let lastMonth = "";
  for (const r of visible) {
    const month = r.date.slice(0, 7);
    if (month !== lastMonth) {
      lastMonth = month;
      const acuteDays = acuteByMonth.get(month) ?? 0;
      list.push(
        <li key={month} className="flex flex-wrap items-center gap-2 px-1 pb-1 pt-4 first:pt-0">
          <h3 className="text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">
            {new Intl.DateTimeFormat(loc, { month: "long", year: "numeric" }).format(parseDate(`${month}-01`))}
          </h3>
          <span className="text-xs text-slate-400">· {shown.filter((x) => x.date.startsWith(month)).length}</span>
          {acuteDays >= 10 && (
            <span className="inline-flex items-center gap-1 rounded-full bg-amber-400 px-2.5 py-0.5 text-[11px] font-bold text-amber-950">
              ⚠ {t.LOG_OVERUSE} · {acuteDays}
            </span>
          )}
        </li>
      );
    }
    list.push(
      <Entry
        key={r.date}
        patient={patient}
        record={r}
        open={openDates.has(r.date)}
        onToggle={() => toggle(r.date)}
        t={t}
        locale={locale}
        showNotes={showNotes}
      />
    );
  }

  const card = "rounded-2xl border border-white/70 bg-white/70 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur";

  return (
    <div className="space-y-4">
      {/* Key numbers */}
      <section className={`${card} grid grid-cols-2 gap-4 px-4 py-4 sm:grid-cols-5 sm:px-5`}>
        <Stat
          label={t.LOG_STAT_SINCE}
          value={since === null ? "–" : since === 0 ? t.LOG_TODAY : formatUnit(locale, since, "day")}
          tone={since === null || since >= 7 ? "good" : "default"}
        />
        <Stat
          label={t.LOG_STAT_LAST}
          value={lastHeadache ? new Intl.DateTimeFormat(loc, { day: "numeric", month: "short" }).format(parseDate(lastHeadache.date)) : "–"}
          tone="accent"
        />
        <Stat label={t.LOG_STAT_HEADACHE_30} value={headache30} />
        <Stat label={t.LOG_STAT_ACUTE_30} value={acute30} tone={acute30 >= 10 ? "alert" : "default"} />
        <Stat label={t.LOG_STAT_TOTAL} value={records.length} />
      </section>

      {/* Timeline: one bar per day, coloured by intensity; a red dot under days with acute medication */}
      <section className={`${card} px-4 py-4 sm:px-5`}>
        <h2 className="text-[10px] font-bold uppercase tracking-[0.12em] text-slate-500">
          {t.LOG_TIMELINE} · {formatUnit(locale, TIMELINE_DAYS, "day")}
        </h2>
        <div className="mt-3 flex gap-px" dir="ltr">
          {timeline.map(({ key, date, record }) => {
            const level = record ? intensityOf(record) : null;
            const label = `${new Intl.DateTimeFormat(loc, { day: "numeric", month: "short" }).format(date)}: ${
              record ? t[INTENSITY[level].key] : t.CAL_NO_REGISTRATION
            }`;
            return (
              <span key={key} className="flex min-w-0 flex-1 flex-col items-center gap-0.5" title={label}>
                <span
                  className="h-7 w-full rounded-[2px]"
                  style={{ backgroundColor: record ? LEVEL_COLORS[level] : "#e2e8f0" }}
                />
                <span className={`h-1 w-1 rounded-full ${record && hasAcute(record) ? "bg-red-500" : "bg-transparent"}`} />
              </span>
            );
          })}
        </div>
        <ul className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-[11px] text-slate-500">
          {[0, 1, 2, 3, 4].map((level) => (
              <li key={level} className="flex items-center gap-1">
                <span className="h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: LEVEL_COLORS[level] }} />
                {t[INTENSITY[level].key]}
              </li>
            ))}
          <li className="flex items-center gap-1">
            <span className="h-2.5 w-2.5 rounded-sm bg-slate-200" />
            {t.CAL_NO_REGISTRATION}
          </li>
          <li className="flex items-center gap-1">
            <span className="h-1.5 w-1.5 rounded-full bg-red-500" />
            {t.CAL_ACUTE_MEDICATION}
          </li>
        </ul>
      </section>

      <div className="flex gap-2">
        <label className="relative flex-1">
          <span className="sr-only">{t.LOG_SEARCH}</span>
          <svg className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <circle cx="9" cy="9" r="6" />
            <path d="m14 14 4 4" strokeLinecap="round" />
          </svg>
          <input
            type="search"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setLimit(PAGE_SIZE);
            }}
            placeholder={t.LOG_SEARCH}
            className="w-full rounded-xl border border-slate-200 bg-white/90 py-2.5 pe-3 ps-9 text-sm text-slate-800 placeholder:text-slate-400 focus:border-[#9dbdf0] focus:outline-none focus:ring-2 focus:ring-blue-100"
          />
        </label>
        <button
          type="button"
          onClick={copy}
          disabled={!shown.length}
          className="shrink-0 whitespace-nowrap rounded-xl bg-[#6a9be0] px-4 text-xs font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3] disabled:opacity-40"
        >
          {copied ? `✓ ${t.SUM_COPIED}` : t.SUM_COPY}
        </button>
      </div>

      {/* Entries */}
      {shown.length ? (
        <ul className="space-y-2">{list}</ul>
      ) : (
        <p className={`${card} px-4 py-10 text-center text-sm text-slate-500`}>{records.length ? t.LOG_NO_MATCH : t.SUM_NONE}</p>
      )}

      {/* Invisible marker at the end of the list – more entries load as it scrolls into view */}
      {hasMore && (
        <div ref={endRef} className="flex justify-center py-4" aria-hidden="true">
          <span className="h-5 w-5 animate-spin rounded-full border-2 border-[#9dbdf0] border-t-transparent" />
        </div>
      )}
    </div>
  );
}
FILE_END
echo "✓ src/components/headache/HeadacheLog.js"
fi

node - <<'FILE_END'
import fs from "node:fs";

// DayDetails.js: back to minutes
const dayFile = "src/components/headache/DayDetails.js";
if (fs.existsSync(dayFile)) {
  let day = fs.readFileSync(dayFile, "utf8");
  day = day
    .replace(
      "            {durationLabel(t, locale, record) && <Line label={t.CAL_DURATION}>{durationLabel(t, locale, record)}</Line>}",
      `            {Number(record.durationMinutes) > 0 && (
              <Line label={t.CAL_DURATION}>{formatUnit(locale, record.durationMinutes, "minute")}</Line>
            )}`
    )
    .replace(", durationLabel } from \"@/components/headache/data\";", " } from \"@/components/headache/data\";");
  fs.writeFileSync(dayFile, day);
  console.log(`✓ ${dayFile}`);
}

// data.js: remove durationLabel()
const dataFile = "src/components/headache/data.js";
let data = fs.readFileSync(dataFile, "utf8");
const start = data.indexOf("\n// Duration as the app registers it:");
if (start >= 0) {
  const end = data.indexOf("\n}\n", data.indexOf("export function durationLabel(", start)) + 3;
  data = data.slice(0, start) + "\n" + data.slice(end);
  data = data.replace(/\n+$/, "\n\n"); // the original file ends with a blank line
  fs.writeFileSync(dataFile, data);
}
console.log(`✓ ${dataFile}`);

// texts.js: remove the added keys
const KEYS = ["SUM_REGISTERED", "SUM_LOW_REG", "SUM_HIT6_LABEL", "SUM_HIT6_NONE", "SUM_HIT6_B1", "SUM_HIT6_B2", "SUM_HIT6_B3", "SUM_HIT6_B4", "SUM_MEDS_TITLE", "SUM_MEDICINE", "SUM_DAYS_COL", "SUM_MAX_MONTH", "SUM_N_DAYS", "SUM_OVERUSE_LIMIT", "SUM_HOURS", "SUM_SHOW_HOURS", "SUM_SHOW_PERIOD", "SUM_PREVENTIVE_NONE", "LOG_DUR_SHORT", "LOG_DUR_SHORT_LONG"];
const textsFile = "src/components/headache/texts.js";
const src = fs.readFileSync(textsFile, "utf8");
const marker = "export const TEXTS = ";
const at = src.indexOf(marker);
const texts = JSON.parse(src.slice(at + marker.length).replace(/;\s*$/, ""));
for (const lang of Object.keys(texts)) for (const k of KEYS) delete texts[lang][k];
fs.writeFileSync(textsFile, src.slice(0, at) + marker + JSON.stringify(texts, null, 2) + ";\n");
console.log(`✓ ${textsFile}`);
FILE_END

echo "Done. Reload the dashboard."
