#!/usr/bin/env bash
# apply-phone-calendar-design.sh
# Makes the dashboard calendar and monthly summary look like "Min dagbok" in the app.
# Run from the root of the HeadacheCalendar repo:  bash apply-phone-calendar-design.sh
set -euo pipefail
[ -f src/components/headache/HeadacheCalendar.js ] || { echo "Run this from the HeadacheCalendar repo root"; exit 1; }

echo "Writing src/components/headache/HeadacheCalendar.js"
cat > "src/components/headache/HeadacheCalendar.js" <<'PHONE_EOF'
// src/components/headache/HeadacheCalendar.js
"use client";

import { useMemo } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  INTENSITY,
  hasAcute,
  hasNote,
  intensityOf,
  intlLocale,
  monthGrid,
  toDateKey,
  todayKey,
} from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ChevronIcon, ClusterIcon, NoteIcon } from "@/components/headache/icons";

// Day icons: size in px, centred on the corner of the date box (the cell has 3 px padding)
const DAY_ICON_SIZE = 17;
// How far the icons are moved from the corner towards the centre of the date (px)
const ICON_INSET = 3;
const ICON_OFFSET = 3 - DAY_ICON_SIZE / 2 + ICON_INSET;

const FILL = { 1: COLORS.mild, 2: COLORS.moderate, 3: COLORS.strong, 4: COLORS.extreme };

// Blinded: every registered day in one flat light blue, so only *whether* a day was
// registered shows – not intensity, medication, aura, cluster, period or notes
const BLIND_BG = "#DCEBF7";
const BLIND_TEXT = "#14324a";

// Same look as the calendar in the app: rounded tiles with a grey outline, filled with the intensity colour
const TILE = "flex h-full w-full items-center justify-center rounded-[9px] text-[15px] tabular-nums";
const EMPTY = "border-[1.5px] border-[#c9d1dc] bg-white font-medium text-[#3b4757]";
const FUTURE = "border-[1.5px] border-[#e3e8ef] bg-white/70 font-medium text-[#b7c0cc]";
// Migraine: a red frame around the day, like in the app
const MIGRAINE_FRAME = "#e8696b";

