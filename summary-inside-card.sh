#!/usr/bin/env bash
# summary-inside-card.sh
# Monthly summary as a white card inside the calendar card (like kolskalender),
# without the "Select a day in the calendar…" hint.
# Run from the project root:  bash summary-inside-card.sh
set -euo pipefail

if [ ! -f src/components/headache/MonthlySummary.js ]; then
  echo "✗ src/components/headache/MonthlySummary.js not found – run monthly-summary.sh first." >&2
  exit 1
fi

cat > src/components/headache/CalendarCard.js <<'FILE_END'
// src/components/headache/CalendarCard.js
"use client";

import { useMemo, useState } from "react";
import HeadacheCalendar from "@/components/headache/HeadacheCalendar";
import DayDetails from "@/components/headache/DayDetails";
import MonthlySummary from "@/components/headache/MonthlySummary";
import { firstRecordMonth, indexRecords } from "@/components/headache/data";

// The calendar card: month navigation, day details and the monthly summary card inside it
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
    <section className="rounded-3xl border border-white/70 bg-white/65 p-4 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:px-5 sm:py-5">
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
      />
      <DayDetails
        patient={patient}
        dateKey={selected}
        record={selected ? byDate.get(selected) : null}
        onClose={() => setSelected(null)}
      />

      {/* Monthly summary as a card inside the calendar card, following the month shown */}
      <MonthlySummary patient={patient} byDate={byDate} year={view.year} month={view.month} />
    </section>
  );
}
FILE_END
echo "✓ src/components/headache/CalendarCard.js"
cat > src/components/headache/MonthlySummary.js <<'FILE_END'
// src/components/headache/MonthlySummary.js
"use client";

import { useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, INTENSITY, formatUnit, intlLocale, monthScore, monthStats } from "@/components/headache/data";
import {
  AcuteIcon,
  AttacksIcon,
  AuraIcon,
  ClusterIcon,
  FaceIcon,
  HoursIcon,
  MigraineIcon,
  PeriodIcon,
} from "@/components/headache/icons";

const LEVELS = [
  { level: 1, key: "CAL_MILD", color: COLORS.mild },
  { level: 2, key: "CAL_MODERATE", color: COLORS.moderate },
  { level: 3, key: "CAL_STRONG", color: COLORS.strong },
  { level: 4, key: "CAL_EXTREME", color: COLORS.extreme },
];

function Row({ icon, label, value, tone = "default" }) {
  if (!value || value === "0") return null; // rows with 0 are hidden
  const alert = tone === "alert";
  return (
    <li className="flex items-center gap-3 px-4 py-2">
      <span className="flex w-5 shrink-0 justify-center">{icon}</span>
      <span className={`min-w-0 flex-1 text-sm ${alert ? "text-red-600" : "text-slate-700"}`}>{label}</span>
      <span className={`text-sm tabular-nums ${alert ? "font-bold text-red-600" : "font-semibold text-slate-700"}`}>{value}</span>
    </li>
  );
}

