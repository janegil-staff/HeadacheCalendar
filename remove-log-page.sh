#!/usr/bin/env bash
# remove-log-page.sh
# Dashboard:
#  - removes the log page (src/app/dashboard/log/) – the log is now opened with the
#    "Show log" button in the summary card (log-modal.sh)
#  - removes the "Calendar" / "Log" links under the dashboard's top bar
#  - the top bar itself (patient, title, close button) is unchanged
#  - safe to run again
# Run from the project root:  bash remove-log-page.sh
set -euo pipefail

if [ ! -f src/components/headache/DashboardHeader.js ]; then
  echo "✗ src/components/headache/DashboardHeader.js not found – run this from the project root." >&2
  exit 1
fi

if [ ! -f src/components/headache/LogModal.js ]; then
  echo "! src/components/headache/LogModal.js not found – run log-modal.sh too, or the log can't be opened anywhere." >&2
fi

if [ -d src/app/dashboard/log ]; then
  rm -rf src/app/dashboard/log
  echo "✓ removed src/app/dashboard/log/"
else
  echo "✓ src/app/dashboard/log/ already removed"
fi

cat > src/components/headache/DashboardHeader.js <<'FILE_END'
// src/components/headache/DashboardHeader.js
"use client";

import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { useLocale } from "@/components/LocaleProvider";
import { fill, formatUnit } from "@/components/headache/data";

const GENDER_KEYS = { female: "GENDER_FEMALE", male: "GENDER_MALE" };

// Top bar: patient, title, close
export default function DashboardHeader({ patient, onClose }) {
  const { t, locale } = useHeadacheText();
  const { t: siteText } = useLocale();

  const gender = t[GENDER_KEYS[patient.gender]] ?? (patient.gender ? t.GENDER_OTHER : "");
  const who = [patient.age ? formatUnit(locale, patient.age, "year") : null, gender].filter(Boolean).join(" · ");

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
    </header>
  );
}
FILE_END
echo "✓ src/components/headache/DashboardHeader.js (Calendar / Log links removed)"