export default function HeadacheCalendar({
  byDate,
  year,
  month,
  canPrev,
  canNext,
  onPrev,
  onNext,
  selected,
  onSelect,
  showNotes = false,
  blinded = false,
}) {
  const { t, locale } = useHeadacheText();
  const loc = intlLocale(locale);
  const today = todayKey();
  const cells = monthGrid(year, month);

  const title = useMemo(
    () => new Intl.DateTimeFormat(loc, { month: "long", year: "numeric" }).format(new Date(year, month, 1)),
    [loc, year, month]
  );

  // Monday-first weekday initials in the selected language (2024-01-01 was a Monday)
  const weekdays = useMemo(() => {
    const fmt = new Intl.DateTimeFormat(loc, { weekday: "narrow" });
    return Array.from({ length: 7 }, (_, i) => fmt.format(new Date(2024, 0, 1 + i)));
  }, [loc]);

  const longDate = useMemo(
    () => new Intl.DateTimeFormat(loc, { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
    [loc]
  );

  return (
    <div>
      {/* Month navigation */}
      <div className="mx-auto mb-4 flex max-w-sm items-center justify-between">
        <button
          type="button"
          onClick={onPrev}
          disabled={!canPrev}
          aria-label={t.CAL_PREV_MONTH}
          className="rounded-full p-1.5 text-[#4f7cc0] transition hover:bg-blue-50 disabled:opacity-25 rtl:rotate-180"
        >
          <ChevronIcon dir="left" size={20} />
        </button>
        <h2 className="text-lg font-bold uppercase tracking-wide text-[#2c4a6e]" aria-live="polite">
          {title}
        </h2>
        <button
          type="button"
          onClick={onNext}
          disabled={!canNext}
          aria-label={t.CAL_NEXT_MONTH}
          className="rounded-full p-1.5 text-[#4f7cc0] transition hover:bg-blue-50 disabled:opacity-25 rtl:rotate-180"
        >
          <ChevronIcon dir="right" size={20} />
        </button>
      </div>

      <div className="mx-auto max-w-sm">
        <div className="grid grid-cols-7 gap-2 pb-2 text-center text-xs font-medium uppercase text-[#7d8899]">
          {weekdays.map((d, i) => (
            <div key={i}>{d}</div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-x-2 gap-y-2.5" role="grid">
          {cells.map((day, i) => {
            if (!day) return <div key={i} />;
            const key = toDateKey(year, month, day);
            const r = byDate.get(key);
            const level = r ? intensityOf(r) : null;
            const isToday = key === today;
            const isFuture = key > today;
            const isSelected = key === selected;
            const note = showNotes && hasNote(r);

            if (blinded) {
              // Read-only and nothing but registered / not registered – also in the screen-reader label
              return (
                <div
                  key={i}
                  role="gridcell"
                  aria-label={`${longDate.format(new Date(year, month, day))}, ${r ? t.CAL_REGISTERED : t.CAL_NO_REGISTRATION}`}
                  className="h-11 rounded-xl p-[3px]"
                >
                  <span
                    className={`${TILE} ${
                      r
                        ? "font-semibold"
                        : isFuture
                          ? FUTURE
                          : EMPTY
                    } ${isToday ? "ring-2 ring-[#6b93d1] ring-offset-1" : ""}`}
                    style={r ? { backgroundColor: BLIND_BG, color: BLIND_TEXT } : undefined}
                  >
                    {day}
                  </span>
                </div>
              );
            }

            let box = EMPTY; // past, nothing registered – outlined like in the app
            let style;
            if (r && level > 0) {
              box = "font-semibold text-white";
              style = { backgroundColor: FILL[level] };
            } else if (r) {
              box = "border-[1.5px] border-[#7ea6e6] bg-[#eef4fd] font-semibold text-[#3b5f94]"; // registered, no headache
            } else if (isToday) {
              box = "font-semibold text-white";
              style = { backgroundColor: COLORS.today };
            } else if (isFuture) {
              box = FUTURE;
            }

            // Frame around the day: menstruation fills the 3 px padding with strong pink,
            // migraine adds a red line outside it (both can show at once)
            const migraine = !!r?.isMigraine;
            const frameStyle =
              r?.hasPeriod || migraine
                ? {
                    backgroundColor: r?.hasPeriod ? COLORS.periodStrong : "#fff",
                    boxShadow: migraine
                      ? `0 0 0 1.5px ${MIGRAINE_FRAME}`
                      : `0 0 0 1px ${COLORS.periodStrong}`,
                  }
                : undefined;

            const label = [
              longDate.format(new Date(year, month, day)),
              r ? t[INTENSITY[level].key] : t.CAL_NO_REGISTRATION,
              r?.hasPeriod && t.CAL_PERIOD,
              r && hasAcute(r) && t.CAL_ACUTE_MEDICATION,
              r?.hasAura && t.CAL_AURA,
              r?.hasClusterHeadache && t.CAL_CLUSTER,
              r?.isMigraine && t.CAL_MIGRAINE,
              note && t.CAL_NOTE,
            ]
              .filter(Boolean)
              .join(", ");

            return (
              <div
                key={i}
                className="relative h-11 rounded-xl p-[3px]"
                // The frame is padding plus a box-shadow ring, so the day keeps its size
                style={frameStyle}
              >
                <button
                  type="button"
                  disabled={isFuture}
                  onClick={() => onSelect(key)}
                  aria-label={label}
                  aria-pressed={isSelected}
                  className={`relative ${TILE} transition ${box} ${
                    isSelected ? "ring-2 ring-[#9dbdee] ring-offset-1" : isToday && r ? "ring-2 ring-[#6b93d1] ring-offset-1" : ""
                  } ${isFuture ? "cursor-default" : "hover:brightness-95"}`}
                  style={style}
                >
                  {day}
                </button>

                {/* Acute medication – top right */}
                {r && hasAcute(r) && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ top: ICON_OFFSET, insetInlineEnd: ICON_OFFSET }}>
                    <AcuteIcon size={DAY_ICON_SIZE} />
                  </span>
                )}

                {/* Aura and cluster headache – bottom left */}
                {(r?.hasAura || r?.hasClusterHeadache) && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ bottom: ICON_OFFSET, insetInlineStart: ICON_OFFSET }}>
                    {r.hasAura && <AuraIcon size={DAY_ICON_SIZE} />}
                    {r.hasClusterHeadache && <ClusterIcon size={DAY_ICON_SIZE} />}
                  </span>
                )}

                {/* Written note – bottom right */}
                {note && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ bottom: ICON_OFFSET, insetInlineEnd: ICON_OFFSET }}>
                    <NoteIcon size={DAY_ICON_SIZE} />
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
PHONE_EOF

echo "Writing src/components/headache/MonthlySummary.js"
cat > "src/components/headache/MonthlySummary.js" <<'PHONE_EOF'
// src/components/headache/MonthlySummary.js
"use client";

import { useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, INTENSITY, formatDays, formatUnit, monthScore, monthStats } from "@/components/headache/data";
import {
  AcuteIcon,
  AttacksIcon,
  AuraIcon,
  ClusterIcon,
  FaceIcon,
  HoursIcon,
  InjectionIcon,
  MigraineIcon,
  NoteIcon,
  PeriodIcon,
} from "@/components/headache/icons";

// Same blue as the numbers in the app
const VALUE = "text-[#4a7fc1]";
const CARD = "rounded-2xl bg-white shadow-[0_4px_16px_-6px_rgba(60,100,160,0.35)]";

function Row({ icon, label, value }) {
  if (!value || value === "0") return null; // rows with 0 are hidden
  return (
    <li className="flex items-center gap-2.5 py-[7px]">
      <span className="flex w-6 shrink-0 justify-center">{icon}</span>
      <span className="min-w-0 flex-1 hyphens-auto text-[15px] leading-tight text-[#3b4757] [overflow-wrap:anywhere]">{label}</span>
      <span className={`whitespace-nowrap text-[15px] font-medium tabular-nums ${VALUE}`}>{value}</span>
    </li>
  );
}

// Monthly numbers under the calendar, laid out like "Min dagbok" in the app:
// a list on the left, month intensity and medication on the right
export default function MonthlySummary({ patient, byDate, year, month }) {
  const { t, locale } = useHeadacheText();
  const [showHelp, setShowHelp] = useState(false);

  const s = monthStats(byDate, year, month);
  const score = monthScore(patient, year, month);
  const hours = Math.round((s.minutes / 60) * 10) / 10;
  const days = (n) => (n ? formatDays(locale, n) : null);
  const overuse = s.acuteDays >= 10; // ≥10 days/month: risk of medication-overuse headache

  return (
    <div className="mt-4 grid grid-cols-[minmax(0,1.55fr)_minmax(0,1fr)] items-start gap-3">
      {/* Numbers for the month */}
      <section className={`${CARD} px-3.5 py-2`}>
        <ul>
          <Row icon={<AttacksIcon size={20} />} label={t.CAL_ATTACKS} value={s.attacks} />
          <Row icon={<HoursIcon size={21} />} label={t.CAL_HOURS_WITH_HEADACHE} value={hours ? formatUnit(locale, hours, "hour") : null} />
          {[1, 2, 3, 4].map((level) => (
            <Row
              key={level}
              icon={<FaceIcon face={INTENSITY[level].face} size={20} />}
              label={t[INTENSITY[level].key]}
              value={days(s.intensity[level])}
            />
          ))}
          <Row icon={<MigraineIcon size={19} />} label={t.CAL_MIGRAINE} value={days(s.migraine)} />
          <Row icon={<AuraIcon size={20} />} label={t.CAL_AURA} value={days(s.aura)} />
          <Row icon={<ClusterIcon size={20} />} label={t.CAL_CLUSTER} value={days(s.cluster)} />
          <Row icon={<PeriodIcon size={19} />} label={t.CAL_PERIOD} value={days(s.period)} />
          {/* Days with a written note – only when the patient shares notes, like in the calendar */}
          <Row icon={<NoteIcon size={20} />} label={t.CAL_NOTES} value={patient?.shareNotes ? days(s.notes) : null} />
        </ul>
        {s.registered === 0 && <p className="py-2 text-sm italic text-slate-400">{t.CAL_NO_REGISTRATION}</p>}
      </section>

      <div className="space-y-3">
        {/* Month intensity */}
        <section className={`${CARD} px-3 py-3 text-center`}>
          <div className="flex items-center justify-center gap-1.5 text-[15px] leading-tight text-[#3b4757]">
            <span>{t.CAL_MONTH_INTENSITY}</span>
            <button
              type="button"
              onClick={() => setShowHelp((v) => !v)}
              aria-expanded={showHelp}
              aria-label={t.CAL_MONTH_INTENSITY_HELP}
              className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-slate-300 text-[10px] font-bold text-white hover:bg-slate-400"
            >
              ?
            </button>
          </div>
          <div className={`mt-2 text-3xl font-medium tabular-nums ${VALUE}`}>{score ?? "–"}</div>
          {showHelp && <p className="mt-2 text-start text-xs leading-relaxed text-slate-500">{t.CAL_MONTH_INTENSITY_HELP}</p>}
        </section>

        {/* Medication: days with acute medication and days with an injection */}
        <section className={`${CARD} px-3 py-3`}>
          <h3 className="text-center text-[15px] text-[#3b4757]">{t.CAL_MEDICATION}</h3>
          <ul className="mt-2 space-y-2">
            <li className="flex items-center gap-2" title={t.CAL_ACUTE_MEDICATION}>
              <AcuteIcon size={20} />
              <span className="sr-only">{t.CAL_ACUTE_MEDICATION}:</span>
              <span
                className={`text-[15px] tabular-nums ${overuse ? "font-bold text-red-600" : `font-medium ${VALUE}`}`}
                style={overuse ? { color: COLORS.acute } : undefined}
              >
                {formatDays(locale, s.acuteDays)}
              </span>
            </li>
            <li className="flex items-center gap-2" title={t.CAL_INJECTIONS}>
              <InjectionIcon size={20} />
              <span className="sr-only">{t.CAL_INJECTIONS}:</span>
              <span className={`text-[15px] font-medium tabular-nums ${VALUE}`}>{formatDays(locale, s.injectionDays)}</span>
            </li>
          </ul>
        </section>
      </div>
    </div>
  );
}
PHONE_EOF

echo "Writing src/components/headache/CalendarCard.js"
cat > "src/components/headache/CalendarCard.js" <<'PHONE_EOF'
// src/components/headache/CalendarCard.js
"use client";

import { useMemo, useState } from "react";
import HeadacheCalendar from "@/components/headache/HeadacheCalendar";
import DayDetails from "@/components/headache/DayDetails";
import MonthlySummary from "@/components/headache/MonthlySummary";
import { MedicationDropdown, PreviousMedicationDropdown } from "@/components/headache/MedicationLists";
import { firstRecordMonth, indexRecords } from "@/components/headache/data";

// The calendar card: month navigation, day details, monthly summary and the medication dropdowns
export default function CalendarCard({ patient }) {
  const now = new Date();
  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });
  const [selected, setSelected] = useState(null);

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);

  const idx = (v) => v.year * 12 + v.month;
  const current = { year: now.getFullYear(), month: now.getMonth() };
  const move = (delta) => {
    setView((v) => {
      const n = idx(v) + delta;
      return { year: Math.floor(n / 12), month: n % 12 };
    });
    setSelected(null);
  };

  return (
    <section className="rounded-3xl border border-white/70 bg-[#eef3f9]/90 p-3 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:p-4">
      {/* The calendar in its own white card, like in the app */}
      <div className="rounded-2xl bg-white px-3 pb-4 pt-3 shadow-[0_4px_16px_-6px_rgba(60,100,160,0.35)] sm:px-4">
        <HeadacheCalendar
          byDate={byDate}
          year={view.year}
          month={view.month}
          canPrev={first ? idx(view) > idx(first) : false}
          canNext={idx(view) < idx(current)}
          onPrev={() => move(-1)}
          onNext={() => move(1)}
          selected={selected}
          onSelect={(key) => setSelected((cur) => (cur === key ? null : key))}
          showNotes={!!patient?.shareNotes}
        />
        <DayDetails
          patient={patient}
          dateKey={selected}
          record={selected ? byDate.get(selected) : null}
          onClose={() => setSelected(null)}
        />
      </div>

      {/* Monthly numbers under the calendar, following the month shown – laid out like the app */}
      <MonthlySummary patient={patient} byDate={byDate} year={view.year} month={view.month} />

      {/* Medication and previously used medication, as dropdowns */}
      <MedicationDropdown patient={patient} />
      <PreviousMedicationDropdown patient={patient} />
    </section>
  );
}
PHONE_EOF

echo "Writing src/components/headache/BlindedCalendarCard.js"
cat > "src/components/headache/BlindedCalendarCard.js" <<'PHONE_EOF'
// src/components/headache/BlindedCalendarCard.js
"use client";

import { useMemo, useState } from "react";
import HeadacheCalendar from "@/components/headache/HeadacheCalendar";
import { firstRecordMonth, indexRecords } from "@/components/headache/data";

// Calendar only, read-only: month navigation and the blinded grid.
// No day details, monthly summary or medication lists – they would show what the
// blinded grid hides.
export default function BlindedCalendarCard({ patient }) {
  const now = new Date();
  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);

  const idx = (v) => v.year * 12 + v.month;
  const current = { year: now.getFullYear(), month: now.getMonth() };
  const move = (delta) =>
    setView((v) => {
      const n = idx(v) + delta;
      return { year: Math.floor(n / 12), month: n % 12 };
    });

  return (
    <section className="rounded-3xl border border-white/70 bg-[#eef3f9]/90 p-3 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:p-4">
      {/* The calendar in its own white card, like in the app */}
      <div className="rounded-2xl bg-white px-3 pb-4 pt-3 shadow-[0_4px_16px_-6px_rgba(60,100,160,0.35)] sm:px-4">
        <HeadacheCalendar
          byDate={byDate}
          year={view.year}
          month={view.month}
          canPrev={first ? idx(view) > idx(first) : false}
          canNext={idx(view) < idx(current)}
          onPrev={() => move(-1)}
          onNext={() => move(1)}
          blinded
        />
      </div>
    </section>
  );
}
PHONE_EOF

