// src/components/headache/LogModal.js
"use client";

import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import HeadacheLog from "@/components/headache/HeadacheLog";
import { useHeadacheText } from "@/components/headache/useHeadacheText";

// The log page's content (same component) in a modal over the dashboard
export default function LogModal({ open, onClose, patient }) {
  const { t, locale, dir } = useHeadacheText();
  const closeRef = useRef(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  });

  // Lock page scroll while open, focus the close button, Esc closes
  useEffect(() => {
    if (!open) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e) => e.key === "Escape" && onCloseRef.current();
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  if (!open) return null;

  // Rendered on <body>: the summary card's backdrop blur would otherwise trap a fixed overlay inside the card
  return createPortal(
    <div
      dir={dir}
      lang={locale}
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-2 backdrop-blur-sm sm:p-6"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="log-modal-title"
        className="flex h-full max-h-full w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-[#eef4fc] shadow-2xl"
      >
        <div className="flex items-center justify-between gap-3 border-b border-white/80 bg-white/80 px-4 py-3 sm:px-6">
          <h2 id="log-modal-title" className="font-serif text-xl font-bold text-[#4f7cc0] sm:text-2xl">
            {t.LOG_TITLE}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            aria-label={t.ABOUT_CLOSE}
            title={t.ABOUT_CLOSE}
            className="rounded-lg p-2 text-slate-600 transition hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain px-3 py-4 sm:px-6 sm:py-6">
          <HeadacheLog patient={patient} />
        </div>
      </div>
    </div>,
    document.body
  );
}
