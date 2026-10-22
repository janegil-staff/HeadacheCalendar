// src/components/landing/CodeHelpModal.js
"use client";

import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useLocale } from "@/components/LocaleProvider";
import { getImageFolder } from "@/lib/i18n";

// A language can have its own screenshots in /images/about-app/<folder>/code-1.webp …;
// otherwise the shared ones in /images/code-help/ are used
const sources = (locale, n) => [`/images/about-app/${getImageFolder(locale)}/code-${n}.webp`, `/images/code-help/code-${n}.webp`];

// "Open the {app} app and tap {share}." → text with the placeholders in bold
function Rich({ text, values }) {
  const parts = String(text ?? "").split(/(\{\w+\})/);
  return parts.map((part, i) => {
    const key = part.match(/^\{(\w+)\}$/)?.[1];
    if (!key || values[key] === undefined) return part;
    return (
      <strong key={i} className="font-semibold text-blue-800">
        {values[key]}
      </strong>
    );
  });
}

function Step({ n, children }) {
  return (
    <div className="flex items-start gap-4">
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-700 text-base font-bold text-white">
        {n}
      </span>
      <p className="pt-1 text-base leading-relaxed text-gray-800 sm:text-lg">{children}</p>
    </div>
  );
}

function Screenshot({ locale, n, alt }) {
  const [index, setIndex] = useState(0);
  const list = sources(locale, n);
  if (index >= list.length) return null;
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={list[index]}
      alt={alt}
      onError={() => setIndex((i) => i + 1)}
      className="mx-auto h-auto max-h-[52vh] w-auto max-w-full rounded-[1.75rem] border border-gray-200 bg-white object-contain shadow-[0_12px_30px_-12px_rgba(30,64,175,0.35)]"
    />
  );
}

export default function CodeHelpModal({ open, onClose }) {
  const { t, locale, dir } = useLocale();
  const closeRef = useRef(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  });

  // Lock page scroll, focus the close button, Esc closes
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

  const values = { app: t.HEADACHE_DIARY, share: t.SHARE_DATA, start: t.PATIENT_CODE_START };

  // On <body>: the code card's backdrop blur would otherwise trap a fixed overlay inside the card
  return createPortal(
    <div
      dir={dir}
      lang={locale}
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-3 backdrop-blur-sm sm:p-6"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="code-help-title"
        className="flex max-h-full w-full max-w-3xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
      >
        {/* Header */}
        <div className="flex items-center justify-between gap-4 border-b border-gray-100 px-5 py-4 sm:px-7 sm:py-5">
          <h2 id="code-help-title" className="text-xl font-bold text-blue-900 sm:text-2xl">
            {t.CODE_HELP_TITLE}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            aria-label={t.ABOUT_CLOSE}
            className="rounded-lg p-2 text-gray-700 transition hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-200"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>

        {/* Body: steps 1 and 2 with their screenshot, step 3 under both */}
        <div className="flex-1 overflow-y-auto overscroll-contain px-5 py-6 sm:px-7">
          <div className="grid gap-8 sm:grid-cols-2 sm:gap-10">
            <div className="flex flex-col gap-5">
              <Step n={1}>
                <Rich text={t.CODE_HELP_STEP_1} values={values} />
              </Step>
              <Screenshot locale={locale} n={1} alt={t.SHARE_DATA ?? ""} />
            </div>
            <div className="flex flex-col gap-5">
              <Step n={2}>
                <Rich text={t.CODE_HELP_STEP_2} values={values} />
              </Step>
              <Screenshot locale={locale} n={2} alt={t.PATIENT_CODE_LABEL ?? ""} />
            </div>
          </div>

          <div className="mt-8">
            <Step n={3}>
              <Rich text={t.CODE_HELP_STEP_3} values={values} />
            </Step>
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-end border-t border-gray-100 px-5 py-4 sm:px-7">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg bg-blue-700 px-8 py-3 text-base font-semibold text-white transition hover:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-blue-200"
          >
            {t.ABOUT_CLOSE}
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