echo "Writing src/components/headache/data.js"
cat > "src/components/headache/data.js" <<'PHONE_EOF'
// src/components/headache/data.js
// Pure helpers for the patient data returned by /api/patients/details/json

export const INTENSITY = {
  0: { key: "CAL_NO_HEADACHE", face: "none" },
  1: { key: "CAL_MILD", face: "mild" },
  2: { key: "CAL_MODERATE", face: "moderate" },
  3: { key: "CAL_STRONG", face: "strong" },
  4: { key: "CAL_EXTREME", face: "extreme" },
};

// Same colours as the app
export const COLORS = {
  none: "#7ea6e6",
  mild: "#5cb87e",
  moderate: "#f6c45f",
  strong: "#ee766e",
  extreme: "#b53b31",
  today: "#6b93d1",
  period: "#fde6ee",
  periodStrong: "#d63384", // thick frame around menstruation days in the calendar
  acute: "#e5484d",
  aura: "#f2c230",
  cluster: "#6b2fb3",
  note: "#4f7cc0",
};

export const EFFECT_KEYS = { 1: "EFFECT_NONE", 2: "EFFECT_MODERATE", 3: "EFFECT_GOOD" };

// CGRP antibodies (N02CD) and botulinum toxin (M03AX01) are given as injections
const INJECTION_ATC = [/^N02CD/i, /^M03AX01/i];
const isInjectionAtc = (atc) => !!atc && INJECTION_ATC.some((re) => re.test(atc));

