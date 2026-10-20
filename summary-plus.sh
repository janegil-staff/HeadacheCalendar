#!/usr/bin/env bash
# summary-plus.sh
# Extends the summary with everything else in the patient data, in a new design:
#  - HIT-6: latest score with impact band (little / some / substantial / severe) on a 36–78 scale
#  - three tiles for the last 4 months: headache days, days with acute medication, hours with headache
#  - "Registered" per month (e.g. 22/31) with a small bar, and a warning when under half the days
#    are registered (the numbers may then be too low)
#  - preventive medication with dose (e.g. Metoprolol 75 mg)
#  - acute medication per medicine: days, most days in one month, effect – and a warning above the
#    limit for medication-overuse headache (triptans/opioids 10, simple analgesics 15 days/month)
#  - new optional columns: hours with headache, menstruation (women)
#  - the text view (for Pridok) includes all of it, wrapped to 60 characters
# Also fixes durations everywhere: short attacks (no minutes stored) now show "Short (under 3 h)",
# "Short and long · 4 h" when both, otherwise hours – in the log and in the day details.
# Needs summary-sidebar.sh (and log-page.sh for the log fix) to have been run first.
# Run from the project root:  bash summary-plus.sh
set -euo pipefail

if [ ! -f src/components/headache/SummaryCard.js ]; then
  echo "✗ src/components/headache/SummaryCard.js not found – run summary-sidebar.sh first." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------- SummaryCard.js
cat > src/components/headache/SummaryCard.js <<'FILE_END'
// src/components/headache/SummaryCard.js
"use client";

import { useEffect, useMemo, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, fill, hasAcute, intensityOf, intlLocale, latestHit6, toDateKey } from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, HoursIcon, MigraineIcon, PeriodIcon } from "@/components/headache/icons";

const MONTH_COUNT = 4; // current month + the three before it
const OPTIONS_KEY = "headache-summary-options";
const DEFAULT_OPTIONS = { textView: false, migraine: false, aura: false, cluster: false, hours: false, period: false };
const LOW_REGISTRATION = 0.5; // under half the days registered → numbers may be too low

// HIT-6: 36–78. Bands from the HIT-6 manual
const HIT6_MIN = 36;
const HIT6_MAX = 78;
const HIT6_BANDS = [
  { from: 36, to: 49, key: "SUM_HIT6_B1", color: "#34b27b", chip: "bg-emerald-50 text-emerald-700 ring-emerald-200" },
  { from: 50, to: 55, key: "SUM_HIT6_B2", color: "#f2c230", chip: "bg-amber-50 text-amber-700 ring-amber-200" },
  { from: 56, to: 59, key: "SUM_HIT6_B3", color: "#f08a3c", chip: "bg-orange-50 text-orange-700 ring-orange-200" },
  { from: 60, to: 78, key: "SUM_HIT6_B4", color: "#e5484d", chip: "bg-red-50 text-red-700 ring-red-200" },
];
const hit6Band = (score) => HIT6_BANDS.find((b) => score <= b.to) ?? HIT6_BANDS[3];

// "2026-07-21" (or a full timestamp) → local date, so it never shifts a day
const localDate = (value) => {
  const [y, m, d] = String(value).slice(0, 10).split("-").map(Number);
  return new Date(y, m - 1, d);
};

// Medication-overuse headache (ICHD-3): triptans, ergots and opioids from 10 days/month,
// simple analgesics (paracetamol, ASA, metamizole, NSAIDs) from 15 days/month
function overuseLimit(atc = "") {
  if (/^N02C|^N02A/i.test(atc)) return 10;
  if (/^N02BE|^N02BA|^N02BB|^M01A/i.test(atc)) return 15;
  return null;
}

const EFFECT_DOTS = [
  { effect: 3, key: "EFFECT_GOOD", color: "bg-emerald-500" },
  { effect: 2, key: "EFFECT_MODERATE", color: "bg-amber-400" },
  { effect: 1, key: "EFFECT_NONE", color: "bg-red-500" },
];

// Per-month numbers for the last MONTH_COUNT months, oldest first
function summaryRows(records) {
  const now = new Date();
  const rows = [];
  for (let i = MONTH_COUNT - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const prefix = toDateKey(d.getFullYear(), d.getMonth(), 1).slice(0, 7);
    const days = i === 0 ? now.getDate() : new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
    const inMonth = records.filter((r) => r.date?.startsWith(prefix));
    const headache = inMonth.filter((r) => intensityOf(r) > 0);
    const level = (n) => inMonth.filter((r) => intensityOf(r) === n).length;
    const [mild, moderate, strong, extreme] = [level(1), level(2), level(3), level(4)];
    rows.push({
      year: d.getFullYear(),
      month: d.getMonth(),
      prefix,
      current: i === 0,
      days,
      registered: inMonth.length,
      headache: headache.length,
      mild,
      moderate,
      strong,
      extreme,
      acute: inMonth.filter(hasAcute).length,
      migraine: inMonth.filter((r) => r.isMigraine).length,
      aura: inMonth.filter((r) => r.hasAura).length,
      cluster: inMonth.filter((r) => r.hasClusterHeadache).length,
      period: headache.filter((r) => r.hasPeriod).length,
      hours: Math.round((headache.reduce((n, r) => n + (Number(r.durationMinutes) || 0), 0) / 60) * 10) / 10,
      // Same as the app's month intensity: strong and extreme both count 3
      sum: i === 0 ? null : mild + 2 * moderate + 3 * (strong + extreme),
    });
  }
  return rows;
}

// Each acute medicine used in the period: days, most days in one month, effect on those days
function medicineRows(patient, records, prefixes) {
  const byId = new Map((patient?.medicines ?? []).map((m) => [m.id, m]));
  const meds = new Map();
  for (const r of records) {
    const month = r.date?.slice(0, 7);
    if (!prefixes.includes(month)) continue;
    (r.acuteMedicines ?? []).forEach((id, i) => {
      const info = byId.get(id);
      const key = info?.name ?? String(id);
      const atc = info?.atcCode ?? (r.acuteMedicinesAtc ?? [])[i] ?? "";
      const m = meds.get(key) ?? { name: key, atc, days: 0, perMonth: {}, effects: { 1: 0, 2: 0, 3: 0 } };
      m.days++;
      m.perMonth[month] = (m.perMonth[month] ?? 0) + 1;
      if (m.effects[r.effect] !== undefined) m.effects[r.effect]++;
      meds.set(key, m);
    });
  }
  return [...meds.values()]
    .map((m) => {
      const max = Math.max(...Object.values(m.perMonth));
      const limit = overuseLimit(m.atc);
      return { ...m, max, limit, over: limit !== null && max >= limit };
    })
    .sort((a, b) => b.days - a.days || a.name.localeCompare(b.name));
}

function monthLabel(locale, year, month, short = false) {
  const loc = intlLocale(locale);
  const format = short ? { month: "short", year: "2-digit" } : { month: "long", year: "numeric" };
  const name = new Intl.DateTimeFormat(loc, format).format(new Date(year, month, 1));
  return name.charAt(0).toLocaleUpperCase(loc) + name.slice(1);
}

// Wraps prose at about 60 characters, so the copied text reads well in the patient record
function wrap(text, width = 60, indent = "") {
  const lines = [];
  let line = "";
  for (const word of String(text).split(/\s+/).filter(Boolean)) {
    if (line && (line + " " + word).length > width) {
      lines.push(line);
      line = indent + word;
    } else {
      line = line ? `${line} ${word}` : word;
    }
  }
  if (line) lines.push(line);
  return lines.join("\n");
}

