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
