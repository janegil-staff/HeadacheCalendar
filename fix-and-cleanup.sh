#!/usr/bin/env bash
# fix-and-cleanup.sh
# 1) Fixes "Loading…" staying on the START button after closing a patient
# 2) Removes files the project no longer uses
# Run from the project root:  bash fix-and-cleanup.sh
set -euo pipefail

if [ ! -f package.json ] || ! grep -q '"next"' package.json; then
  echo "✗ Run this from the headache_calendar project root." >&2
  exit 1
fi

# ---------- 1. Fix ----------
mkdir -p src/components/landing src/app/dashboard

cat > src/components/landing/CodeCard.js <<'FILE_END'
// src/components/landing/CodeCard.js
"use client";

import { useCallback, useEffect, useState, useTransition } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useLocale } from "@/components/LocaleProvider";

export default function CodeCard() {
  const router = useRouter();
  const pathname = usePathname();
  const { t } = useLocale();
  const [code, setCode] = useState("");
  const [errorKey, setErrorKey] = useState(""); // store the key so it re-translates on language switch
  const [loading, setLoading] = useState(false); // true only while the code is being checked
  const [showHelp, setShowHelp] = useState(false);
  const [isNavigating, startNavigation] = useTransition(); // ends by itself when the dashboard is shown

  const busy = loading || isNavigating;

  const reset = useCallback(() => {
    setCode("");
    setErrorKey("");
    setLoading(false);
    setShowHelp(false);
  }, []);

  // Next can keep this page alive while you're on the dashboard, so start fresh
  // every time the landing page becomes active again…
  useEffect(() => {
    if (pathname === "/") reset();
  }, [pathname, reset]);

  // …and when the browser restores it from its back/forward cache
  useEffect(() => {
    const onPageShow = (e) => e.persisted && reset();
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, [reset]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    const value = code.trim();
    if (busy) return;
    if (!/^\d{6}$/.test(value)) {
      setErrorKey("PATIENT_CODE_INVALID");
      return;
    }

    setLoading(true);
    setErrorKey("");
    try {
      const res = await fetch("/api/patient-access", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code: value }),
      });
      const data = await res.json().catch(() => ({}));

      if (!res.ok || !data.patient) {
        setErrorKey(res.status === 410 ? "PATIENT_CODE_EXPIRED" : "PATIENT_CODE_INVALID");
        setCode("");
        setLoading(false);
        return;
      }

      // The code dies after 10 s, so hand the data to the dashboard via sessionStorage
      try {
        sessionStorage.setItem("patient", JSON.stringify(data.patient));
      } catch {}

      // Never leave the card in "loading": clear it now, and let the transition
      // show "Loading…" only for as long as the navigation itself takes.
      reset();
      startNavigation(() => router.push("/dashboard"));
    } catch {
      setErrorKey("ERROR_NETWORK");
      setLoading(false);
    }
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl border border-white/70 bg-white/80 p-5 shadow-sm backdrop-blur"
    >
      <label htmlFor="patient-code" className="block text-sm font-semibold uppercase tracking-[0.15em] text-gray-900">
        {t.PATIENT_CODE_LABEL}
      </label>

      <input
        id="patient-code"
        type="text"
        inputMode="numeric"
        autoComplete="one-time-code"
        dir="ltr"
        maxLength={6}
        autoFocus
        value={code}
        onChange={(e) => {
          setCode(e.target.value.replace(/\D/g, ""));
          setErrorKey("");
        }}
        placeholder={t.PATIENT_CODE_PLACEHOLDER}
        disabled={busy}
        className="mt-3 w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-start text-gray-900 placeholder:text-gray-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-200 disabled:opacity-60"
      />

      {errorKey && (
        <p role="alert" className="mt-2 text-sm text-red-600">
          {t[errorKey]}
        </p>
      )}

      <button
        type="submit"
        disabled={busy}
        className="mt-4 w-full rounded-lg bg-blue-700 py-3 text-sm font-semibold uppercase tracking-[0.2em] text-white transition hover:bg-blue-800 disabled:bg-blue-400"
      >
        {busy ? t.COMMON_LOADING : t.PATIENT_CODE_START}
      </button>

      <button
        type="button"
        onClick={() => setShowHelp((v) => !v)}
        aria-expanded={showHelp}
        className="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-700 underline underline-offset-2 hover:text-blue-800"
      >
        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
          <circle cx="12" cy="12" r="9" />
          <path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5v.4M12 17h.01" />
        </svg>
        {t.PATIENT_CODE_HELP_LINK}
      </button>

      {showHelp && (
        <p className="mt-2 text-sm leading-relaxed text-gray-600">{t.PATIENT_CODE_HELP_TEXT}</p>
      )}
    </form>
  );
}
FILE_END

cat > src/app/dashboard/page.js <<'FILE_END'
// src/app/dashboard/page.js
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function DashboardPage() {
  const router = useRouter();
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

  return (
    <main className="min-h-screen bg-gray-50 px-4 py-8">
      <div className="mx-auto max-w-5xl">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="font-serif text-3xl font-bold text-blue-800">Dashboard</h1>
          <button
            type="button"
            onClick={close}
            className="rounded-lg border border-blue-700 px-4 py-2 text-sm font-semibold text-blue-700 hover:bg-blue-50"
          >
            Lukk pasient
          </button>
        </div>

        {/* Temporary raw view until the response shape is known */}
        <pre className="overflow-x-auto rounded-2xl bg-white p-6 text-sm text-gray-800 shadow-sm">
          {JSON.stringify(patient, null, 2)}
        </pre>
      </div>
    </main>
  );
}
FILE_END

echo "✓ Updated src/components/landing/CodeCard.js"
echo "✓ Updated src/app/dashboard/page.js"

# ---------- 2. Cleanup ----------
removed=0
remove() {
  if [ -e "$1" ]; then rm -rf "$1"; echo "  − $1"; removed=$((removed + 1)); fi
}
# Only delete a component if nothing in src/ imports it anymore
remove_if_unused() {
  local file="$1" name
  [ -f "$file" ] || return 0
  name="$(basename "$file" .js)"
  if grep -rqE "from ['\"][^'\"]*/${name}['\"]" src --include='*.js' --include='*.jsx' --exclude="$(basename "$file")"; then
    echo "  ! kept $file (still imported somewhere)"
  else
    remove "$file"
  fi
}

echo "Removing unused files:"
remove src/app/patients/open/page.js
rmdir src/app/patients/open src/app/patients 2>/dev/null || true
remove_if_unused src/components/PatientCodeInput.js
remove_if_unused src/components/landing/InfoAccordion.js
remove_if_unused src/components/landing/PhoneMockup.js

# Default Next.js template images, only if nothing references them
for svg in next vercel file globe window; do
  f="public/$svg.svg"
  [ -f "$f" ] || continue
  if grep -rq "/$svg.svg" src 2>/dev/null; then
    echo "  ! kept $f (still referenced)"
  else
    remove "$f"
  fi
done

# Backups and helper files from earlier steps
for d in .i18n-backup-* .fix-backup-*; do [ -e "$d" ] && remove "$d"; done
for f in apply-i18n.sh fix-loading-state.sh headache-i18n.zip locales.zip gen_locales.py; do remove "$f"; done

[ "$removed" -eq 0 ] && echo "  (nothing to remove)"
echo "Done. Restart the dev server (npm run dev) and hard-refresh the page (Cmd+Shift+R)."
echo "You can delete this script afterwards: rm fix-and-cleanup.sh"