// Monthly numbers under the calendar, in the style of kolskalender's "Monthly summary"
export default function MonthlySummary({ patient, byDate, year, month }) {
  const { t, locale } = useHeadacheText();
  const [showHelp, setShowHelp] = useState(false);

  const s = monthStats(byDate, year, month);
  const score = monthScore(patient, year, month);
  const headacheDays = s.intensity[1] + s.intensity[2] + s.intensity[3] + s.intensity[4];
  const hours = Math.round((s.minutes / 60) * 10) / 10;
  // Average intensity of the headache days (1–4), rounded – decides the smiley's colour and expression
  const avgLevel = headacheDays
    ? Math.min(4, Math.max(1, Math.round((s.intensity[1] + 2 * s.intensity[2] + 3 * s.intensity[3] + 4 * s.intensity[4]) / headacheDays)))
    : 0;
  const monthName = new Intl.DateTimeFormat(intlLocale(locale), { month: "long", year: "numeric" }).format(
    new Date(year, month, 1)
  );

  // Intensity breakdown as a list under "Headache days" (only levels that occurred)
  const breakdown = LEVELS.filter(({ level }) => s.intensity[level] > 0).map(({ level, key, color }) => (
    <li key={level} className="flex items-center gap-3 py-1.5 pe-4 ps-12">
      <span className="h-3 w-3 shrink-0 rounded-sm" style={{ backgroundColor: color }} />
      <span className="flex-1 text-[13px] text-slate-600">{t[key]}</span>
      <span className="text-[13px] font-semibold tabular-nums text-slate-600">{s.intensity[level]}</span>
    </li>
  ));

  return (
    <section className="mt-4 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)]">
      <div className="flex items-baseline gap-2 border-b border-slate-100 px-5 py-3">
        <h3 className="text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{t.DASH_MONTHLY_SUMMARY}</h3>
        <span className="text-xs capitalize text-slate-500">· {monthName}</span>
      </div>

      <ul className="divide-y divide-slate-100">
        <li className="flex items-center gap-3 px-4 py-2">
          <span className="flex w-5 shrink-0 justify-center">
            <span className="h-3.5 w-3.5 rounded-full" style={{ backgroundColor: COLORS.today }} />
          </span>
          <span className="flex flex-1 items-center gap-1.5 text-sm text-slate-700">
            {t.CAL_MONTH_INTENSITY}
            <button
              type="button"
              onClick={() => setShowHelp((v) => !v)}
              aria-expanded={showHelp}
              aria-label={t.CAL_MONTH_INTENSITY_HELP}
              className="flex h-4 w-4 items-center justify-center rounded-full bg-slate-300 text-[10px] font-bold text-white hover:bg-slate-400"
            >
              ?
            </button>
          </span>
          <span className="text-sm font-bold tabular-nums text-slate-800">{score ?? "–"}</span>
        </li>
        {showHelp && <li className="px-4 py-2 text-xs leading-relaxed text-slate-500">{t.CAL_MONTH_INTENSITY_HELP}</li>}

        <Row icon={<FaceIcon face={INTENSITY[avgLevel].face} size={18} />} label={t.DASH_HEADACHE_DAYS} value={headacheDays} />
        {breakdown.length > 0 && (
          <li className="bg-slate-50/60">
            <ul className="divide-y divide-slate-100/70">{breakdown}</ul>
          </li>
        )}
        <Row icon={<MigraineIcon size={18} />} label={t.CAL_MIGRAINE} value={s.migraine} />
        <Row icon={<AttacksIcon size={18} />} label={t.CAL_ATTACKS} value={s.attacks} />
        <Row icon={<HoursIcon size={18} />} label={t.CAL_HOURS_WITH_HEADACHE} value={hours ? formatUnit(locale, hours, "hour") : null} />
        <Row
          icon={<AcuteIcon size={18} />}
          label={t.DASH_ACUTE_DAYS}
          value={s.acuteDays}
          tone={s.acuteDays >= 10 ? "alert" : "default"} // ≥10 days/month: risk of medication-overuse headache
        />
        <Row icon={<AuraIcon size={18} />} label={t.CAL_AURA} value={s.aura} />
        <Row icon={<PeriodIcon size={18} />} label={t.CAL_PERIOD} value={s.period} />
        <Row icon={<ClusterIcon size={18} />} label={t.CAL_CLUSTER} value={s.cluster} />
        {s.registered === 0 && <li className="px-4 py-3 text-sm italic text-slate-400">{t.CAL_NO_REGISTRATION}</li>}
      </ul>
    </section>
  );
}
FILE_END
echo "✓ src/components/headache/MonthlySummary.js"
cat > src/components/headache/DayDetails.js <<'FILE_END'
// src/components/headache/DayDetails.js
"use client";

import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { EFFECT_KEYS, INTENSITY, formatUnit, intensityOf, intlLocale, medicineName } from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, FaceIcon, MigraineIcon, PeriodIcon } from "@/components/headache/icons";

const card = "relative mx-auto mt-3 max-w-sm rounded-xl border border-slate-100 bg-slate-50/80 px-3 py-2.5";

function Line({ label, children }) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b border-slate-100 py-1.5 last:border-0">
      <dt className="text-xs text-slate-500">{label}</dt>
      <dd className="text-end text-xs font-medium text-slate-800">{children}</dd>
    </div>
  );
}

