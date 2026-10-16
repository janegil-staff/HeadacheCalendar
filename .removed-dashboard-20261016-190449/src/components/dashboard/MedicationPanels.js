// src/components/dashboard/MedicationPanels.js
"use client";

import { useMemo } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { intlLocale } from "@/lib/headache";
import { Collapsible } from "@/components/dashboard/ui";
import { AcuteIcon } from "@/components/dashboard/icons";

function Item({ icon, name, detail }) {
  return (
    <li className="flex items-center justify-between gap-3 border-b border-slate-100 py-2 last:border-0">
      <span className="flex items-center gap-2 text-sm font-medium text-slate-800">
        {icon}
        {name}
      </span>
      {detail && <span className="text-end text-xs text-slate-500">{detail}</span>}
    </li>
  );
}

function Subheading({ children }) {
  return <p className="mb-1 mt-3 text-xs font-semibold uppercase tracking-[0.1em] text-slate-500 first:mt-0">{children}</p>;
}

export function MedicationPanel({ patient }) {
  const { t, locale } = useLocale();
  const dateFmt = new Intl.DateTimeFormat(intlLocale(locale), { day: "numeric", month: "short", year: "numeric" });

  // How often and when each acute medicine was used, across all registrations
  const acute = useMemo(() => {
    const use = new Map();
    for (const r of patient.records ?? []) {
      (r.acuteMedicines ?? []).forEach((id, i) => {
        const u = use.get(id) ?? { times: 0, last: null };
        u.times += r.acuteMedicinesUsedTimes?.[i] || 1;
        if (!u.last || r.date > u.last) u.last = r.date;
        use.set(id, u);
      });
    }
    return [...use.entries()]
      .map(([id, u]) => ({ id, name: patient.medicines?.find((m) => m.id === id)?.name ?? String(id), ...u }))
      .sort((a, b) => b.times - a.times);
  }, [patient]);

  const preventive = patient.preventiveMedicines ?? [];
  const fmt = (key) => {
    const [y, m, d] = key.split("-").map(Number);
    return dateFmt.format(new Date(y, m - 1, d));
  };

  return (
    <Collapsible title={t.CAL_MEDICATION} count={preventive.length + acute.length}>
      <Subheading>{t.CAL_PREVENTIVE}</Subheading>
      {preventive.length ? (
        <ul>
          {preventive.map((m, i) => (
            <Item key={i} name={m?.name ?? String(m)} detail={m?.dose ? String(m.dose) : m?.atcCode || null} />
          ))}
        </ul>
      ) : (
        <p className="text-sm text-slate-500">{t.DASH_NONE}</p>
      )}

      <Subheading>{t.CAL_ACUTE_MEDICATION}</Subheading>
      {acute.length ? (
        <ul>
          {acute.map((m) => (
            <Item
              key={m.id}
              icon={<AcuteIcon size={16} />}
              name={m.name}
              detail={`× ${m.times}${m.last ? ` · ${t.DASH_LAST_USED} ${fmt(m.last)}` : ""}`}
            />
          ))}
        </ul>
      ) : (
        <p className="text-sm text-slate-500">{t.DASH_NONE}</p>
      )}
    </Collapsible>
  );
}

export function PreviousMedicationPanel({ patient }) {
  const { t } = useLocale();
  const previous = patient.previousMedicines ?? [];

  return (
    <Collapsible title={t.DASH_PREVIOUS_MEDICATION} count={previous.length}>
      {previous.length ? (
        <ul>
          {previous.map((m, i) => (
            <Item key={i} name={m?.name ?? String(m)} detail={m?.atcCode || null} />
          ))}
        </ul>
      ) : (
        <p className="text-sm text-slate-500">{t.DASH_NONE}</p>
      )}
    </Collapsible>
  );
}
