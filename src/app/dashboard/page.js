// src/app/dashboard/page.js
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import CalendarCard from "@/components/headache/CalendarCard";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { useLocale } from "@/components/LocaleProvider";
import { fill, formatUnit } from "@/components/headache/data";

const GENDER_KEYS = { female: "GENDER_FEMALE", male: "GENDER_MALE" };

export default function DashboardPage() {
  const router = useRouter();
  const { t, locale, dir } = useHeadacheText();
  const { t: siteText } = useLocale();
  const [patient, setPatient] = useState(null);

  useEffect(() => {
    let stored = null;
    try {
      stored = JSON.parse(sessionStorage.getItem("patient"));
    } catch {}
    if (!stored) {
      router.replace("/"); // no valid code used → back to landing
      return;
    }
    setPatient(stored);
  }, [router]);

  const close = () => {
    try {
      sessionStorage.removeItem("patient");
    } catch {}
    router.replace("/"); // replace: Back shouldn't return to a closed patient
  };

  if (!patient) return null;

  const gender = t[GENDER_KEYS[patient.gender]] ?? (patient.gender ? t.GENDER_OTHER : "");
  const who = [patient.age ? formatUnit(locale, patient.age, "year") : null, gender].filter(Boolean).join(" · ");

  return (
    <div dir={dir} lang={locale} className="min-h-screen pb-12">
      {/* Top bar */}
      <header className="border-b border-white/70 bg-white/70 backdrop-blur">
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
            onClick={close}
            className="shrink-0 justify-self-end whitespace-nowrap rounded-full bg-[#6a9be0] px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
          >
            {t.DASHBOARD_CLOSE}
          </button>
        </div>
      </header>

      <main className="mx-auto mt-6 max-w-md px-4">
        <CalendarCard patient={patient} />
      </main>
    </div>
  );
}
