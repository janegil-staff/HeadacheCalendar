// src/components/landing/AboutAppModal.js
"use client";

import { useEffect, useRef, useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { DEFAULT_LOCALE, getImageFolder } from "@/lib/i18n";

export const ABOUT_PAGE_COUNT = 9;
const FALLBACK_IMAGE_LOCALE = DEFAULT_LOCALE;

const imageSrc = (locale, page) => `/images/about-app/${getImageFolder(locale)}/${String(page).padStart(2, "0")}.webp`;

export default function AboutAppModal({ open, onClose }) {
  const { t, locale, dir } = useLocale();
  const [page, setPage] = useState(1);
  const dialogRef = useRef(null);
  const closeRef = useRef(null);

  const isFirst = page === 1;
  const isLast = page === ABOUT_PAGE_COUNT;
  const next = () => setPage((p) => Math.min(p + 1, ABOUT_PAGE_COUNT));
  const prev = () => setPage((p) => Math.max(p - 1, 1));

  // Start on page 1 every time it opens; lock page scroll while open
  useEffect(() => {
    if (!open) return;
    setPage(1);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [open]);

  // Esc closes, arrow keys flip pages (mirrored for right-to-left languages)
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => {
      if (e.key === "Escape") onClose();
      const forward = dir === "rtl" ? "ArrowLeft" : "ArrowRight";
      const back = dir === "rtl" ? "ArrowRight" : "ArrowLeft";
      if (e.key === forward) next();
      if (e.key === back) prev();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, dir, onClose]);

  // Preload the next image so flipping feels instant
  useEffect(() => {
    if (!open || isLast) return;
    const img = new Image();
    img.src = imageSrc(locale, page + 1);
  }, [open, page, locale, isLast]);

  if (!open) return null;

  const title = t[`ABOUT_PAGE_${page}_TITLE`];
  const text = t[`ABOUT_PAGE_${page}_TEXT`];
  const stepLabel = (t.ABOUT_STEP_OF ?? "{current} / {total}")
    .replace("{current}", page)
    .replace("{total}", ABOUT_PAGE_COUNT);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 backdrop-blur-sm sm:p-6"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="about-app-title"
        className="flex max-h-full w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 px-5 py-4 sm:px-7">
          <h2 id="about-app-title" className="text-xl font-bold text-blue-900 sm:text-2xl">
            {t.ABOUT_TITLE}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            aria-label={t.ABOUT_CLOSE}
            className="rounded-lg p-2 text-gray-700 transition hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-200"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-5 sm:px-7 sm:py-6">
          <p className="rounded-lg border-s-4 border-blue-700 bg-blue-50 px-4 py-3 text-base font-semibold leading-relaxed text-blue-900 sm:px-5 sm:text-lg">
            {t.ABOUT_INTRO}
          </p>

          <div className="mt-5 grid items-center gap-6 sm:mt-6 sm:grid-cols-[minmax(0,280px)_1fr] sm:gap-10">
            <div className="mx-auto w-full max-w-[280px] rounded-2xl bg-blue-50 p-4">
              <AboutImage key={`${locale}-${page}`} locale={locale} page={page} alt={title} />
            </div>

            <div aria-live="polite">
              <p className="text-sm font-semibold text-blue-700">{stepLabel}</p>
              <h3 className="mt-1 text-xl font-bold text-gray-900 sm:text-2xl">{title}</h3>
              <p className="mt-3 text-base leading-relaxed text-gray-700 sm:text-lg">{text}</p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between gap-3 border-t border-gray-100 px-5 py-4 sm:px-7">
          <div className="w-24 sm:w-28">
            {!isFirst && (
              <button
                type="button"
                onClick={prev}
                className="rounded-lg px-3 py-2 text-sm font-semibold text-blue-800 transition hover:bg-blue-50"
              >
                {t.ABOUT_PREVIOUS}
              </button>
            )}
          </div>

          <div className="flex gap-1.5" role="tablist">
            {Array.from({ length: ABOUT_PAGE_COUNT }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                type="button"
                role="tab"
                aria-selected={n === page}
                aria-label={(t.ABOUT_STEP_OF ?? "{current} / {total}")
                  .replace("{current}", n)
                  .replace("{total}", ABOUT_PAGE_COUNT)}
                onClick={() => setPage(n)}
                className={`h-2.5 rounded-full transition-all ${
                  n === page ? "w-6 bg-blue-700" : "w-2.5 bg-gray-300 hover:bg-gray-400"
                }`}
              />
            ))}
          </div>

          <div className="flex w-24 justify-end sm:w-28">
            <button
              type="button"
              onClick={isLast ? onClose : next}
              className="rounded-lg bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 sm:px-7 sm:text-base"
            >
              {isLast ? t.ABOUT_CLOSE : t.ABOUT_NEXT}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Uses the language's own screenshot, or the Norwegian one if that folder doesn't exist
function AboutImage({ locale, page, alt }) {
  const [src, setSrc] = useState(imageSrc(locale, page));

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt ?? ""}
      onError={() => {
        const fallback = imageSrc(FALLBACK_IMAGE_LOCALE, page);
        if (src !== fallback) setSrc(fallback);
      }}
      className="mx-auto h-auto max-h-[52vh] w-auto rounded-xl object-contain"
    />
  );
}