export const pad = (n) => String(n).padStart(2, "0");
export const toDateKey = (y, m, d) => `${y}-${pad(m + 1)}-${pad(d)}`; // m is 0-based
export const monthKey = (y, m) => `${y}-${pad(m + 1)}`;

export function todayKey() {
  const now = new Date();
  return toDateKey(now.getFullYear(), now.getMonth(), now.getDate());
}

export function indexRecords(records = []) {
  const map = new Map();
  for (const r of records) if (r?.date) map.set(r.date, r);
  return map;
}

// A written note on the day (only shown when the patient shares notes)
export const hasNote = (r) => typeof r?.note === "string" && r.note.trim() !== "";

export const hasAcute = (r) => (r?.acuteMedicines?.length ?? 0) > 0;

export function hasInjection(r) {
  if (!r) return false;
  return [...(r.acuteMedicinesAtc ?? []), ...(r.preventiveMedicinesAtc ?? [])].some(isInjectionAtc);
}

export const intensityOf = (r) => Math.max(0, Math.min(4, Number(r?.intensity) || 0));

// Calendar grid for a month: weeks starting on Monday, null for padding cells
export function monthGrid(year, month) {
  const first = new Date(year, month, 1);
  const lead = (first.getDay() + 6) % 7; // Monday = 0
  const days = new Date(year, month + 1, 0).getDate();
  const cells = [...Array(lead).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
  while (cells.length % 7) cells.push(null);
  return cells;
}

function emptyStats() {
  return {
    attacks: 0,
    minutes: 0,
    intensity: [0, 0, 0, 0, 0],
    migraine: 0,
    aura: 0,
    cluster: 0,
    period: 0,
    acuteDays: 0,
    injectionDays: 0,
    notes: 0, // days with a written note
    registered: 0,
  };
}

function addRecord(stats, r) {
  stats.registered++;
  stats.attacks += Number(r.attacks) || 0;
  stats.minutes += Number(r.durationMinutes) || 0;
  stats.intensity[intensityOf(r)]++;
  if (r.isMigraine) stats.migraine++;
  if (r.hasAura) stats.aura++;
  if (r.hasClusterHeadache) stats.cluster++;
  if (r.hasPeriod) stats.period++;
  if (hasAcute(r)) stats.acuteDays++;
  if (hasInjection(r)) stats.injectionDays++;
  if (hasNote(r)) stats.notes++;
}

export function monthStats(byDate, year, month) {
  const prefix = monthKey(year, month);
  const stats = emptyStats();
  for (const [date, r] of byDate) if (date.startsWith(prefix)) addRecord(stats, r);
  return stats;
}

// Same numbers as monthStats, for `days` days starting at `from` (a Date)
export function rangeStats(byDate, from, days) {
  const stats = emptyStats();
  for (let i = 0; i < days; i++) {
    const d = new Date(from.getFullYear(), from.getMonth(), from.getDate() + i);
    const r = byDate.get(toDateKey(d.getFullYear(), d.getMonth(), d.getDate()));
    if (r) addRecord(stats, r);
  }
  return stats;
}

// ISO 8601 week number (weeks start on Monday, week 1 holds the first Thursday)
export function isoWeek(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 3 - ((d.getUTCDay() + 6) % 7));
  const yearStart = Date.UTC(d.getUTCFullYear(), 0, 1);
  return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
}