// Plain text with aligned columns, like the old summary – for pasting into the patient record
function buildText({ intro, lowNote, rows, columns, t, locale, footnote, extra }) {
  const label = (r) => `${monthLabel(locale, r.year, r.month)}${r.current ? ` (${t.SUM_SO_FAR})` : ""}:`;
  const labelWidth = Math.max(t.SUM_DAYS_WITH.length, ...rows.map((r) => label(r).length)) + 3;

  const cells = columns.map((c) => {
    const head = `${c.open ? "(" : ""}${c.text}${c.close ? ")" : ""}`;
    const values = rows.map((r) => {
      const v = c.text_ ? c.text_(r) : c.get(r);
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

  return [
    wrap(intro),
    ...(lowNote ? [wrap(lowNote)] : []),
    "",
    t.SUM_DAYS_WITH.padEnd(labelWidth) + cells.map((c) => c.head).join("   "),
    ...rows.map((r, i) => label(r).padEnd(labelWidth) + cells.map((c) => c.cells[i]).join("   ")),
    "",
    wrap(footnote),
    ...(extra.length ? ["", ...extra.map((line) => wrap(line, 60, "  "))] : []),
  ].join("\n");
}

function Checkbox({ checked, onChange, children }) {
  return (
    <label className="flex cursor-pointer items-center gap-3 py-1.5 text-sm text-slate-700">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 shrink-0 cursor-pointer rounded border-slate-300 accent-[#6a9be0]"
      />
      {children}
    </label>
  );
}

const panel = "rounded-2xl border border-slate-200/80 bg-white p-3 shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)] sm:p-4";
const heading = "text-[11px] font-bold uppercase tracking-[0.14em] text-[#4f7cc0]";

function Hit6Panel({ hit, t, locale }) {
  if (!hit) {
    return (
      <div className={`${panel} flex items-center justify-between gap-3`}>
        <h3 className={heading}>{t.SUM_HIT6_LABEL}</h3>
        <span className="text-sm text-slate-400">{t.SUM_HIT6_NONE}</span>
      </div>
    );
  }
  const band = hit6Band(hit.score);
  const pos = ((Math.min(Math.max(hit.score, HIT6_MIN), HIT6_MAX) - HIT6_MIN) / (HIT6_MAX - HIT6_MIN)) * 100;
  const date = hit.date
    ? new Intl.DateTimeFormat(intlLocale(locale), { day: "numeric", month: "numeric", year: "numeric" }).format(localDate(hit.date))
    : null;

  return (
    <div className={panel}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className={heading}>{t.SUM_HIT6_LABEL}</h3>
          {date && <p className="mt-0.5 text-xs text-slate-400">{date}</p>}
          <span className={`mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ${band.chip}`}>{t[band.key]}</span>
        </div>
        <span className="font-serif text-4xl font-bold leading-none tabular-nums" style={{ color: band.color }}>
          {hit.score}
        </span>
      </div>

      {/* Scale 36–78 with the four bands and a marker at the score */}
      <div className="relative mt-4" dir="ltr">
        <div className="flex h-2 overflow-hidden rounded-full">
          {HIT6_BANDS.map((b) => (
            <span
              key={b.key}
              className="h-full"
              style={{ backgroundColor: b.color, opacity: b === band ? 1 : 0.35, width: `${((b.to - b.from + 1) / (HIT6_MAX - HIT6_MIN + 1)) * 100}%` }}
            />
          ))}
        </div>
        <span
          className="absolute top-1/2 h-4 w-4 -translate-x-1/2 -translate-y-1/2 rounded-full border-[3px] border-white shadow"
          style={{ left: `${pos}%`, backgroundColor: band.color }}
        />
        <div className="mt-1.5 flex justify-between text-[10px] tabular-nums text-slate-400">
          {[36, 50, 56, 60, 78].map((n) => (
            <span key={n}>{n}</span>
          ))}
        </div>
      </div>
    </div>
  );
}

function Tile({ icon, label, value, tone = "default" }) {
  return (
    <div className={`${panel} flex flex-col items-center justify-center px-2 text-center sm:px-2`}>
      <span className="mb-1">{icon}</span>
      <span className={`text-2xl font-bold tabular-nums ${tone === "alert" ? "text-red-600" : "text-slate-800"}`}>{value}</span>
      <span className="mt-0.5 text-[10px] font-semibold uppercase leading-tight tracking-wide text-slate-500">{label}</span>
    </div>
  );
}

// "Summary" in the right sidebar
export default function SummaryCard({ patient }) {
  const { t, locale } = useHeadacheText();
  const loc = intlLocale(locale);
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

  const records = useMemo(() => (patient?.records ?? []).filter((r) => r?.date), [patient]);
  const rows = useMemo(() => summaryRows(records), [records]);
  const meds = useMemo(() => medicineRows(patient, records, rows.map((r) => r.prefix)), [patient, records, rows]);
  const hit = latestHit6(patient);
  const preventive = (patient?.preventiveMedicines ?? []).map((m) =>
    typeof m === "string" ? m : `${m.name}${m.dose ? ` ${m.dose} mg` : ""}`
  );

  const total = (key) => rows.reduce((n, r) => n + r[key], 0);
  const hasData = rows.some((r) => r.registered > 0);
  const numberFmt = new Intl.NumberFormat(loc, { maximumFractionDigits: 1 });
  const showPeriodOption = patient?.gender === "female" || rows.some((r) => r.period > 0);

  const lowMonths = rows.filter((r) => r.registered / r.days < LOW_REGISTRATION);
  const lowNote = hasData && lowMonths.length
    ? fill(t.SUM_LOW_REG, {
        months: lowMonths.map((r) => `${monthLabel(locale, r.year, r.month)}: ${r.registered}/${r.days}`).join(", "),
      })
    : "";

  const intro = hasData
    ? fill(t.SUM_INTRO, { months: MONTH_COUNT, days: total("headache"), migraine: total("migraine"), acute: total("acute") })
    : t.SUM_NONE;
  const footnote = `*${t.SUM_SUM} = (${t.CAL_MILD} × 1) + (${t.CAL_MODERATE} × 2) + (${t.CAL_STRONG}/${t.CAL_EXTREME} × 3)`;

  // Table columns in order; the optional ones follow the checkboxes
  const columns = [
    { id: "registered", text: t.SUM_REGISTERED, get: (r) => r.registered, text_: (r) => `${r.registered}/${r.days}`, inTable: false },
    { id: "headache", text: t.SUM_HEADACHE, get: (r) => r.headache, strong: true },
    { id: "mild", text: t.CAL_MILD, get: (r) => r.mild, color: COLORS.mild, open: true },
    { id: "moderate", text: t.CAL_MODERATE, get: (r) => r.moderate, color: COLORS.moderate },
    { id: "strong", text: t.CAL_STRONG, get: (r) => r.strong, color: COLORS.strong },
    { id: "extreme", text: t.CAL_EXTREME, get: (r) => r.extreme, color: COLORS.extreme, close: true },
    { id: "acute", text: t.CAL_ACUTE_MEDICATION, get: (r) => r.acute, icon: <AcuteIcon size={16} /> },
    options.migraine && { id: "migraine", text: t.CAL_MIGRAINE, get: (r) => r.migraine, icon: <MigraineIcon size={16} /> },
    options.aura && { id: "aura", text: t.CAL_AURA, get: (r) => r.aura, icon: <AuraIcon size={16} /> },
    options.cluster && { id: "cluster", text: t.CAL_CLUSTER, get: (r) => r.cluster, icon: <ClusterIcon size={16} /> },
    options.hours && { id: "hours", text: t.SUM_HOURS, get: (r) => r.hours, text_: (r) => numberFmt.format(r.hours), icon: <HoursIcon size={16} /> },
    options.period && showPeriodOption && { id: "period", text: t.CAL_PERIOD, get: (r) => r.period, icon: <PeriodIcon size={16} /> },
    { id: "sum", text: `${t.SUM_SUM}*`, get: (r) => r.sum, strong: true },
  ].filter(Boolean);
  const tableColumns = columns.filter((c) => c.inTable !== false);

  // Extra lines for the text version
  const dateFmt = new Intl.DateTimeFormat(loc, { day: "numeric", month: "numeric", year: "numeric" });
  const extra = [
    hit && `HIT-6: ${hit.score} – ${t[hit6Band(hit.score).key]}${hit.date ? ` (${dateFmt.format(localDate(hit.date))})` : ""}`,
    `${t.CAL_PREVENTIVE}: ${preventive.length ? preventive.join(", ") : t.SUM_PREVENTIVE_NONE}`,
    meds.length &&
      `${fill(t.SUM_MEDS_TITLE, { months: MONTH_COUNT })}: ${meds
        .map((m) => `${m.name} ${fill(t.SUM_N_DAYS, { n: m.days })} (${t.SUM_MAX_MONTH} ${m.max}${m.over ? " !" : ""})`)
        .join(", ")}`,
  ].filter(Boolean);

  const text = buildText({ intro, lowNote, rows, columns, t, locale, footnote, extra });

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  const maxDays = Math.max(1, ...meds.map((m) => m.days));

  return (
    <section className="rounded-3xl border border-white/70 bg-white/65 p-4 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:px-6 sm:py-5">
      <h2 className="mb-4 text-center font-serif text-xl font-bold text-[#4f7cc0]">{t.SUM_TITLE}</h2>

      {options.textView ? (
        <div className={panel}>
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
        </div>
      ) : (
        <div className="space-y-3">
          <Hit6Panel hit={hit} t={t} locale={locale} />

          {/* The last four months at a glance */}
          {hasData && (
            <div className="grid grid-cols-3 gap-2 sm:gap-3">
              <Tile icon={<span className="block h-3 w-3 rounded-full" style={{ backgroundColor: COLORS.moderate }} />} label={t.DASH_HEADACHE_DAYS} value={total("headache")} />
              <Tile icon={<AcuteIcon size={16} />} label={t.DASH_ACUTE_DAYS} value={total("acute")} />
              <Tile icon={<HoursIcon size={16} />} label={t.CAL_HOURS_WITH_HEADACHE} value={numberFmt.format(Math.round(total("hours")))} />
            </div>
          )}

          {/* Per month */}
          <div className={panel}>
            {!hasData && <p className="text-sm text-slate-500">{intro}</p>}
            {hasData && (
              <>
                <div className="-mx-1 overflow-x-auto">
                  <table className="w-full border-collapse text-xs tabular-nums sm:text-sm">
                    <thead>
                      <tr className="border-b border-slate-200 text-[10px] font-semibold uppercase tracking-wide text-slate-500 sm:text-[11px]">
                        <th className="px-0.5 pb-2 text-start font-semibold sm:px-1">{t.SUM_DAYS_WITH}</th>
                        {tableColumns.map((c) => (
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
                      {rows.map((r) => {
                        const share = r.days ? r.registered / r.days : 0;
                        const low = share < LOW_REGISTRATION;
                        return (
                          <tr key={r.prefix}>
                            <td className="px-0.5 py-2 text-start text-slate-700 sm:px-1">
                              <span className="block whitespace-nowrap" title={monthLabel(locale, r.year, r.month)}>
                                {monthLabel(locale, r.year, r.month, true)}
                              </span>
                              {/* How much of the month is registered */}
                              <span className="mt-1 flex items-center gap-1.5" title={`${t.SUM_REGISTERED}: ${r.registered}/${r.days}`}>
                                <span className="h-1 w-10 overflow-hidden rounded-full bg-slate-100 sm:w-14">
                                  <span
                                    className={`block h-full rounded-full ${low ? "bg-amber-400" : "bg-[#9dbdf0]"}`}
                                    style={{ width: `${Math.min(100, share * 100)}%` }}
                                  />
                                </span>
                                <span className={`text-[10px] ${low ? "font-semibold text-amber-600" : "text-slate-400"}`}>
                                  {r.registered}/{r.days}
                                </span>
                              </span>
                              {r.current && <span className="block text-[10px] text-slate-400">{t.SUM_SO_FAR}</span>}
                            </td>
                            {tableColumns.map((c) => {
                              const v = c.get(r);
                              const alert = c.id === "acute" && v >= 10; // ≥10 days/month: risk of medication-overuse headache
                              return (
                                <td
                                  key={c.id}
                                  className={`px-0.5 py-2 text-center align-top sm:px-1 ${
                                    alert
                                      ? "font-bold text-red-600"
                                      : v === null || v === 0
                                        ? "text-slate-300"
                                        : c.strong
                                          ? "font-bold text-slate-800"
                                          : "text-slate-700"
                                  }`}
                                >
                                  {v === null ? "–" : c.text_ ? c.text_(r) : v}
                                </td>
                              );
                            })}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {lowNote && (
                  <p className="mt-3 flex gap-2 rounded-xl bg-amber-50 px-3 py-2 text-xs leading-relaxed text-amber-800">
                    <span aria-hidden="true">⚠</span>
                    {lowNote}
                  </p>
                )}

                {/* What the colour squares and icons stand for */}
                <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5 text-xs text-slate-500">
                  {tableColumns
                    .filter((c) => c.color || c.icon)
                    .map((c) => (
                      <li key={c.id} className="flex items-center gap-1.5">
                        {c.color ? <span className="h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: c.color }} /> : c.icon}
                        {c.text}
                      </li>
                    ))}
                </ul>
                <p className="mt-2 text-xs italic text-slate-500">{footnote}</p>
              </>
            )}
          </div>

          {/* Medication: preventive now, and acute medicines used in the period */}
          <div className={panel}>
            <h3 className={heading}>{t.CAL_PREVENTIVE}</h3>
            <div className="mt-2 flex flex-wrap gap-1.5">
              {preventive.length ? (
                preventive.map((p) => (
                  <span key={p} className="rounded-full bg-[#eef4fd] px-3 py-1 text-xs font-semibold text-[#3f6db3] ring-1 ring-[#d6e4fa]">
                    {p}
                  </span>
                ))
              ) : (
                <span className="text-sm text-slate-400">{t.SUM_PREVENTIVE_NONE}</span>
              )}
            </div>

            <h3 className={`${heading} mt-5`}>{fill(t.SUM_MEDS_TITLE, { months: MONTH_COUNT })}</h3>
            {meds.length ? (
              <table className="mt-2 w-full border-collapse text-xs sm:text-sm">
                <thead>
                  <tr className="border-b border-slate-200 text-[10px] font-semibold uppercase tracking-wide text-slate-500 sm:text-[11px]">
                    <th className="pb-2 pe-2 text-start font-semibold">{t.SUM_MEDICINE}</th>
                    <th className="px-1 pb-2 text-end font-semibold">{t.SUM_DAYS_COL}</th>
                    <th className="px-1 pb-2 text-end font-semibold">{t.SUM_MAX_MONTH}</th>
                    <th className="ps-2 pb-2 text-end font-semibold">{t.LOG_EFFECT}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {meds.map((m) => (
                    <tr key={m.name} className="align-top">
                      <td className="py-2 pe-2">
                        <span className="flex items-center gap-1.5 font-medium text-slate-800">
                          <AcuteIcon size={14} />
                          {m.name}
                        </span>
                        <span className="mt-1 block h-1 overflow-hidden rounded-full bg-slate-100">
                          <span
                            className={`block h-full rounded-full ${m.over ? "bg-red-500" : "bg-[#9dbdf0]"}`}
                            style={{ width: `${(m.days / maxDays) * 100}%` }}
                          />
                        </span>
                        {m.over && (
                          <span className="mt-1 block text-[11px] font-semibold text-red-600">⚠ {fill(t.SUM_OVERUSE_LIMIT, { limit: m.limit })}</span>
                        )}
                      </td>
                      <td className="px-1 py-2 text-end font-bold tabular-nums text-slate-800">{m.days}</td>
                      <td className={`px-1 py-2 text-end tabular-nums ${m.over ? "font-bold text-red-600" : "text-slate-600"}`}>
                        {m.max}
                        {m.limit && <span className="font-normal text-slate-400">/{m.limit}</span>}
                      </td>
                      <td className="py-2 ps-2">
                        <span className="flex justify-end gap-2">
                          {EFFECT_DOTS.filter((e) => m.effects[e.effect] > 0).map((e) => (
                            <span key={e.effect} className="inline-flex items-center gap-1 tabular-nums text-slate-600" title={t[e.key]}>
                              <span className={`h-2 w-2 rounded-full ${e.color}`} />
                              {m.effects[e.effect]}
                              <span className="sr-only">{t[e.key]}</span>
                            </span>
                          ))}
                          {!EFFECT_DOTS.some((e) => m.effects[e.effect] > 0) && <span className="text-slate-300">–</span>}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="mt-2 text-sm text-slate-400">{t.DASH_NONE}</p>
            )}
            {meds.length > 0 && (
              <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-slate-500">
                {EFFECT_DOTS.map((e) => (
                  <li key={e.effect} className="flex items-center gap-1.5">
                    <span className={`h-2 w-2 rounded-full ${e.color}`} />
                    {t[e.key]}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      )}

      <div className="mt-4 grid border-t border-slate-200/80 pt-3 sm:grid-cols-2 sm:gap-x-4">
        <div className="sm:col-span-2">
          <Checkbox checked={options.textView} onChange={(v) => setOption("textView", v)}>
            {t.SUM_TEXT_VIEW}
          </Checkbox>
        </div>
        <Checkbox checked={options.migraine} onChange={(v) => setOption("migraine", v)}>
          {t.SUM_SHOW_MIGRAINE}
        </Checkbox>
        <Checkbox checked={options.aura} onChange={(v) => setOption("aura", v)}>
          {t.SUM_SHOW_AURA}
        </Checkbox>
        <Checkbox checked={options.cluster} onChange={(v) => setOption("cluster", v)}>
          {t.SUM_SHOW_CLUSTER}
        </Checkbox>
        <Checkbox checked={options.hours} onChange={(v) => setOption("hours", v)}>
          {t.SUM_SHOW_HOURS}
        </Checkbox>
        {showPeriodOption && (
          <Checkbox checked={options.period} onChange={(v) => setOption("period", v)}>
            {t.SUM_SHOW_PERIOD}
          </Checkbox>
        )}
      </div>
    </section>
  );
}
FILE_END
echo "✓ src/components/headache/SummaryCard.js"

# ---------------------------------------------------------------- HeadacheLog.js (if the log page exists)
if [ -f src/components/headache/HeadacheLog.js ]; then
cat > src/components/headache/HeadacheLog.js <<'FILE_END'
// src/components/headache/HeadacheLog.js
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  EFFECT_KEYS,
  durationLabel,
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
      <p className="text-[10px] font-bold uppercase leading-tight tracking-[0.12em] text-slate-500">{label}</p>
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
  const duration = durationLabel(t, locale, r);
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

            {/* Only when the day itself has preventive medication registered */}
            {preventive.length > 0 && (
              <Section title={t.CAL_PREVENTIVE}>
                <p className="text-sm text-slate-700">{preventive.join(", ")}</p>
              </Section>
            )}
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
        level > 0 ? durationLabel(t, locale, r) ?? "" : "",
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

# ---------------------------------------------------------------- shared duration helper
cat > "$TMP/durationLabel.js" <<'FILE_END'

// Duration as the app registers it: durationType 1 = short attacks (under 3 h, no time stored),
// 2 = long (hours in durationMinutes), 3 = both short and long attacks. Null when nothing is known.
export function durationLabel(t, locale, r) {
  const m = Number(r?.durationMinutes) || 0;
  const time =
    m <= 0 ? null : m < 60 ? formatUnit(locale, Math.round(m), "minute") : formatUnit(locale, Math.round((m / 60) * 2) / 2, "hour");
  if (r?.durationType === 1) return t.LOG_DUR_SHORT;
  if (r?.durationType === 3) return time ? `${t.LOG_DUR_SHORT_LONG} · ${time}` : t.LOG_DUR_SHORT_LONG;
  return time;
}
FILE_END

cat > "$TMP/texts.json" <<'FILE_END'
{
  "ar": {
    "SUM_REGISTERED": "مسجّل",
    "SUM_LOW_REG": "أيام مسجّلة قليلة ({months}) – قد تكون الأرقام أقل من الواقع.",
    "SUM_HIT6_LABEL": "تأثير الصداع (HIT-6)",
    "SUM_HIT6_NONE": "لم يُسجَّل HIT-6",
    "SUM_HIT6_B1": "تأثير ضئيل أو معدوم",
    "SUM_HIT6_B2": "بعض التأثير",
    "SUM_HIT6_B3": "تأثير كبير",
    "SUM_HIT6_B4": "تأثير شديد",
    "SUM_MEDS_TITLE": "دواء النوبة، آخر {months} أشهر",
    "SUM_MEDICINE": "الدواء",
    "SUM_DAYS_COL": "الأيام",
    "SUM_MAX_MONTH": "الحد الأقصى/شهر",
    "SUM_N_DAYS": "{n} يوم",
    "SUM_OVERUSE_LIMIT": "فوق حد صداع الإفراط في الأدوية ({limit} يومًا/شهر)",
    "SUM_HOURS": "ساعات",
    "SUM_SHOW_HOURS": "إظهار ساعات الصداع",
    "SUM_SHOW_PERIOD": "إظهار الحيض",
    "SUM_PREVENTIVE_NONE": "لا يوجد دواء وقائي",
    "LOG_DUR_SHORT": "قصيرة (أقل من 3 ساعات)",
    "LOG_DUR_SHORT_LONG": "قصيرة وطويلة"
  },
  "bg": {
    "SUM_REGISTERED": "Регистрирани",
    "SUM_LOW_REG": "Малко регистрирани дни ({months}) – стойностите може да са занижени.",
    "SUM_HIT6_LABEL": "Влияние на главоболието (HIT-6)",
    "SUM_HIT6_NONE": "Няма регистриран HIT-6",
    "SUM_HIT6_B1": "Малко или никакво влияние",
    "SUM_HIT6_B2": "Известно влияние",
    "SUM_HIT6_B3": "Значително влияние",
    "SUM_HIT6_B4": "Тежко влияние",
    "SUM_MEDS_TITLE": "Лекарства при пристъп, последните {months} месеца",
    "SUM_MEDICINE": "Лекарство",
    "SUM_DAYS_COL": "Дни",
    "SUM_MAX_MONTH": "Макс./месец",
    "SUM_N_DAYS": "{n} д.",
    "SUM_OVERUSE_LIMIT": "Над границата за главоболие от свръхупотреба на лекарства ({limit} дни/месец)",
    "SUM_HOURS": "Часове",
    "SUM_SHOW_HOURS": "Покажи часове с главоболие",
    "SUM_SHOW_PERIOD": "Покажи менструация",
    "SUM_PREVENTIVE_NONE": "Няма профилактично лечение",
    "LOG_DUR_SHORT": "Кратки (под 3 часа)",
    "LOG_DUR_SHORT_LONG": "Кратки и дълги"
  },
  "bs": {
    "SUM_REGISTERED": "Registrovano",
    "SUM_LOW_REG": "Malo registrovanih dana ({months}) – brojevi mogu biti preniski.",
    "SUM_HIT6_LABEL": "Utjecaj glavobolje (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 nije registrovan",
    "SUM_HIT6_B1": "Mali ili nikakav utjecaj",
    "SUM_HIT6_B2": "Određeni utjecaj",
    "SUM_HIT6_B3": "Značajan utjecaj",
    "SUM_HIT6_B4": "Težak utjecaj",
    "SUM_MEDS_TITLE": "Akutni lijekovi, posljednja {months} mjeseca",
    "SUM_MEDICINE": "Lijek",
    "SUM_DAYS_COL": "Dani",
    "SUM_MAX_MONTH": "Maks./mjesec",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Iznad granice za glavobolju zbog prekomjerne upotrebe lijekova ({limit} dana/mjesec)",
    "SUM_HOURS": "Sati",
    "SUM_SHOW_HOURS": "Prikaži sate s glavoboljom",
    "SUM_SHOW_PERIOD": "Prikaži menstruaciju",
    "SUM_PREVENTIVE_NONE": "Nema preventivnih lijekova",
    "LOG_DUR_SHORT": "Kratke (ispod 3 sata)",
    "LOG_DUR_SHORT_LONG": "Kratke i duge"
  },
  "ca": {
    "SUM_REGISTERED": "Registrats",
    "SUM_LOW_REG": "Pocs dies registrats ({months}): les xifres poden ser baixes.",
    "SUM_HIT6_LABEL": "Impacte del mal de cap (HIT-6)",
    "SUM_HIT6_NONE": "No hi ha cap HIT-6 registrat",
    "SUM_HIT6_B1": "Impacte escàs o nul",
    "SUM_HIT6_B2": "Cert impacte",
    "SUM_HIT6_B3": "Impacte considerable",
    "SUM_HIT6_B4": "Impacte greu",
    "SUM_MEDS_TITLE": "Medicació aguda, últims {months} mesos",
    "SUM_MEDICINE": "Medicament",
    "SUM_DAYS_COL": "Dies",
    "SUM_MAX_MONTH": "Màx./mes",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Per sobre del límit de cefalea per abús de medicació ({limit} dies/mes)",
    "SUM_HOURS": "Hores",
    "SUM_SHOW_HOURS": "Mostra les hores amb mal de cap",
    "SUM_SHOW_PERIOD": "Mostra la menstruació",
    "SUM_PREVENTIVE_NONE": "Sense medicació preventiva",
    "LOG_DUR_SHORT": "Curts (menys de 3 h)",
    "LOG_DUR_SHORT_LONG": "Curts i llargs"
  },
  "cs": {
    "SUM_REGISTERED": "Zaznamenáno",
    "SUM_LOW_REG": "Málo zaznamenaných dní ({months}) – čísla mohou být nižší.",
    "SUM_HIT6_LABEL": "Dopad bolesti hlavy (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 není zaznamenán",
    "SUM_HIT6_B1": "Malý nebo žádný dopad",
    "SUM_HIT6_B2": "Určitý dopad",
    "SUM_HIT6_B3": "Značný dopad",
    "SUM_HIT6_B4": "Závažný dopad",
    "SUM_MEDS_TITLE": "Akutní léky, poslední {months} měsíce",
    "SUM_MEDICINE": "Lék",
    "SUM_DAYS_COL": "Dny",
    "SUM_MAX_MONTH": "Max./měsíc",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Nad hranicí pro bolest hlavy z nadužívání léků ({limit} dní/měsíc)",
    "SUM_HOURS": "Hodiny",
    "SUM_SHOW_HOURS": "Zobrazit hodiny s bolestí hlavy",
    "SUM_SHOW_PERIOD": "Zobrazit menstruaci",
    "SUM_PREVENTIVE_NONE": "Bez preventivní léčby",
    "LOG_DUR_SHORT": "Krátké (pod 3 h)",
    "LOG_DUR_SHORT_LONG": "Krátké i dlouhé"
  },
  "da": {
    "SUM_REGISTERED": "Registreret",
    "SUM_LOW_REG": "Få registrerede dage ({months}) – tallene kan være for lave.",
    "SUM_HIT6_LABEL": "Hovedpinens påvirkning (HIT-6)",
    "SUM_HIT6_NONE": "Ingen HIT-6 registreret",
    "SUM_HIT6_B1": "Lille eller ingen påvirkning",
    "SUM_HIT6_B2": "Nogen påvirkning",
    "SUM_HIT6_B3": "Betydelig påvirkning",
    "SUM_HIT6_B4": "Svær påvirkning",
    "SUM_MEDS_TITLE": "Anfaldsmedicin, seneste {months} måneder",
    "SUM_MEDICINE": "Medicin",
    "SUM_DAYS_COL": "Dage",
    "SUM_MAX_MONTH": "Maks./md.",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Over grænsen for medicinoverforbrugshovedpine ({limit} dage/md.)",
    "SUM_HOURS": "Timer",
    "SUM_SHOW_HOURS": "Vis timer med hovedpine",
    "SUM_SHOW_PERIOD": "Vis menstruation",
    "SUM_PREVENTIVE_NONE": "Ingen forebyggende medicin",
    "LOG_DUR_SHORT": "Korte (under 3 timer)",
    "LOG_DUR_SHORT_LONG": "Korte og lange"
  },
  "de": {
    "SUM_REGISTERED": "Erfasst",
    "SUM_LOW_REG": "Wenige erfasste Tage ({months}) – die Zahlen können zu niedrig sein.",
    "SUM_HIT6_LABEL": "Kopfschmerz-Beeinträchtigung (HIT-6)",
    "SUM_HIT6_NONE": "Kein HIT-6 erfasst",
    "SUM_HIT6_B1": "Keine oder geringe Beeinträchtigung",
    "SUM_HIT6_B2": "Einige Beeinträchtigung",
    "SUM_HIT6_B3": "Deutliche Beeinträchtigung",
    "SUM_HIT6_B4": "Schwere Beeinträchtigung",
    "SUM_MEDS_TITLE": "Akutmedikation, letzte {months} Monate",
    "SUM_MEDICINE": "Medikament",
    "SUM_DAYS_COL": "Tage",
    "SUM_MAX_MONTH": "Max./Monat",
    "SUM_N_DAYS": "{n} T.",
    "SUM_OVERUSE_LIMIT": "Über der Grenze für Kopfschmerz durch Medikamentenübergebrauch ({limit} Tage/Monat)",
    "SUM_HOURS": "Stunden",
    "SUM_SHOW_HOURS": "Stunden mit Kopfschmerz anzeigen",
    "SUM_SHOW_PERIOD": "Menstruation anzeigen",
    "SUM_PREVENTIVE_NONE": "Keine Prophylaxe",
    "LOG_DUR_SHORT": "Kurz (unter 3 Std.)",
    "LOG_DUR_SHORT_LONG": "Kurz und lang"
  },
  "el": {
    "SUM_REGISTERED": "Καταγραφές",
    "SUM_LOW_REG": "Λίγες καταγεγραμμένες ημέρες ({months}) – οι αριθμοί μπορεί να είναι χαμηλότεροι.",
    "SUM_HIT6_LABEL": "Επίδραση πονοκεφάλου (HIT-6)",
    "SUM_HIT6_NONE": "Δεν έχει καταγραφεί HIT-6",
    "SUM_HIT6_B1": "Μικρή ή καμία επίδραση",
    "SUM_HIT6_B2": "Κάποια επίδραση",
    "SUM_HIT6_B3": "Σημαντική επίδραση",
    "SUM_HIT6_B4": "Σοβαρή επίδραση",
    "SUM_MEDS_TITLE": "Φάρμακα κρίσης, τελευταίοι {months} μήνες",
    "SUM_MEDICINE": "Φάρμακο",
    "SUM_DAYS_COL": "Ημέρες",
    "SUM_MAX_MONTH": "Μέγ./μήνα",
    "SUM_N_DAYS": "{n} ημ.",
    "SUM_OVERUSE_LIMIT": "Πάνω από το όριο για κεφαλαλγία από υπερκατανάλωση φαρμάκων ({limit} ημέρες/μήνα)",
    "SUM_HOURS": "Ώρες",
    "SUM_SHOW_HOURS": "Εμφάνιση ωρών με πονοκέφαλο",
    "SUM_SHOW_PERIOD": "Εμφάνιση εμμήνου ρύσεως",
    "SUM_PREVENTIVE_NONE": "Χωρίς προληπτική αγωγή",
    "LOG_DUR_SHORT": "Σύντομες (κάτω από 3 ώρες)",
    "LOG_DUR_SHORT_LONG": "Σύντομες και μακρές"
  },
  "en": {
    "SUM_REGISTERED": "Registered",
    "SUM_LOW_REG": "Few days registered ({months}) – the numbers may be too low.",
    "SUM_HIT6_LABEL": "Headache impact (HIT-6)",
    "SUM_HIT6_NONE": "No HIT-6 registered",
    "SUM_HIT6_B1": "Little or no impact",
    "SUM_HIT6_B2": "Some impact",
    "SUM_HIT6_B3": "Substantial impact",
    "SUM_HIT6_B4": "Severe impact",
    "SUM_MEDS_TITLE": "Acute medication, last {months} months",
    "SUM_MEDICINE": "Medicine",
    "SUM_DAYS_COL": "Days",
    "SUM_MAX_MONTH": "Max/month",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Above the limit for medication-overuse headache ({limit} days/month)",
    "SUM_HOURS": "Hours",
    "SUM_SHOW_HOURS": "Show hours with headache",
    "SUM_SHOW_PERIOD": "Show menstruation",
    "SUM_PREVENTIVE_NONE": "No preventive medication",
    "LOG_DUR_SHORT": "Short (under 3 h)",
    "LOG_DUR_SHORT_LONG": "Short and long"
  },
  "es": {
    "SUM_REGISTERED": "Registrados",
    "SUM_LOW_REG": "Pocos días registrados ({months}): las cifras pueden ser bajas.",
    "SUM_HIT6_LABEL": "Impacto de la cefalea (HIT-6)",
    "SUM_HIT6_NONE": "No hay HIT-6 registrado",
    "SUM_HIT6_B1": "Impacto escaso o nulo",
    "SUM_HIT6_B2": "Cierto impacto",
    "SUM_HIT6_B3": "Impacto considerable",
    "SUM_HIT6_B4": "Impacto grave",
    "SUM_MEDS_TITLE": "Medicación aguda, últimos {months} meses",
    "SUM_MEDICINE": "Medicamento",
    "SUM_DAYS_COL": "Días",
    "SUM_MAX_MONTH": "Máx./mes",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Por encima del límite de cefalea por uso excesivo de medicación ({limit} días/mes)",
    "SUM_HOURS": "Horas",
    "SUM_SHOW_HOURS": "Mostrar horas con cefalea",
    "SUM_SHOW_PERIOD": "Mostrar menstruación",
    "SUM_PREVENTIVE_NONE": "Sin medicación preventiva",
    "LOG_DUR_SHORT": "Cortos (menos de 3 h)",
    "LOG_DUR_SHORT_LONG": "Cortos y largos"
  },
  "et": {
    "SUM_REGISTERED": "Registreeritud",
    "SUM_LOW_REG": "Vähe registreeritud päevi ({months}) – numbrid võivad olla liiga madalad.",
    "SUM_HIT6_LABEL": "Peavalu mõju (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 pole registreeritud",
    "SUM_HIT6_B1": "Vähene või puuduv mõju",
    "SUM_HIT6_B2": "Mõningane mõju",
    "SUM_HIT6_B3": "Märkimisväärne mõju",
    "SUM_HIT6_B4": "Raske mõju",
    "SUM_MEDS_TITLE": "Hooravimid, viimased {months} kuud",
    "SUM_MEDICINE": "Ravim",
    "SUM_DAYS_COL": "Päevad",
    "SUM_MAX_MONTH": "Maks./kuu",
    "SUM_N_DAYS": "{n} p",
    "SUM_OVERUSE_LIMIT": "Üle ravimite liigtarvitamise peavalu piiri ({limit} päeva/kuus)",
    "SUM_HOURS": "Tunnid",
    "SUM_SHOW_HOURS": "Näita peavalutunde",
    "SUM_SHOW_PERIOD": "Näita menstruatsiooni",
    "SUM_PREVENTIVE_NONE": "Ennetavat ravi pole",
    "LOG_DUR_SHORT": "Lühikesed (alla 3 h)",
    "LOG_DUR_SHORT_LONG": "Lühikesed ja pikad"
  },
  "fi": {
    "SUM_REGISTERED": "Kirjattu",
    "SUM_LOW_REG": "Vähän kirjattuja päiviä ({months}) – luvut voivat olla liian pieniä.",
    "SUM_HIT6_LABEL": "Päänsäryn vaikutus (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6:ta ei ole kirjattu",
    "SUM_HIT6_B1": "Vähäinen tai ei vaikutusta",
    "SUM_HIT6_B2": "Jonkin verran vaikutusta",
    "SUM_HIT6_B3": "Huomattava vaikutus",
    "SUM_HIT6_B4": "Vakava vaikutus",
    "SUM_MEDS_TITLE": "Kohtauslääkitys, viimeiset {months} kuukautta",
    "SUM_MEDICINE": "Lääke",
    "SUM_DAYS_COL": "Päivät",
    "SUM_MAX_MONTH": "Enint./kk",
    "SUM_N_DAYS": "{n} pv",
    "SUM_OVERUSE_LIMIT": "Yli lääkepäänsäryn rajan ({limit} päivää/kk)",
    "SUM_HOURS": "Tunnit",
    "SUM_SHOW_HOURS": "Näytä päänsärkytunnit",
    "SUM_SHOW_PERIOD": "Näytä kuukautiset",
    "SUM_PREVENTIVE_NONE": "Ei estolääkitystä",
    "LOG_DUR_SHORT": "Lyhyet (alle 3 h)",
    "LOG_DUR_SHORT_LONG": "Lyhyet ja pitkät"
  },
  "fr": {
    "SUM_REGISTERED": "Enregistrés",
    "SUM_LOW_REG": "Peu de jours enregistrés ({months}) : les chiffres peuvent être sous-estimés.",
    "SUM_HIT6_LABEL": "Impact des céphalées (HIT-6)",
    "SUM_HIT6_NONE": "Aucun HIT-6 enregistré",
    "SUM_HIT6_B1": "Impact faible ou nul",
    "SUM_HIT6_B2": "Impact modéré",
    "SUM_HIT6_B3": "Impact important",
    "SUM_HIT6_B4": "Impact sévère",
    "SUM_MEDS_TITLE": "Traitement de crise, {months} derniers mois",
    "SUM_MEDICINE": "Médicament",
    "SUM_DAYS_COL": "Jours",
    "SUM_MAX_MONTH": "Max./mois",
    "SUM_N_DAYS": "{n} j",
    "SUM_OVERUSE_LIMIT": "Au-dessus du seuil de céphalée par abus médicamenteux ({limit} jours/mois)",
    "SUM_HOURS": "Heures",
    "SUM_SHOW_HOURS": "Afficher les heures de céphalée",
    "SUM_SHOW_PERIOD": "Afficher les règles",
    "SUM_PREVENTIVE_NONE": "Aucun traitement de fond",
    "LOG_DUR_SHORT": "Courtes (moins de 3 h)",
    "LOG_DUR_SHORT_LONG": "Courtes et longues"
  },
  "he": {
    "SUM_REGISTERED": "נרשמו",
    "SUM_LOW_REG": "מעט ימים נרשמו ({months}) – ייתכן שהמספרים נמוכים מדי.",
    "SUM_HIT6_LABEL": "השפעת כאב הראש (HIT-6)",
    "SUM_HIT6_NONE": "לא נרשם HIT-6",
    "SUM_HIT6_B1": "השפעה מועטה או ללא השפעה",
    "SUM_HIT6_B2": "השפעה מסוימת",
    "SUM_HIT6_B3": "השפעה ניכרת",
    "SUM_HIT6_B4": "השפעה חמורה",
    "SUM_MEDS_TITLE": "תרופה להתקף, {months} החודשים האחרונים",
    "SUM_MEDICINE": "תרופה",
    "SUM_DAYS_COL": "ימים",
    "SUM_MAX_MONTH": "מקס׳/חודש",
    "SUM_N_DAYS": "{n} י׳",
    "SUM_OVERUSE_LIMIT": "מעל הסף לכאב ראש משימוש יתר בתרופות ({limit} ימים בחודש)",
    "SUM_HOURS": "שעות",
    "SUM_SHOW_HOURS": "הצג שעות עם כאב ראש",
    "SUM_SHOW_PERIOD": "הצג מחזור",
    "SUM_PREVENTIVE_NONE": "ללא טיפול מונע",
    "LOG_DUR_SHORT": "קצרים (פחות מ־3 שעות)",
    "LOG_DUR_SHORT_LONG": "קצרים וארוכים"
  },
  "hr": {
    "SUM_REGISTERED": "Zabilježeno",
    "SUM_LOW_REG": "Malo zabilježenih dana ({months}) – brojevi mogu biti preniski.",
    "SUM_HIT6_LABEL": "Utjecaj glavobolje (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 nije zabilježen",
    "SUM_HIT6_B1": "Mali ili nikakav utjecaj",
    "SUM_HIT6_B2": "Određeni utjecaj",
    "SUM_HIT6_B3": "Značajan utjecaj",
    "SUM_HIT6_B4": "Težak utjecaj",
    "SUM_MEDS_TITLE": "Akutni lijekovi, posljednja {months} mjeseca",
    "SUM_MEDICINE": "Lijek",
    "SUM_DAYS_COL": "Dani",
    "SUM_MAX_MONTH": "Maks./mjesec",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Iznad granice za glavobolju zbog prekomjerne uporabe lijekova ({limit} dana/mjesec)",
    "SUM_HOURS": "Sati",
    "SUM_SHOW_HOURS": "Prikaži sate s glavoboljom",
    "SUM_SHOW_PERIOD": "Prikaži menstruaciju",
    "SUM_PREVENTIVE_NONE": "Nema preventivnih lijekova",
    "LOG_DUR_SHORT": "Kratke (ispod 3 sata)",
    "LOG_DUR_SHORT_LONG": "Kratke i duge"
  },
  "hu": {
    "SUM_REGISTERED": "Rögzítve",
    "SUM_LOW_REG": "Kevés rögzített nap ({months}) – a számok alacsonyabbak lehetnek.",
    "SUM_HIT6_LABEL": "A fejfájás hatása (HIT-6)",
    "SUM_HIT6_NONE": "Nincs rögzített HIT-6",
    "SUM_HIT6_B1": "Kis vagy semmilyen hatás",
    "SUM_HIT6_B2": "Némi hatás",
    "SUM_HIT6_B3": "Jelentős hatás",
    "SUM_HIT6_B4": "Súlyos hatás",
    "SUM_MEDS_TITLE": "Rohamoldó gyógyszer, utolsó {months} hónap",
    "SUM_MEDICINE": "Gyógyszer",
    "SUM_DAYS_COL": "Napok",
    "SUM_MAX_MONTH": "Max./hó",
    "SUM_N_DAYS": "{n} nap",
    "SUM_OVERUSE_LIMIT": "A gyógyszer-túlhasználati fejfájás határa felett ({limit} nap/hó)",
    "SUM_HOURS": "Órák",
    "SUM_SHOW_HOURS": "Fejfájásos órák megjelenítése",
    "SUM_SHOW_PERIOD": "Menstruáció megjelenítése",
    "SUM_PREVENTIVE_NONE": "Nincs megelőző kezelés",
    "LOG_DUR_SHORT": "Rövid (3 óránál rövidebb)",
    "LOG_DUR_SHORT_LONG": "Rövid és hosszú"
  },
  "is": {
    "SUM_REGISTERED": "Skráð",
    "SUM_LOW_REG": "Fáir skráðir dagar ({months}) – tölurnar gætu verið of lágar.",
    "SUM_HIT6_LABEL": "Áhrif höfuðverkjar (HIT-6)",
    "SUM_HIT6_NONE": "Ekkert HIT-6 skráð",
    "SUM_HIT6_B1": "Lítil eða engin áhrif",
    "SUM_HIT6_B2": "Nokkur áhrif",
    "SUM_HIT6_B3": "Talsverð áhrif",
    "SUM_HIT6_B4": "Alvarleg áhrif",
    "SUM_MEDS_TITLE": "Bráðalyf, síðustu {months} mánuðir",
    "SUM_MEDICINE": "Lyf",
    "SUM_DAYS_COL": "Dagar",
    "SUM_MAX_MONTH": "Hám./mán.",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Yfir mörkum fyrir lyfjaofnotkunarhöfuðverk ({limit} dagar/mán.)",
    "SUM_HOURS": "Klst.",
    "SUM_SHOW_HOURS": "Sýna klukkustundir með höfuðverk",
    "SUM_SHOW_PERIOD": "Sýna tíðir",
    "SUM_PREVENTIVE_NONE": "Engin fyrirbyggjandi lyf",
    "LOG_DUR_SHORT": "Stuttir (undir 3 klst.)",
    "LOG_DUR_SHORT_LONG": "Stuttir og langir"
  },
  "it": {
    "SUM_REGISTERED": "Registrati",
    "SUM_LOW_REG": "Pochi giorni registrati ({months}): i valori potrebbero essere sottostimati.",
    "SUM_HIT6_LABEL": "Impatto della cefalea (HIT-6)",
    "SUM_HIT6_NONE": "Nessun HIT-6 registrato",
    "SUM_HIT6_B1": "Impatto scarso o nullo",
    "SUM_HIT6_B2": "Impatto moderato",
    "SUM_HIT6_B3": "Impatto notevole",
    "SUM_HIT6_B4": "Impatto grave",
    "SUM_MEDS_TITLE": "Farmaci per l'attacco, ultimi {months} mesi",
    "SUM_MEDICINE": "Farmaco",
    "SUM_DAYS_COL": "Giorni",
    "SUM_MAX_MONTH": "Max/mese",
    "SUM_N_DAYS": "{n} g",
    "SUM_OVERUSE_LIMIT": "Oltre la soglia per cefalea da uso eccessivo di farmaci ({limit} giorni/mese)",
    "SUM_HOURS": "Ore",
    "SUM_SHOW_HOURS": "Mostra le ore con cefalea",
    "SUM_SHOW_PERIOD": "Mostra le mestruazioni",
    "SUM_PREVENTIVE_NONE": "Nessuna terapia preventiva",
    "LOG_DUR_SHORT": "Brevi (meno di 3 ore)",
    "LOG_DUR_SHORT_LONG": "Brevi e lunghi"
  },
  "ja": {
    "SUM_REGISTERED": "記録日数",
    "SUM_LOW_REG": "記録日数が少ない月があります（{months}）。数値が実際より低い可能性があります。",
    "SUM_HIT6_LABEL": "頭痛の影響度（HIT-6）",
    "SUM_HIT6_NONE": "HIT-6の記録はありません",
    "SUM_HIT6_B1": "影響はほとんどない",
    "SUM_HIT6_B2": "ある程度の影響",
    "SUM_HIT6_B3": "かなりの影響",
    "SUM_HIT6_B4": "重度の影響",
    "SUM_MEDS_TITLE": "急性期治療薬（過去{months}か月）",
    "SUM_MEDICINE": "薬",
    "SUM_DAYS_COL": "日数",
    "SUM_MAX_MONTH": "最大/月",
    "SUM_N_DAYS": "{n}日",
    "SUM_OVERUSE_LIMIT": "薬剤の使用過多による頭痛の目安を超えています（月{limit}日）",
    "SUM_HOURS": "時間",
    "SUM_SHOW_HOURS": "頭痛の時間を表示",
    "SUM_SHOW_PERIOD": "月経を表示",
    "SUM_PREVENTIVE_NONE": "予防薬はありません",
    "LOG_DUR_SHORT": "短い（3時間未満）",
    "LOG_DUR_SHORT_LONG": "短いものと長いもの"
  },
  "lt": {
    "SUM_REGISTERED": "Užregistruota",
    "SUM_LOW_REG": "Mažai užregistruotų dienų ({months}) – skaičiai gali būti per maži.",
    "SUM_HIT6_LABEL": "Galvos skausmo poveikis (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 neužregistruotas",
    "SUM_HIT6_B1": "Mažas arba jokio poveikio",
    "SUM_HIT6_B2": "Tam tikras poveikis",
    "SUM_HIT6_B3": "Didelis poveikis",
    "SUM_HIT6_B4": "Sunkus poveikis",
    "SUM_MEDS_TITLE": "Priepuolio vaistai, paskutiniai {months} mėn.",
    "SUM_MEDICINE": "Vaistas",
    "SUM_DAYS_COL": "Dienos",
    "SUM_MAX_MONTH": "Daugiausia/mėn.",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Viršyta vaistų pervartojimo galvos skausmo riba ({limit} d./mėn.)",
    "SUM_HOURS": "Valandos",
    "SUM_SHOW_HOURS": "Rodyti galvos skausmo valandas",
    "SUM_SHOW_PERIOD": "Rodyti menstruacijas",
    "SUM_PREVENTIVE_NONE": "Prevencinių vaistų nėra",
    "LOG_DUR_SHORT": "Trumpi (iki 3 val.)",
    "LOG_DUR_SHORT_LONG": "Trumpi ir ilgi"
  },
  "lv": {
    "SUM_REGISTERED": "Reģistrēts",
    "SUM_LOW_REG": "Maz reģistrētu dienu ({months}) – skaitļi var būt par zemu.",
    "SUM_HIT6_LABEL": "Galvassāpju ietekme (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 nav reģistrēts",
    "SUM_HIT6_B1": "Neliela vai nekāda ietekme",
    "SUM_HIT6_B2": "Zināma ietekme",
    "SUM_HIT6_B3": "Būtiska ietekme",
    "SUM_HIT6_B4": "Smaga ietekme",
    "SUM_MEDS_TITLE": "Lēkmes medikamenti, pēdējie {months} mēn.",
    "SUM_MEDICINE": "Medikaments",
    "SUM_DAYS_COL": "Dienas",
    "SUM_MAX_MONTH": "Maks./mēn.",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Pārsniegta medikamentu pārlietošanas galvassāpju robeža ({limit} dienas/mēn.)",
    "SUM_HOURS": "Stundas",
    "SUM_SHOW_HOURS": "Rādīt galvassāpju stundas",
    "SUM_SHOW_PERIOD": "Rādīt menstruācijas",
    "SUM_PREVENTIVE_NONE": "Nav profilaktisku medikamentu",
    "LOG_DUR_SHORT": "Īsas (līdz 3 h)",
    "LOG_DUR_SHORT_LONG": "Īsas un garas"
  },
  "mk": {
    "SUM_REGISTERED": "Регистрирано",
    "SUM_LOW_REG": "Малку регистрирани денови ({months}) – бројките може да се пониски.",
    "SUM_HIT6_LABEL": "Влијание на главоболката (HIT-6)",
    "SUM_HIT6_NONE": "Нема регистриран HIT-6",
    "SUM_HIT6_B1": "Мало или никакво влијание",
    "SUM_HIT6_B2": "Одредено влијание",
    "SUM_HIT6_B3": "Значително влијание",
    "SUM_HIT6_B4": "Тешко влијание",
    "SUM_MEDS_TITLE": "Акутни лекови, последните {months} месеци",
    "SUM_MEDICINE": "Лек",
    "SUM_DAYS_COL": "Денови",
    "SUM_MAX_MONTH": "Макс./месец",
    "SUM_N_DAYS": "{n} д.",
    "SUM_OVERUSE_LIMIT": "Над границата за главоболка од прекумерна употреба на лекови ({limit} дена/месец)",
    "SUM_HOURS": "Часови",
    "SUM_SHOW_HOURS": "Прикажи часови со главоболка",
    "SUM_SHOW_PERIOD": "Прикажи менструација",
    "SUM_PREVENTIVE_NONE": "Нема превентивни лекови",
    "LOG_DUR_SHORT": "Кратки (под 3 часа)",
    "LOG_DUR_SHORT_LONG": "Кратки и долги"
  },
  "nl": {
    "SUM_REGISTERED": "Geregistreerd",
    "SUM_LOW_REG": "Weinig geregistreerde dagen ({months}) – de cijfers kunnen te laag zijn.",
    "SUM_HIT6_LABEL": "Impact van hoofdpijn (HIT-6)",
    "SUM_HIT6_NONE": "Geen HIT-6 geregistreerd",
    "SUM_HIT6_B1": "Weinig of geen impact",
    "SUM_HIT6_B2": "Enige impact",
    "SUM_HIT6_B3": "Aanzienlijke impact",
    "SUM_HIT6_B4": "Ernstige impact",
    "SUM_MEDS_TITLE": "Aanvalsmedicatie, laatste {months} maanden",
    "SUM_MEDICINE": "Medicijn",
    "SUM_DAYS_COL": "Dagen",
    "SUM_MAX_MONTH": "Max./mnd",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Boven de grens voor hoofdpijn door overmatig medicijngebruik ({limit} dagen/mnd)",
    "SUM_HOURS": "Uren",
    "SUM_SHOW_HOURS": "Toon uren met hoofdpijn",
    "SUM_SHOW_PERIOD": "Toon menstruatie",
    "SUM_PREVENTIVE_NONE": "Geen preventieve medicatie",
    "LOG_DUR_SHORT": "Kort (minder dan 3 uur)",
    "LOG_DUR_SHORT_LONG": "Kort en lang"
  },
  "no": {
    "SUM_REGISTERED": "Registrert",
    "SUM_LOW_REG": "Få registrerte dager ({months}) – tallene kan være for lave.",
    "SUM_HIT6_LABEL": "Hodepinens påvirkning (HIT-6)",
    "SUM_HIT6_NONE": "Ingen HIT-6 registrert",
    "SUM_HIT6_B1": "Liten eller ingen påvirkning",
    "SUM_HIT6_B2": "Noe påvirkning",
    "SUM_HIT6_B3": "Betydelig påvirkning",
    "SUM_HIT6_B4": "Alvorlig påvirkning",
    "SUM_MEDS_TITLE": "Anfallsmedisin siste {months} måneder",
    "SUM_MEDICINE": "Medisin",
    "SUM_DAYS_COL": "Dager",
    "SUM_MAX_MONTH": "Maks/mnd",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Over grensen for medikamentoverforbrukshodepine ({limit} dager/mnd)",
    "SUM_HOURS": "Timer",
    "SUM_SHOW_HOURS": "Vis timer med hodepine",
    "SUM_SHOW_PERIOD": "Vis menstruasjon",
    "SUM_PREVENTIVE_NONE": "Ingen forebyggende medisin",
    "LOG_DUR_SHORT": "Korte (under 3 timer)",
    "LOG_DUR_SHORT_LONG": "Korte og lange"
  },
  "pl": {
    "SUM_REGISTERED": "Zarejestrowano",
    "SUM_LOW_REG": "Mało zarejestrowanych dni ({months}) – liczby mogą być zaniżone.",
    "SUM_HIT6_LABEL": "Wpływ bólu głowy (HIT-6)",
    "SUM_HIT6_NONE": "Brak zarejestrowanego HIT-6",
    "SUM_HIT6_B1": "Mały lub brak wpływu",
    "SUM_HIT6_B2": "Pewien wpływ",
    "SUM_HIT6_B3": "Znaczny wpływ",
    "SUM_HIT6_B4": "Poważny wpływ",
    "SUM_MEDS_TITLE": "Leki doraźne, ostatnie {months} miesiące",
    "SUM_MEDICINE": "Lek",
    "SUM_DAYS_COL": "Dni",
    "SUM_MAX_MONTH": "Maks./mies.",
    "SUM_N_DAYS": "{n} d.",
    "SUM_OVERUSE_LIMIT": "Powyżej progu bólu głowy z nadużywania leków ({limit} dni/mies.)",
    "SUM_HOURS": "Godziny",
    "SUM_SHOW_HOURS": "Pokaż godziny z bólem głowy",
    "SUM_SHOW_PERIOD": "Pokaż miesiączkę",
    "SUM_PREVENTIVE_NONE": "Brak leczenia zapobiegawczego",
    "LOG_DUR_SHORT": "Krótkie (poniżej 3 h)",
    "LOG_DUR_SHORT_LONG": "Krótkie i długie"
  },
  "pt-BR": {
    "SUM_REGISTERED": "Registrados",
    "SUM_LOW_REG": "Poucos dias registrados ({months}) – os números podem estar baixos.",
    "SUM_HIT6_LABEL": "Impacto da cefaleia (HIT-6)",
    "SUM_HIT6_NONE": "Nenhum HIT-6 registrado",
    "SUM_HIT6_B1": "Pouco ou nenhum impacto",
    "SUM_HIT6_B2": "Algum impacto",
    "SUM_HIT6_B3": "Impacto considerável",
    "SUM_HIT6_B4": "Impacto grave",
    "SUM_MEDS_TITLE": "Medicação para crise, últimos {months} meses",
    "SUM_MEDICINE": "Medicamento",
    "SUM_DAYS_COL": "Dias",
    "SUM_MAX_MONTH": "Máx./mês",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Acima do limite para cefaleia por uso excessivo de medicamentos ({limit} dias/mês)",
    "SUM_HOURS": "Horas",
    "SUM_SHOW_HOURS": "Mostrar horas com cefaleia",
    "SUM_SHOW_PERIOD": "Mostrar menstruação",
    "SUM_PREVENTIVE_NONE": "Sem medicação preventiva",
    "LOG_DUR_SHORT": "Curtas (menos de 3 h)",
    "LOG_DUR_SHORT_LONG": "Curtas e longas"
  },
  "pt": {
    "SUM_REGISTERED": "Registados",
    "SUM_LOW_REG": "Poucos dias registados ({months}) – os números podem estar baixos.",
    "SUM_HIT6_LABEL": "Impacto da cefaleia (HIT-6)",
    "SUM_HIT6_NONE": "Nenhum HIT-6 registado",
    "SUM_HIT6_B1": "Pouco ou nenhum impacto",
    "SUM_HIT6_B2": "Algum impacto",
    "SUM_HIT6_B3": "Impacto considerável",
    "SUM_HIT6_B4": "Impacto grave",
    "SUM_MEDS_TITLE": "Medicação de crise, últimos {months} meses",
    "SUM_MEDICINE": "Medicamento",
    "SUM_DAYS_COL": "Dias",
    "SUM_MAX_MONTH": "Máx./mês",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Acima do limite para cefaleia por uso excessivo de medicação ({limit} dias/mês)",
    "SUM_HOURS": "Horas",
    "SUM_SHOW_HOURS": "Mostrar horas com cefaleia",
    "SUM_SHOW_PERIOD": "Mostrar menstruação",
    "SUM_PREVENTIVE_NONE": "Sem medicação preventiva",
    "LOG_DUR_SHORT": "Curtas (menos de 3 h)",
    "LOG_DUR_SHORT_LONG": "Curtas e longas"
  },
  "ro": {
    "SUM_REGISTERED": "Înregistrate",
    "SUM_LOW_REG": "Puține zile înregistrate ({months}) – cifrele pot fi prea mici.",
    "SUM_HIT6_LABEL": "Impactul cefaleei (HIT-6)",
    "SUM_HIT6_NONE": "Niciun HIT-6 înregistrat",
    "SUM_HIT6_B1": "Impact mic sau absent",
    "SUM_HIT6_B2": "Un anumit impact",
    "SUM_HIT6_B3": "Impact considerabil",
    "SUM_HIT6_B4": "Impact sever",
    "SUM_MEDS_TITLE": "Medicație pentru criză, ultimele {months} luni",
    "SUM_MEDICINE": "Medicament",
    "SUM_DAYS_COL": "Zile",
    "SUM_MAX_MONTH": "Max./lună",
    "SUM_N_DAYS": "{n} z",
    "SUM_OVERUSE_LIMIT": "Peste pragul pentru cefaleea prin abuz de medicamente ({limit} zile/lună)",
    "SUM_HOURS": "Ore",
    "SUM_SHOW_HOURS": "Afișează orele cu cefalee",
    "SUM_SHOW_PERIOD": "Afișează menstruația",
    "SUM_PREVENTIVE_NONE": "Fără tratament preventiv",
    "LOG_DUR_SHORT": "Scurte (sub 3 ore)",
    "LOG_DUR_SHORT_LONG": "Scurte și lungi"
  },
  "ru": {
    "SUM_REGISTERED": "Записано",
    "SUM_LOW_REG": "Мало записанных дней ({months}) – цифры могут быть занижены.",
    "SUM_HIT6_LABEL": "Влияние головной боли (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 не записан",
    "SUM_HIT6_B1": "Незначительное влияние или его нет",
    "SUM_HIT6_B2": "Некоторое влияние",
    "SUM_HIT6_B3": "Значительное влияние",
    "SUM_HIT6_B4": "Тяжёлое влияние",
    "SUM_MEDS_TITLE": "Экстренные лекарства, последние {months} мес.",
    "SUM_MEDICINE": "Лекарство",
    "SUM_DAYS_COL": "Дни",
    "SUM_MAX_MONTH": "Макс./мес.",
    "SUM_N_DAYS": "{n} дн.",
    "SUM_OVERUSE_LIMIT": "Выше порога лекарственно-индуцированной головной боли ({limit} дн./мес.)",
    "SUM_HOURS": "Часы",
    "SUM_SHOW_HOURS": "Показать часы с головной болью",
    "SUM_SHOW_PERIOD": "Показать менструацию",
    "SUM_PREVENTIVE_NONE": "Нет профилактического лечения",
    "LOG_DUR_SHORT": "Короткие (менее 3 ч)",
    "LOG_DUR_SHORT_LONG": "Короткие и длинные"
  },
  "sk": {
    "SUM_REGISTERED": "Zaznamenané",
    "SUM_LOW_REG": "Málo zaznamenaných dní ({months}) – čísla môžu byť nižšie.",
    "SUM_HIT6_LABEL": "Dopad bolesti hlavy (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 nie je zaznamenaný",
    "SUM_HIT6_B1": "Malý alebo žiadny dopad",
    "SUM_HIT6_B2": "Určitý dopad",
    "SUM_HIT6_B3": "Značný dopad",
    "SUM_HIT6_B4": "Závažný dopad",
    "SUM_MEDS_TITLE": "Akútne lieky, posledné {months} mesiace",
    "SUM_MEDICINE": "Liek",
    "SUM_DAYS_COL": "Dni",
    "SUM_MAX_MONTH": "Max./mesiac",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Nad hranicou pre bolesť hlavy z nadužívania liekov ({limit} dní/mesiac)",
    "SUM_HOURS": "Hodiny",
    "SUM_SHOW_HOURS": "Zobraziť hodiny s bolesťou hlavy",
    "SUM_SHOW_PERIOD": "Zobraziť menštruáciu",
    "SUM_PREVENTIVE_NONE": "Bez preventívnej liečby",
    "LOG_DUR_SHORT": "Krátke (pod 3 h)",
    "LOG_DUR_SHORT_LONG": "Krátke aj dlhé"
  },
  "sl": {
    "SUM_REGISTERED": "Zabeleženo",
    "SUM_LOW_REG": "Malo zabeleženih dni ({months}) – številke so lahko prenizke.",
    "SUM_HIT6_LABEL": "Vpliv glavobola (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 ni zabeležen",
    "SUM_HIT6_B1": "Majhen ali nikakršen vpliv",
    "SUM_HIT6_B2": "Nekaj vpliva",
    "SUM_HIT6_B3": "Precejšen vpliv",
    "SUM_HIT6_B4": "Hud vpliv",
    "SUM_MEDS_TITLE": "Akutna zdravila, zadnji {months} meseci",
    "SUM_MEDICINE": "Zdravilo",
    "SUM_DAYS_COL": "Dnevi",
    "SUM_MAX_MONTH": "Najv./mesec",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Nad mejo za glavobol zaradi čezmerne rabe zdravil ({limit} dni/mesec)",
    "SUM_HOURS": "Ure",
    "SUM_SHOW_HOURS": "Prikaži ure z glavobolom",
    "SUM_SHOW_PERIOD": "Prikaži menstruacijo",
    "SUM_PREVENTIVE_NONE": "Brez preventivnih zdravil",
    "LOG_DUR_SHORT": "Kratki (pod 3 ure)",
    "LOG_DUR_SHORT_LONG": "Kratki in dolgi"
  },
  "sr": {
    "SUM_REGISTERED": "Забележено",
    "SUM_LOW_REG": "Мало забележених дана ({months}) – бројеви могу бити прениски.",
    "SUM_HIT6_LABEL": "Утицај главобоље (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 није забележен",
    "SUM_HIT6_B1": "Мали или никакав утицај",
    "SUM_HIT6_B2": "Одређени утицај",
    "SUM_HIT6_B3": "Значајан утицај",
    "SUM_HIT6_B4": "Тежак утицај",
    "SUM_MEDS_TITLE": "Акутни лекови, последња {months} месеца",
    "SUM_MEDICINE": "Лек",
    "SUM_DAYS_COL": "Дани",
    "SUM_MAX_MONTH": "Макс./месец",
    "SUM_N_DAYS": "{n} д.",
    "SUM_OVERUSE_LIMIT": "Изнад границе за главобољу због прекомерне употребе лекова ({limit} дана/месец)",
    "SUM_HOURS": "Сати",
    "SUM_SHOW_HOURS": "Прикажи сате са главобољом",
    "SUM_SHOW_PERIOD": "Прикажи менструацију",
    "SUM_PREVENTIVE_NONE": "Нема превентивних лекова",
    "LOG_DUR_SHORT": "Кратке (испод 3 сата)",
    "LOG_DUR_SHORT_LONG": "Кратке и дуге"
  },
  "sv": {
    "SUM_REGISTERED": "Registrerat",
    "SUM_LOW_REG": "Få registrerade dagar ({months}) – siffrorna kan vara för låga.",
    "SUM_HIT6_LABEL": "Huvudvärkens påverkan (HIT-6)",
    "SUM_HIT6_NONE": "Ingen HIT-6 registrerad",
    "SUM_HIT6_B1": "Liten eller ingen påverkan",
    "SUM_HIT6_B2": "Viss påverkan",
    "SUM_HIT6_B3": "Betydande påverkan",
    "SUM_HIT6_B4": "Svår påverkan",
    "SUM_MEDS_TITLE": "Anfallsmedicin, senaste {months} månaderna",
    "SUM_MEDICINE": "Läkemedel",
    "SUM_DAYS_COL": "Dagar",
    "SUM_MAX_MONTH": "Max/mån",
    "SUM_N_DAYS": "{n} d",
    "SUM_OVERUSE_LIMIT": "Över gränsen för läkemedelsöverförbrukningshuvudvärk ({limit} dagar/mån)",
    "SUM_HOURS": "Timmar",
    "SUM_SHOW_HOURS": "Visa timmar med huvudvärk",
    "SUM_SHOW_PERIOD": "Visa mens",
    "SUM_PREVENTIVE_NONE": "Inget förebyggande läkemedel",
    "LOG_DUR_SHORT": "Korta (under 3 timmar)",
    "LOG_DUR_SHORT_LONG": "Korta och långa"
  },
  "tr": {
    "SUM_REGISTERED": "Kayıtlı",
    "SUM_LOW_REG": "Az kayıtlı gün ({months}) – sayılar olduğundan düşük olabilir.",
    "SUM_HIT6_LABEL": "Baş ağrısının etkisi (HIT-6)",
    "SUM_HIT6_NONE": "Kayıtlı HIT-6 yok",
    "SUM_HIT6_B1": "Az veya hiç etki yok",
    "SUM_HIT6_B2": "Bir miktar etki",
    "SUM_HIT6_B3": "Önemli etki",
    "SUM_HIT6_B4": "Ciddi etki",
    "SUM_MEDS_TITLE": "Atak ilacı, son {months} ay",
    "SUM_MEDICINE": "İlaç",
    "SUM_DAYS_COL": "Gün",
    "SUM_MAX_MONTH": "Maks./ay",
    "SUM_N_DAYS": "{n} g",
    "SUM_OVERUSE_LIMIT": "İlaç aşırı kullanım baş ağrısı sınırının üzerinde (ayda {limit} gün)",
    "SUM_HOURS": "Saat",
    "SUM_SHOW_HOURS": "Baş ağrılı saatleri göster",
    "SUM_SHOW_PERIOD": "Adet dönemini göster",
    "SUM_PREVENTIVE_NONE": "Koruyucu ilaç yok",
    "LOG_DUR_SHORT": "Kısa (3 saatten az)",
    "LOG_DUR_SHORT_LONG": "Kısa ve uzun"
  },
  "uk": {
    "SUM_REGISTERED": "Записано",
    "SUM_LOW_REG": "Мало записаних днів ({months}) – цифри можуть бути заниженими.",
    "SUM_HIT6_LABEL": "Вплив головного болю (HIT-6)",
    "SUM_HIT6_NONE": "HIT-6 не записано",
    "SUM_HIT6_B1": "Незначний вплив або його немає",
    "SUM_HIT6_B2": "Певний вплив",
    "SUM_HIT6_B3": "Значний вплив",
    "SUM_HIT6_B4": "Тяжкий вплив",
    "SUM_MEDS_TITLE": "Екстрені ліки, останні {months} міс.",
    "SUM_MEDICINE": "Ліки",
    "SUM_DAYS_COL": "Дні",
    "SUM_MAX_MONTH": "Макс./міс.",
    "SUM_N_DAYS": "{n} дн.",
    "SUM_OVERUSE_LIMIT": "Вище порогу медикаментозного головного болю ({limit} дн./міс.)",
    "SUM_HOURS": "Години",
    "SUM_SHOW_HOURS": "Показати години з головним болем",
    "SUM_SHOW_PERIOD": "Показати менструацію",
    "SUM_PREVENTIVE_NONE": "Немає профілактичного лікування",
    "LOG_DUR_SHORT": "Короткі (менше 3 год)",
    "LOG_DUR_SHORT_LONG": "Короткі та довгі"
  }
}
FILE_END

cat > "$TMP/apply.mjs" <<'FILE_END'
import fs from "node:fs";
const [durationFile, textsJson] = process.argv.slice(2);

// data.js: add durationLabel() once
const dataFile = "src/components/headache/data.js";
let data = fs.readFileSync(dataFile, "utf8");
if (!data.includes("export function durationLabel(")) {
  data = data.replace(/\s*$/, "\n") + fs.readFileSync(durationFile, "utf8");
  fs.writeFileSync(dataFile, data);
}
console.log(`✓ ${dataFile}`);

// DayDetails.js: use durationLabel (short attacks have no minutes)
const dayFile = "src/components/headache/DayDetails.js";
if (fs.existsSync(dayFile)) {
  let day = fs.readFileSync(dayFile, "utf8");
  if (!day.includes("durationLabel(")) {
    const from = `            {Number(record.durationMinutes) > 0 && (
              <Line label={t.CAL_DURATION}>{formatUnit(locale, record.durationMinutes, "minute")}</Line>
            )}`;
    const to = `            {durationLabel(t, locale, record) && <Line label={t.CAL_DURATION}>{durationLabel(t, locale, record)}</Line>}`;
    if (!day.includes(from)) throw new Error(`${dayFile}: could not find the duration line`);
    day = day.replace(from, to).replace(
      /import \{ ([^}]*) \} from "@\/components\/headache\/data";/,
      (m, names) => `import { ${names.trim()}, durationLabel } from "@/components/headache/data";`
    );
    fs.writeFileSync(dayFile, day);
  }
  console.log(`✓ ${dayFile}`);
}

// texts.js: new texts in all languages (keys stay sorted, same formatting)
const textsFile = "src/components/headache/texts.js";
const src = fs.readFileSync(textsFile, "utf8");
const marker = "export const TEXTS = ";
const at = src.indexOf(marker);
if (at < 0) throw new Error(`${textsFile}: could not find "${marker}"`);
const texts = JSON.parse(src.slice(at + marker.length).replace(/;\s*$/, ""));
const added = JSON.parse(fs.readFileSync(textsJson, "utf8"));
for (const [lang, values] of Object.entries(added)) {
  if (!texts[lang]) continue;
  const merged = { ...texts[lang], ...values };
  texts[lang] = Object.fromEntries(Object.keys(merged).sort().map((k) => [k, merged[k]]));
}
fs.writeFileSync(textsFile, src.slice(0, at) + marker + JSON.stringify(texts, null, 2) + ";\n");
console.log(`✓ ${textsFile}  (new texts in ${Object.keys(added).length} languages)`);
FILE_END
node "$TMP/apply.mjs" "$TMP/durationLabel.js" "$TMP/texts.json"

echo "Done. Reload the dashboard."
