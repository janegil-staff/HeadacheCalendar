// src/components/dashboard/CalendarLegend.js
"use client";

import { useLocale } from "@/components/LocaleProvider";
import { COLORS } from "@/lib/headache";
import { AcuteIcon, AuraIcon, ClusterIcon } from "@/components/dashboard/icons";

function Swatch({ style, className = "" }) {
  return <span className={`inline-block h-5 w-5 shrink-0 rounded-md ${className}`} style={style} />;
}

export default function CalendarLegend() {
  const { t } = useLocale();

  const items = [
    [<Swatch key="0" className="border-2 border-slate-300 bg-white" />, t.CAL_NO_HEADACHE],
    [<Swatch key="1" style={{ backgroundColor: COLORS.mild }} />, t.CAL_MILD],
    [<Swatch key="2" style={{ backgroundColor: COLORS.moderate }} />, t.CAL_MODERATE],
    [<Swatch key="3" style={{ backgroundColor: COLORS.strong }} />, t.CAL_STRONG],
    [<Swatch key="4" style={{ backgroundColor: COLORS.extreme }} />, t.CAL_EXTREME],
    [<Swatch key="p" style={{ backgroundColor: COLORS.period }} className="border border-pink-200" />, t.CAL_PERIOD],
    [<AcuteIcon key="a" size={20} />, t.CAL_ACUTE_MEDICATION],
    [<AuraIcon key="au" size={20} />, t.CAL_AURA],
    [<ClusterIcon key="c" size={20} />, t.CAL_CLUSTER],
    [<Swatch key="n" className="border-2 border-dashed border-slate-200" />, t.CAL_NO_REGISTRATION],
    [<Swatch key="t" style={{ backgroundColor: COLORS.today }} />, t.CAL_TODAY],
  ];

  return (
    <div className="mt-4 border-t border-slate-100 pt-3">
      <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">{t.CAL_LEGEND}</p>
      <ul className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm text-slate-600 sm:grid-cols-3">
        {items.map(([icon, label], i) => (
          <li key={i} className="flex items-center gap-2">
            {icon}
            {label}
          </li>
        ))}
      </ul>
    </div>
  );
}