// headacheScores is keyed by the first day of the month, e.g. "2026-09-01"
export const monthScore = (patient, year, month) =>
  patient?.headacheScores?.[`${monthKey(year, month)}-01`] ?? null;

export function firstRecordMonth(records = []) {
  let min = null;
  for (const r of records) if (r?.date && (!min || r.date < min)) min = r.date;
  if (!min) return null;
  const [y, m] = min.split("-").map(Number);
  return { year: y, month: m - 1 };
}

export function medicineName(patient, id) {
  const m = patient?.medicines?.find((x) => x.id === id);
  return m?.name ?? String(id);
}

// Intl wants "nb" for Norwegian
export const intlLocale = (locale) => (locale === "no" ? "nb" : locale);

export function formatUnit(locale, value, unit) {
  try {
    return new Intl.NumberFormat(intlLocale(locale), {
      style: "unit",
      unit,
      unitDisplay: "long",
      maximumFractionDigits: 1,
    }).format(value);
  } catch {
    return `${value} ${unit}`;
  }
}

// "3 dager" – Intl says "døgn" for Norwegian, the app says "dag" / "dager"
export const formatDays = (locale, n) =>
  locale === "no" ? `${n} ${n === 1 ? "dag" : "dager"}` : formatUnit(locale, n, "day");

// ---------- Overview helpers for the dashboard sidebar ----------

