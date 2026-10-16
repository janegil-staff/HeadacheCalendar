// src/components/dashboard/MonthSummary.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { INTENSITY, formatUnit, intlLocale } from "@/lib/headache";
import { Card } from "@/components/dashboard/ui";
import {
  AcuteIcon,
  AttacksIcon,
  AuraIcon,
  ClusterIcon,
  FaceIcon,
  HoursIcon,
  InjectionIcon,
  MigraineIcon,
  PeriodIcon,
} from "@/components/dashboard/icons";

function Row({ icon, label, value, muted }) {
  return (
    <div className="grid grid-cols-[28px_1fr_auto] items-center gap-3 border-b border-slate-100 px-5 py-2 last:border-0">
      <span className="flex justify-center">{icon}</span>
      <span className="text-[15px] text-slate-700">{label}</span>
      <span className={`text-[15px] font-semibold tabular-nums ${muted ? "text-slate-400" : "text-blue-700"}`}>{value}</span>
    </div>
  );
}

export default function MonthSummary({ stats, score, year, month }) {
  const { t, locale } = useLocale();
  const [showHelp, setShowHelp] = useState(false);
  const days = (n) => formatUnit(locale, n, "day");
  const hours = Math.round((stats.minutes / 60) * 10) / 10;
  const monthName = new Intl.DateTimeFormat(intlLocale(locale), { month: "long", year: "numeric" }).format(new Date(year, month, 1));

  const dayRow = (icon, label, n) => <Row icon={icon} label={label} value={days(n)} muted={n === 0} />;

  return (
    <Card className="overflow-hidden">
      <div className="flex items-baseline gap-2 border-b border-slate-100 px-5 py-3">
        <h3 className="text-sm font-bold uppercase tracking-[0.14em] text-blue-900">{t.DASH_MONTHLY_SUMMARY}</h3>
        <span className="text-sm text-slate-500">· {monthName}</span>
      </div>

      {/* Month intensity */}
      <div className="flex items-center justify-between gap-3 border-b border-slate-100 bg-blue-50/60 px-5 py-3">
        <span className="flex items-center gap-2 text-[15px] font-medium text-slate-700">
          {t.CAL_MONTH_INTENSITY}
          <button
            type="button"
            onClick={() => setShowHelp((v) => !v)}
            aria-expanded={showHelp}
            aria-label={t.CAL_MONTH_INTENSITY_HELP}
            className="flex h-5 w-5 items-center justify-center rounded-full bg-slate-300 text-xs font-bold text-white hover:bg-slate-400"
          >
            ?
          </button>
        </span>
        <span className="text-2xl font-bold tabular-nums text-slate-800">{score ?? "–"}</span>
      </div>
      {showHelp && <p className="border-b border-slate-100 px-5 py-2 text-sm text-slate-500">{t.CAL_MONTH_INTENSITY_HELP}</p>}

      <Row icon={<AttacksIcon size={22} />} label={t.CAL_ATTACKS} value={stats.attacks} muted={!stats.attacks} />
      <Row icon={<HoursIcon size={22} />} label={t.CAL_HOURS_WITH_HEADACHE} value={formatUnit(locale, hours, "hour")} muted={!hours} />
      {[0, 1, 2, 3, 4].map((level) => (
        <Row
          key={level}
          icon={<FaceIcon face={INTENSITY[level].face} size={22} />}
          label={t[INTENSITY[level].key]}
          value={days(stats.intensity[level])}
          muted={stats.intensity[level] === 0}
        />
      ))}
      {dayRow(<MigraineIcon size={22} />, t.CAL_MIGRAINE, stats.migraine)}
      {dayRow(<AuraIcon size={22} />, t.CAL_AURA, stats.aura)}
      {dayRow(<ClusterIcon size={22} />, t.CAL_CLUSTER, stats.cluster)}
      {dayRow(<PeriodIcon size={22} />, t.CAL_PERIOD, stats.period)}
      {dayRow(<AcuteIcon size={22} />, t.CAL_ACUTE_MEDICATION, stats.acuteDays)}
      {dayRow(<InjectionIcon size={22} />, t.CAL_INJECTIONS, stats.injectionDays)}
    </Card>
  );
}
