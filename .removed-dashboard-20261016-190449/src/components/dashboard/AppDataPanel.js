// src/components/dashboard/AppDataPanel.js
"use client";

import { useLocale } from "@/components/LocaleProvider";
import { COLORS, INTENSITY, intlLocale } from "@/lib/headache";
import { Collapsible } from "@/components/dashboard/ui";

const LEVEL_COLORS = [null, COLORS.mild, COLORS.moderate, COLORS.strong, COLORS.extreme];

// Stacked bars: headache days per month, split by intensity
function HeadacheDaysChart({ months, monthLabel }) {
  const { t } = useLocale();
  const max = Math.max(5, ...months.map((m) => m.headacheDays));
  const top = Math.ceil(max / 5) * 5;
  const W = 440;
  const H = 170;
  const padL = 26;
  const padB = 22;
  const plotH = H - padB - 8;
  const step = (W - padL) / months.length;
  const barW = Math.min(22, step * 0.62);
  const y = (v) => 8 + plotH - (v / top) * plotH;

  return (
    <figure>
      <svg viewBox={`0 0 ${W} ${H}`} className="h-auto w-full" role="img" aria-label={t.DASH_HEADACHE_DAYS}>
        {[0, top / 2, top].map((v) => (
          <g key={v}>
            <line x1={padL} x2={W} y1={y(v)} y2={y(v)} stroke="#e2e8f0" strokeWidth="1" />
            <text x={padL - 6} y={y(v) + 4} textAnchor="end" fontSize="10" fill="#64748b">
              {v}
            </text>
          </g>
        ))}
        {months.map((m, i) => {
          const x = padL + i * step + (step - barW) / 2;
          let acc = 0;
          return (
            <g key={i}>
              {[1, 2, 3, 4].map((lvl) => {
                const v = m.levels[lvl];
                if (!v) return null;
                const y0 = y(acc + v);
                const h = y(acc) - y0;
                acc += v;
                return <rect key={lvl} x={x} y={y0} width={barW} height={Math.max(h - 1, 0.5)} rx="2" fill={LEVEL_COLORS[lvl]} />;
              })}
              <text x={x + barW / 2} y={H - 6} textAnchor="middle" fontSize="10" fill="#64748b">
                {monthLabel(m, "narrow")}
              </text>
            </g>
          );
        })}
      </svg>
      <figcaption className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-600">
        {[1, 2, 3, 4].map((lvl) => (
          <span key={lvl} className="inline-flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-sm" style={{ backgroundColor: LEVEL_COLORS[lvl] }} />
            {t[INTENSITY[lvl].key]}
          </span>
        ))}
      </figcaption>
    </figure>
  );
}

export default function AppDataPanel({ months }) {
  const { t, locale } = useLocale();
  const loc = intlLocale(locale);
  const monthLabel = (m, style = "short") =>
    new Intl.DateTimeFormat(loc, style === "narrow" ? { month: "narrow" } : { month: "short", year: "2-digit" }).format(
      new Date(m.year, m.month, 1)
    );

  return (
    <Collapsible title={t.DASH_APP_DATA}>
      <p className="mb-2 text-xs font-semibold uppercase tracking-[0.1em] text-slate-500">
        {t.DASH_HEADACHE_DAYS} · {t.DASH_12_MONTHS}
      </p>
      <HeadacheDaysChart months={months} monthLabel={monthLabel} />

      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[420px] text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-xs uppercase tracking-wide text-slate-500">
              <th className="py-2 text-start font-semibold">{t.DASH_MONTH}</th>
              <th className="py-2 text-end font-semibold">{t.CAL_MONTH_INTENSITY}</th>
              <th className="py-2 text-end font-semibold">{t.DASH_HEADACHE_DAYS}</th>
              <th className="py-2 text-end font-semibold">{t.DASH_MIGRAINE_DAYS}</th>
              <th className="py-2 text-end font-semibold">{t.DASH_ACUTE_DAYS}</th>
            </tr>
          </thead>
          <tbody>
            {[...months].reverse().map((m) => (
              <tr key={`${m.year}-${m.month}`} className="border-b border-slate-100 last:border-0">
                <td className="whitespace-nowrap py-2 capitalize text-slate-700">{monthLabel(m)}</td>
                <td className="py-2 text-end font-semibold text-slate-800 tabular-nums">{m.score ?? "–"}</td>
                <td className="py-2 text-end tabular-nums text-slate-700">{m.registered ? m.headacheDays : "–"}</td>
                <td className="py-2 text-end tabular-nums text-slate-700">{m.registered ? m.migraineDays : "–"}</td>
                <td className={`py-2 text-end tabular-nums ${m.acuteDays >= 10 ? "font-semibold text-red-600" : "text-slate-700"}`}>
                  {m.registered ? m.acuteDays : "–"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Collapsible>
  );
}