// Records in the last `days` days, counted back from today (inclusive)
export function recordsInLastDays(byDate, days) {
  const now = new Date();
  const out = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    const r = byDate.get(toDateKey(d.getFullYear(), d.getMonth(), d.getDate()));
    if (r) out.push(r);
  }
  return out;
}

export function periodSummary(records) {
  const headache = records.filter((r) => intensityOf(r) > 0);
  const acute = records.filter(hasAcute);
  return {
    registered: records.length,
    headacheDays: headache.length,
    migraineDays: records.filter((r) => r.isMigraine).length,
    auraDays: records.filter((r) => r.hasAura).length,
    clusterDays: records.filter((r) => r.hasClusterHeadache).length,
    acuteDays: acute.length,
    // effect: 1 = no effect, 2 = moderate, 3 = good (0 = not rated)
    ratedAcuteDays: acute.filter((r) => r.effect > 0).length,
    noEffectDays: acute.filter((r) => r.effect === 1).length,
    headacheOnPeriod: headache.filter((r) => r.hasPeriod).length,
  };
}

export function lastRegistration(records = []) {
  let max = null;
  for (const r of records) if (r?.date && (!max || r.date > max)) max = r.date;
  return max;
}

// HIT-6 entries may be numbers or objects – take the newest score we can find
export function latestHit6(patient) {
  const list = Array.isArray(patient?.hitSix) ? patient.hitSix : [];
  if (!list.length) return null;
  const withDate = list.map((e) =>
    typeof e === "number"
      ? { score: e, date: null }
      : { score: e?.score ?? e?.total ?? e?.value ?? e?.sum ?? null, date: e?.date ?? e?.createdAt ?? null }
  );
  withDate.sort((a, b) => String(b.date ?? "").localeCompare(String(a.date ?? "")));
  const hit = withDate.find((e) => typeof e.score === "number");
  return hit ?? null;
}

// The last `count` months (oldest first) with per-month numbers
export function monthlyOverview(patient, byDate, count = 12) {
  const now = new Date();
  const months = [];
  for (let i = count - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const y = d.getFullYear();
    const m = d.getMonth();
    const s = monthStats(byDate, y, m);
    months.push({
      year: y,
      month: m,
      score: monthScore(patient, y, m),
      levels: s.intensity, // [none, mild, moderate, strong, extreme]
      headacheDays: s.intensity[1] + s.intensity[2] + s.intensity[3] + s.intensity[4],
      migraineDays: s.migraine,
      acuteDays: s.acuteDays,
      registered: s.registered,
    });
  }
  return months;
}

// Topics for the doctor to discuss, derived only from the registrations.
// Each item: { id, titleKey, textKey, values: { n, total }, extraKey? }
export function adviceTopics(patient, byDate) {
  const topics = [];
  const last30 = periodSummary(recordsInLastDays(byDate, 30));
  const last90 = periodSummary(recordsInLastDays(byDate, 90));
  const hasPreventive = (patient?.preventiveMedicines?.length ?? 0) > 0;

  // ICHD-3: acute medication on ≥10 days/month (≥15 for simple analgesics) – flag from 10
  if (last30.acuteDays >= 10) {
    topics.push({ id: "overuse", titleKey: "ADVICE_OVERUSE_TITLE", textKey: "ADVICE_OVERUSE_TEXT", values: { n: last30.acuteDays } });
  }
  if (last30.headacheDays >= 4 && !hasPreventive) {
    topics.push({ id: "preventive", titleKey: "ADVICE_PREVENTIVE_TITLE", textKey: "ADVICE_PREVENTIVE_TEXT", values: { n: last30.headacheDays } });
  }
  if (last90.ratedAcuteDays >= 3 && last90.noEffectDays / last90.ratedAcuteDays >= 0.5) {
    topics.push({
      id: "effect",
      titleKey: "ADVICE_EFFECT_TITLE",
      textKey: "ADVICE_EFFECT_TEXT",
      values: { n: last90.noEffectDays, total: last90.ratedAcuteDays },
    });
  }
  if (last90.headacheDays >= 4 && last90.headacheOnPeriod / last90.headacheDays >= 0.5) {
    topics.push({
      id: "period",
      titleKey: "ADVICE_PERIOD_TITLE",
      textKey: "ADVICE_PERIOD_TEXT",
      values: { n: last90.headacheOnPeriod, total: last90.headacheDays },
    });
  }
  if (last90.auraDays > 0) {
    topics.push({
      id: "aura",
      titleKey: "ADVICE_AURA_TITLE",
      textKey: "ADVICE_AURA_TEXT",
      values: { n: last90.auraDays },
      extraKey: patient?.gender === "female" ? "ADVICE_AURA_FEMALE" : null,
    });
  }
  if (last90.clusterDays > 0) {
    topics.push({ id: "cluster", titleKey: "ADVICE_CLUSTER_TITLE", textKey: "ADVICE_CLUSTER_TEXT", values: { n: last90.clusterDays } });
  }

  // Rising month intensity: last full month vs. the average of the three before it
  const now = new Date();
  const score = (offset) => {
    const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
    return monthScore(patient, d.getFullYear(), d.getMonth());
  };
  const last = score(1);
  const before = [score(2), score(3), score(4)].filter((v) => typeof v === "number");
  if (typeof last === "number" && before.length === 3) {
    const avg = Math.round((before.reduce((a, b) => a + b, 0) / 3) * 10) / 10;
    if (last >= avg * 1.3 && last - avg >= 3) {
      topics.push({ id: "trend", titleKey: "ADVICE_TREND_TITLE", textKey: "ADVICE_TREND_TEXT", values: { n: last, total: avg } });
    }
  }
  return topics;
}

