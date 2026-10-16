#!/usr/bin/env bash
# intensity-list.sh
# Monthly summary: shows Mild / Moderate / Strong / Extreme as a list under "Headache days".
# Run from the project root:  bash intensity-list.sh
set -euo pipefail

if [ ! -f src/components/headache/MonthlySummary.js ]; then
  echo "✗ src/components/headache/MonthlySummary.js not found – run monthly-summary.sh first." >&2
  exit 1
fi

cat > src/components/headache/MonthlySummary.js <<'FILE_END'
// src/components/headache/MonthlySummary.js
"use client";

import { useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { COLORS, formatUnit, intlLocale, monthScore, monthStats } from "@/components/headache/data";
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
  const zero = value === 0 || value === "0";
  const toneClass = zero
    ? "font-normal italic text-slate-400"
    : tone === "alert"
      ? "font-bold text-red-600"
      : "font-semibold text-slate-700";
  return (
    <li className="flex items-center gap-3 px-4 py-2">
      <span className="flex w-5 shrink-0 justify-center">{icon}</span>
      <span className={`min-w-0 flex-1 text-sm ${tone === "alert" && !zero ? "text-red-600" : "text-slate-700"}`}>{label}</span>
      <span className={`text-sm tabular-nums ${toneClass}`}>{value}</span>
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
  const monthName = new Intl.DateTimeFormat(intlLocale(locale), { month: "long", year: "numeric" }).format(
    new Date(year, month, 1)
  );

  // Intensity breakdown as a list under "Headache days" – also explains the calendar colours
  const breakdown = LEVELS.map(({ level, key, color }) => {
    const n = s.intensity[level];
    return (
      <li key={level} className="flex items-center gap-3 py-1.5 pe-4 ps-12">
        <span className="h-3 w-3 shrink-0 rounded-sm" style={{ backgroundColor: color, opacity: n ? 1 : 0.4 }} />
        <span className={`flex-1 text-[13px] ${n ? "text-slate-600" : "text-slate-400"}`}>{t[key]}</span>
        <span className={`text-[13px] tabular-nums ${n ? "font-semibold text-slate-600" : "italic text-slate-400"}`}>{n}</span>
      </li>
    );
  });

  return (
    <div className="mt-4 overflow-hidden rounded-2xl border border-slate-100 bg-white">
      <div className="flex items-baseline gap-2 border-b border-slate-100 px-4 py-2.5">
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

        <Row icon={<FaceIcon face="moderate" size={18} />} label={t.DASH_HEADACHE_DAYS} value={headacheDays} />
        <li className="bg-slate-50/60">
          <ul className="divide-y divide-slate-100/70">{breakdown}</ul>
        </li>
        <Row icon={<MigraineIcon size={18} />} label={t.CAL_MIGRAINE} value={s.migraine} />
        <Row icon={<AttacksIcon size={18} />} label={t.CAL_ATTACKS} value={s.attacks} />
        <Row icon={<HoursIcon size={18} />} label={t.CAL_HOURS_WITH_HEADACHE} value={hours ? formatUnit(locale, hours, "hour") : 0} />
        <Row
          icon={<AcuteIcon size={18} />}
          label={t.DASH_ACUTE_DAYS}
          value={s.acuteDays}
          tone={s.acuteDays >= 10 ? "alert" : "default"} // ≥10 days/month: risk of medication-overuse headache
        />
        <Row icon={<AuraIcon size={18} />} label={t.CAL_AURA} value={s.aura} />
        <Row icon={<PeriodIcon size={18} />} label={t.CAL_PERIOD} value={s.period} />
        {s.cluster > 0 && <Row icon={<ClusterIcon size={18} />} label={t.CAL_CLUSTER} value={s.cluster} />}
      </ul>
    </div>
  );
}
FILE_END
echo "✓ src/components/headache/MonthlySummary.js"
echo "Done. Reload the page."
