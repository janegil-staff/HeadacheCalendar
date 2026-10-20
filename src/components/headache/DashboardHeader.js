// src/components/headache/DashboardHeader.js
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { useLocale } from "@/components/LocaleProvider";
import { fill, formatUnit } from "@/components/headache/data";

const GENDER_KEYS = { female: "GENDER_FEMALE", male: "GENDER_MALE" };

// Top bar (patient, title, close) with the Calendar / Log tabs underneath
export default function DashboardHeader({ patient, onClose }) {
  const { t, locale } = useHeadacheText();
  const { t: siteText } = useLocale();
  const pathname = usePathname();

  const gender = t[GENDER_KEYS[patient.gender]] ?? (patient.gender ? t.GENDER_OTHER : "");
  const who = [patient.age ? formatUnit(locale, patient.age, "year") : null, gender].filter(Boolean).join(" · ");

  const tabs = [
    { href: "/dashboard", label: t.TAB_CALENDAR },
    { href: "/dashboard/log", label: t.LOG_TITLE },
  ];

  return (
    <header className="sticky top-0 z-30 border-b border-white/70 bg-white/80 backdrop-blur">
      <div className="flex w-full items-center justify-between gap-3 px-4 py-3 sm:grid sm:grid-cols-[1fr_auto_1fr] sm:px-6">
        <div className="flex min-w-0 items-center gap-3">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#8db3ea] text-sm font-bold text-white">
            {(gender || "?").charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold text-slate-700">{who}</p>
            <p className="truncate text-xs text-slate-500">{fill(t.DASH_REGISTRATIONS, { n: patient.records?.length ?? 0 })}</p>
          </div>
        </div>
        <h1 className="hidden font-serif text-2xl font-bold text-[#4f7cc0] sm:block">{siteText.HEADACHE_DIARY}</h1>
        <button
          type="button"
          onClick={onClose}
          className="shrink-0 justify-self-end whitespace-nowrap rounded-full bg-[#6a9be0] px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
        >
          {t.DASHBOARD_CLOSE}
        </button>
      </div>

      <nav className="flex gap-1 px-2 sm:px-4" aria-label={siteText.HEADACHE_DIARY}>
        {tabs.map((tab) => {
          const active = pathname === tab.href;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              aria-current={active ? "page" : undefined}
              className={`-mb-px border-b-2 px-3 py-2 text-sm font-semibold transition ${
                active ? "border-[#6a9be0] text-[#4f7cc0]" : "border-transparent text-slate-500 hover:text-slate-700"
              }`}
            >
              {tab.label}
            </Link>
          );
        })}
      </nav>
    </header>
  );
}
