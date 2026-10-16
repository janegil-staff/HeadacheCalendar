// src/components/landing/ReadMoreButton.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import AboutAppModal from "@/components/landing/AboutAppModal";

export default function ReadMoreButton() {
  const { t } = useLocale();
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-2 rounded-full border-2 border-blue-700 bg-white px-6 py-3 text-lg font-semibold text-blue-800 shadow-sm transition hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-200"
      >
        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <rect x="6" y="2" width="12" height="20" rx="2" />
          <path d="M11 18h2" />
        </svg>
        {t.LANDING_READ_MORE}
      </button>

      <AboutAppModal open={open} onClose={() => setOpen(false)} />
    </>
  );
}