// Replaces {n} / {total} in a translated string
export const fill = (text = "", values = {}) =>
  Object.entries(values).reduce((s, [k, v]) => s.replaceAll(`{${k}}`, String(v)), text);


// ---------- Before / after a reference date (e.g. the start of a treatment) ----------

export const REF_PERIOD_DAYS = 30;
export const REF_PERIOD_COUNT = 3;

const periodRow = (byDate, from, index, today) => {
  const s = rangeStats(byDate, from, REF_PERIOD_DAYS);
  const [, mild, moderate, strong, extreme] = s.intensity;
  const end = new Date(from.getFullYear(), from.getMonth(), from.getDate() + REF_PERIOD_DAYS - 1);
  return {
    index, // -3, -2, -1 before; 1, 2, 3 after
    from,
    end,
    finished: end < today, // the last day is before today
    started: from <= today,
    registered: s.registered,
    mild,
    moderate,
    strong,
    extreme,
    headache: mild + moderate + strong + extreme,
    modPlus: moderate + strong + extreme, // moderate, strong and extreme
    acute: s.acuteDays,
  };
};

export const REF_VALUES = ["mild", "moderate", "strong", "extreme", "headache", "modPlus", "acute"];

const average = (rows) =>
  rows.length ? Object.fromEntries(REF_VALUES.map((k) => [k, rows.reduce((n, r) => n + r[k], 0) / rows.length])) : null;

// 3 × 30 days before and after `ref` (a Date), the baseline and the change from before to after.
// Baseline = average of the periods before with registrations. Periods after count only when
// they have ended and have registrations. Change = (average after − baseline) / baseline.
export function referenceComparison(byDate, ref) {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day = (offset) => new Date(ref.getFullYear(), ref.getMonth(), ref.getDate() + offset);

  const before = [];
  for (let i = REF_PERIOD_COUNT; i >= 1; i--) before.push(periodRow(byDate, day(-REF_PERIOD_DAYS * i), -i, today));
  const after = [];
  for (let i = 1; i <= REF_PERIOD_COUNT; i++) after.push(periodRow(byDate, day(REF_PERIOD_DAYS * (i - 1)), i, today));

  const counted = (r) => r.registered > 0 && r.finished;
  const baselineRows = before.filter((r) => r.registered > 0);
  const baseline = average(baselineRows);

  // One row per period after the date, each compared with the average before:
  // "Day 0 to 30", "Day 30 to 60", "Day 60 to 90"
  const change = [];
  for (let i = 1; i <= REF_PERIOD_COUNT; i++) {
    const row = after.find((r) => r.index === i && counted(r)); // unfinished or empty period → "–"
    const values = {};
    for (const k of REF_VALUES) {
      values[k] = !row || !baseline || baseline[k] === 0 ? null : (row[k] - baseline[k]) / baseline[k];
    }
    change.push({ first: i, last: i, values, average: row ?? null });
  }

  // Average of all counted periods after the date, and its change from the baseline
  const afterRows = after.filter(counted);
  const afterAverage = average(afterRows);
  let averageChange = null;
  if (afterAverage && baseline) {
    averageChange = {};
    for (const k of REF_VALUES) {
      averageChange[k] = baseline[k] === 0 ? null : (afterAverage[k] - baseline[k]) / baseline[k];
    }
  }

  return {
    before,
    after,
    baseline,
    baselineCount: baselineRows.length,
    afterAverage,
    afterCount: afterRows.length,
    averageChange,
    change,
  };
}
PHONE_EOF

echo "Writing src/components/headache/HeadacheLog.js"
cat > "src/components/headache/HeadacheLog.js" <<'PHONE_EOF'
// src/components/headache/HeadacheLog.js
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  EFFECT_KEYS,
  INTENSITY,
  formatDays,
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

// Duration as the app registers it: durationType 1 = short attacks (under 3 h, no time stored),
// 2 = long (hours in durationMinutes), 3 = both short and long. "4 timer", "Korte (under 3 timer)", …
function durationText(t, locale, r) {
  const m = Number(r?.durationMinutes) || 0;
  const time =
    m <= 0 ? null : m < 60 ? formatUnit(locale, Math.round(m), "minute") : formatUnit(locale, Math.round((m / 60) * 2) / 2, "hour");
  if (r?.durationType === 1) return t.LOG_DUR_SHORT;
  if (r?.durationType === 3) return time ? `${t.LOG_DUR_SHORT_LONG} · ${time}` : t.LOG_DUR_SHORT_LONG;
  return time;
}

