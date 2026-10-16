// src/components/headache/MedicationLists.js
"use client";

import { useMemo, useState } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { intlLocale } from "@/components/headache/data";

const PANEL =
  "mt-3 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)]";

// Image of a medicine, if the data has one
const imageOf = (m) => m?.image ?? m?.imageUrl ?? m?.picture ?? m?.photo ?? m?.thumbnail ?? null;

function PillIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" aria-hidden="true">
      <rect x="2.5" y="8" width="19" height="8" rx="4" transform="rotate(-35 12 12)" fill="#e8f0fb" stroke="#6a9be0" strokeWidth="1.4" />
      <path d="M12 6.9 9.3 17" transform="rotate(-35 12 12)" stroke="#6a9be0" strokeWidth="1.4" />
    </svg>
  );
}

function Thumb({ src, name }) {
  const [failed, setFailed] = useState(false);
  return (
    <span className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-slate-100 bg-slate-50">
      {src && !failed ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt={name} className="h-full w-full object-contain" onError={() => setFailed(true)} />
      ) : (
        <PillIcon />
      )}
    </span>
  );
}

function Item({ m, name, detail }) {
  const ingredients = (m?.ingredients ?? []).map((i) => (typeof i === "string" ? i : i?.name)).filter(Boolean);
  return (
    <li className="flex items-center gap-3 px-4 py-2.5">
      <Thumb src={imageOf(m)} name={name} />
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-medium capitalize text-slate-700">{name}</span>
        {(ingredients.length > 0 || m?.atcCode) && (
          <span className="block truncate text-xs text-slate-400">
            {[ingredients.join(", "), m?.atcCode].filter(Boolean).join(" · ")}
          </span>
        )}
      </span>
      {detail && <span className="shrink-0 text-end text-xs text-slate-500">{detail}</span>}
    </li>
  );
}

function Dropdown({ title, count, children }) {
  const [open, setOpen] = useState(false);
  return (
    <section className={PANEL}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="flex w-full items-center gap-3 px-4 py-3 text-start"
      >
        <span className="flex-1 text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{title}</span>
        <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-[#6a9be0] px-1.5 text-[11px] font-bold text-white">
          {count}
        </span>
        <svg
          className={`h-3.5 w-3.5 text-[#6a9be0] transition-transform ${open ? "rotate-180" : ""}`}
          viewBox="0 0 24 24"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M5 8h14l-7 9z" />
        </svg>
      </button>
      {open && <div className="border-t border-slate-100">{children}</div>}
    </section>
  );
}

function Subheading({ children }) {
  return (
    <p className="bg-slate-50/70 px-4 py-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-slate-500">{children}</p>
  );
}

export function MedicationDropdown({ patient }) {
  const { t, locale } = useHeadacheText();
  const dateFmt = new Intl.DateTimeFormat(intlLocale(locale), { day: "numeric", month: "short", year: "numeric" });

  // Acute medicines actually used, with how often and when last
  const acute = useMemo(() => {
    const use = new Map();
    for (const r of patient?.records ?? []) {
      (r.acuteMedicines ?? []).forEach((id, i) => {
        const u = use.get(id) ?? { times: 0, last: null };
        u.times += r.acuteMedicinesUsedTimes?.[i] || 1;
        if (!u.last || r.date > u.last) u.last = r.date;
        use.set(id, u);
      });
    }
    return [...use.entries()]
      .map(([id, u]) => {
        const med = patient?.medicines?.find((m) => m.id === id);
        return { id, med, name: med?.name ?? String(id), ...u };
      })
      .sort((a, b) => b.times - a.times);
  }, [patient]);

  const preventive = patient?.preventiveMedicines ?? [];
  const fmt = (key) => {
    const [y, m, d] = key.split("-").map(Number);
    return dateFmt.format(new Date(y, m - 1, d));
  };

  return (
    <Dropdown title={t.CAL_MEDICATION} count={preventive.length + acute.length}>
      {preventive.length > 0 && (
        <>
          <Subheading>{t.CAL_PREVENTIVE}</Subheading>
          <ul className="divide-y divide-slate-100">
            {preventive.map((m, i) => (
              <Item key={`p${i}`} m={m} name={m?.name ?? String(m)} detail={m?.dose ? String(m.dose) : null} />
            ))}
          </ul>
        </>
      )}
      {acute.length > 0 && (
        <>
          <Subheading>{t.CAL_ACUTE_MEDICATION}</Subheading>
          <ul className="divide-y divide-slate-100">
            {acute.map((a) => (
              <Item
                key={`a${a.id}`}
                m={a.med}
                name={a.name}
                detail={
                  <>
                    <span className="block font-semibold text-slate-600">× {a.times}</span>
                    {a.last && (
                      <span className="block">
                        {t.DASH_LAST_USED} {fmt(a.last)}
                      </span>
                    )}
                  </>
                }
              />
            ))}
          </ul>
        </>
      )}
      {!preventive.length && !acute.length && <p className="px-4 py-3 text-sm italic text-slate-400">{t.DASH_NONE}</p>}
    </Dropdown>
  );
}

export function PreviousMedicationDropdown({ patient }) {
  const { t } = useHeadacheText();
  const previous = patient?.previousMedicines ?? [];

  return (
    <Dropdown title={t.DASH_PREVIOUS_MEDICATION} count={previous.length}>
      {previous.length ? (
        <ul className="divide-y divide-slate-100">
          {previous.map((m, i) => (
            <Item key={i} m={m} name={m?.name ?? String(m)} />
          ))}
        </ul>
      ) : (
        <p className="px-4 py-3 text-sm italic text-slate-400">{t.DASH_NONE}</p>
      )}
    </Dropdown>
  );
}
