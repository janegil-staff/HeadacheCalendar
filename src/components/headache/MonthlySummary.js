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
  NoteIcon,
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
        {/* Days with a written note – only when the patient shares notes, like in the calendar */}
        <Row icon={<NoteIcon size={18} />} label={t.CAL_NOTES} value={patient?.shareNotes ? s.notes : null} />
        {s.registered === 0 && <li className="px-4 py-3 text-sm italic text-slate-400">{t.CAL_NO_REGISTRATION}</li>}
      </ul>
    </section>
  );
}
