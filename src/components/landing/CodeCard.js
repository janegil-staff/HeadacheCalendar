// src/components/landing/CodeCard.js
"use client";

import { useCallback, useEffect, useState, useTransition } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useLocale } from "@/components/LocaleProvider";
import CodeHelpModal from "@/components/landing/CodeHelpModal";

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
        onClick={() => setShowHelp(true)}
        aria-haspopup="dialog"
        className="mt-3 inline-flex items-center gap-1.5 text-sm text-gray-700 underline underline-offset-2 hover:text-blue-800"
      >
        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
          <circle cx="12" cy="12" r="9" />
          <path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5v.4M12 17h.01" />
        </svg>
        {t.PATIENT_CODE_HELP_LINK}
      </button>

      <CodeHelpModal open={showHelp} onClose={() => setShowHelp(false)} />
    </form>
  );
}