function Chip({ icon, children }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-white py-0.5 pe-2 ps-0.5 text-xs text-slate-700">
      {icon}
      {children}
    </span>
  );
}

// Preventive medicines may come as ids (into patient.medicines) or as names
const preventiveName = (patient, m) => (typeof m === "number" ? medicineName(patient, m) : String(m));

export default function DayDetails({ patient, dateKey, record, onClose }) {
  const { t, locale } = useHeadacheText();

  if (!dateKey) return null; // nothing selected

  const closeButton = onClose && (
    <button
      type="button"
      onClick={onClose}
      aria-label={t.ABOUT_CLOSE}
      className="absolute end-2 top-2 rounded-lg p-1.5 text-slate-500 hover:bg-slate-200"
    >
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.2}>
        <path d="M6 6l12 12M18 6 6 18" />
      </svg>
    </button>
  );

  const [y, m, d] = dateKey.split("-").map(Number);
  const heading = new Intl.DateTimeFormat(intlLocale(locale), {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(y, m - 1, d));

  if (!record) {
    return (
      <div className={card}>
        {closeButton}
        <h3 className="pe-8 text-sm font-semibold capitalize text-slate-800">{heading}</h3>
        <p className="mt-2 text-sm text-slate-500">{t.CAL_NO_REGISTRATION}</p>
      </div>
    );
  }

  const level = intensityOf(record);
  const acute = record.acuteMedicines ?? [];
  const times = record.acuteMedicinesUsedTimes ?? [];
  const preventive = record.preventiveMedicines ?? [];
  const effectKey = EFFECT_KEYS[record.effect];

  return (
    <div className={card}>
      {closeButton}
      <h3 className="pe-8 text-sm font-semibold capitalize text-slate-800">{heading}</h3>

      <div className="mt-1.5 flex items-center gap-2">
        <FaceIcon face={INTENSITY[level].face} size={20} />
        <span className="text-sm font-semibold text-slate-800">{t[INTENSITY[level].key]}</span>
      </div>

      {(record.isMigraine || record.hasAura || record.hasClusterHeadache || record.hasPeriod) && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {record.isMigraine && <Chip icon={<MigraineIcon size={16} />}>{t.CAL_MIGRAINE}</Chip>}
          {record.hasAura && <Chip icon={<AuraIcon size={16} />}>{t.CAL_AURA}</Chip>}
          {record.hasClusterHeadache && <Chip icon={<ClusterIcon size={16} />}>{t.CAL_CLUSTER}</Chip>}
          {record.hasPeriod && <Chip icon={<PeriodIcon size={16} />}>{t.CAL_PERIOD}</Chip>}
        </div>
      )}

      <dl className="mt-1.5">
        {level > 0 && (
          <>
            <Line label={t.CAL_ATTACKS}>{record.attacks ?? 0}</Line>
            {Number(record.durationMinutes) > 0 && (
              <Line label={t.CAL_DURATION}>{formatUnit(locale, record.durationMinutes, "minute")}</Line>
            )}
          </>
        )}

        {acute.length > 0 && (
          <Line label={t.CAL_ACUTE_MEDICATION}>
            <span className="inline-flex flex-col items-end gap-1">
              {acute.map((id, i) => (
                <span key={i} className="inline-flex items-center gap-1.5">
                  <AcuteIcon size={16} />
                  {medicineName(patient, id)}
                  {times[i] > 1 ? ` × ${times[i]}` : ""}
                </span>
              ))}
            </span>
          </Line>
        )}

        {acute.length > 0 && effectKey && <Line label={t.CAL_EFFECT}>{t[effectKey]}</Line>}

        {preventive.length > 0 && (
          <Line label={t.CAL_PREVENTIVE}>{preventive.map((p) => preventiveName(patient, p)).join(", ")}</Line>
        )}

        {patient?.shareNotes && record.note?.trim() && (
          <Line label={t.CAL_NOTE}>
            <span className="whitespace-pre-wrap font-normal">{record.note}</span>
          </Line>
        )}
      </dl>

      {record.wasAddedLater && <p className="mt-3 text-xs text-slate-400">{t.CAL_REGISTERED_LATER}</p>}
    </div>
  );
}
FILE_END
echo "✓ src/components/headache/DayDetails.js"
echo "Done. Reload the page."