// "3 dager" – Intl writes "døgn" for Norwegian days, which reads oddly here
const daysText = formatDays;

// Doses are only trusted when given as { medicineId, dose } (mg); plain numbers in that list are not reliable
const acuteDose = (r, id) => {
  const d = (r.acuteMedicinesDoses ?? []).find((x) => x && typeof x === "object" && x.medicineId === id);
  return d && Number(d.dose) > 0 ? Number(d.dose) : null;
};
const acuteList = (patient, r) =>
  (r.acuteMedicines ?? []).map((id, i) => {
    const dose = acuteDose(r, id);
    return {
      name: `${medicineName(patient, id)}${dose ? ` ${dose} mg` : ""}`,
      times: (r.acuteMedicinesUsedTimes ?? [])[i] ?? 1,
    };
  });
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
  const duration = durationText(t, locale, r);
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
          {/* Fixed columns, so date, intensity, attacks, duration and tags line up from row to row.
              Phones: date | intensity, then attacks | duration, then the tags */}
          <span className="grid grid-cols-[6.5rem_minmax(0,1fr)] items-center gap-x-3 gap-y-2 md:grid-cols-[7.5rem_7.5rem_4.5rem_12.5rem_minmax(0,1fr)] md:gap-x-4">
            <span>
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

            <span>
              {level > 0 && (
                <>
                  <span className="block text-[10px] font-bold uppercase tracking-wide text-slate-400">{t.CAL_ATTACKS}</span>
                  <span className="block text-sm font-bold text-slate-700">{r.attacks ?? 0}</span>
                </>
              )}
            </span>

            <span className="min-w-0">
              {level > 0 && duration && (
                <>
                  <span className="block text-[10px] font-bold uppercase tracking-wide text-slate-400">{t.CAL_DURATION}</span>
                  <span className="block text-sm font-bold leading-snug text-slate-700">{duration}</span>
                </>
              )}
            </span>

            <span className="col-span-2 flex flex-wrap items-center gap-1.5 empty:hidden md:col-span-1">
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

            {/* Only when the day itself has preventive medication (it is usually stored on the patient) */}
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
  const [showNoHeadache, setShowNoHeadache] = useState(false); // days registered as "no headache" are hidden by default
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
  const shown = records.filter((r) => (showNoHeadache || intensityOf(r) > 0) && matches(r));
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
        level > 0 ? durationText(t, locale, r) ?? "" : "",
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
          value={since === null ? "–" : since === 0 ? t.LOG_TODAY : daysText(locale, since)}
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
          {t.LOG_TIMELINE} · {daysText(locale, TIMELINE_DAYS)}
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

      <label className="flex w-fit cursor-pointer items-center gap-2 px-1 text-sm text-slate-600">
        <input
          type="checkbox"
          checked={showNoHeadache}
          onChange={(e) => {
            setShowNoHeadache(e.target.checked);
            setLimit(PAGE_SIZE);
          }}
          className="h-4 w-4 cursor-pointer rounded border-slate-300 accent-[#6a9be0]"
        />
        {t.LOG_SHOW_NO_HEADACHE}
        <span className="text-xs text-slate-400">({records.filter((r) => intensityOf(r) === 0).length})</span>
      </label>

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
PHONE_EOF

echo "Adding CAL_INJECTIONS to src/components/headache/texts.js"
node - <<'PHONE_EOF'
const fs = require("fs");
const p = "src/components/headache/texts.js";
const INJ = {"ar": "الحقن", "bg": "Инжекции", "bs": "Injekcije", "ca": "Injeccions", "cs": "Injekce", "da": "Injektioner", "de": "Injektionen", "el": "Ενέσεις", "en": "Injections", "es": "Inyecciones", "et": "Süstid", "fi": "Pistokset", "fr": "Injections", "he": "זריקות", "hr": "Injekcije", "hu": "Injekciók", "is": "Sprautur", "it": "Iniezioni", "ja": "注射", "lt": "Injekcijos", "lv": "Injekcijas", "mk": "Инјекции", "nl": "Injecties", "no": "Injeksjoner", "pl": "Zastrzyki", "pt-BR": "Injeções", "pt": "Injeções", "ro": "Injecții", "ru": "Инъекции", "sk": "Injekcie", "sl": "Injekcije", "sr": "Инјекције", "sv": "Injektioner", "tr": "Enjeksiyonlar", "uk": "Ін'єкції"};
let s = fs.readFileSync(p, "utf8");
let n = 0;
s = s.replace(/^  "([A-Za-z-]+)": \{\n(?!    "CAL_INJECTIONS")/gm, (m, lang) => {
  if (!INJ[lang]) return m;
  n++;
  return m + `    "CAL_INJECTIONS": ${JSON.stringify(INJ[lang])},\n`;
});
fs.writeFileSync(p, s);
console.log(`  added to ${n} languages`);
PHONE_EOF

echo "Done. Start with: npm run dev"
