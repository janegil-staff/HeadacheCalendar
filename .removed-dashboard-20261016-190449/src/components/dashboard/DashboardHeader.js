// src/components/dashboard/DashboardHeader.js
"use client";

import { useLocale } from "@/components/LocaleProvider";
import LanguagePicker from "@/components/landing/LanguagePicker";
import { fill, formatUnit } from "@/lib/headache";

const GENDER_KEYS = { female: "GENDER_FEMALE", male: "GENDER_MALE" };

export default function DashboardHeader({ patient, onClose }) {
  const { t, locale } = useLocale();

  const gender = t[GENDER_KEYS[patient.gender]] ?? (patient.gender ? t.GENDER_OTHER : "");
  const who = [patient.age ? formatUnit(locale, patient.age, "year") : null, gender].filter(Boolean).join(" · ");
  const count = patient.records?.length ?? 0;

  return (
    <header className="sticky top-0 z-20 border-b border-white/60 bg-white/75 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3 sm:grid sm:grid-cols-[1fr_auto_1fr] sm:px-6">
        <div className="flex min-w-0 items-center gap-3">
          <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-700 text-sm font-bold text-white">
            {(gender || "?").charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold text-slate-800">{who}</p>
            <p className="truncate text-xs text-slate-500">{fill(t.DASH_REGISTRATIONS, { n: count })}</p>
          </div>
        </div>

        <h1 className="hidden text-center font-serif text-2xl font-bold text-blue-800 sm:block md:text-3xl">
          {t.LANDING_TITLE}
        </h1>

        <div className="flex items-center justify-end gap-3">
          <div className="hidden md:block">
            <LanguagePicker />
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 whitespace-nowrap rounded-full bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-800 sm:px-5"
          >
            {t.DASHBOARD_CLOSE}
          </button>
        </div>
      </div>
    </header>
  );
}
