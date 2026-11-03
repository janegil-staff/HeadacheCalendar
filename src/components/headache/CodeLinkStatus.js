// src/components/headache/CodeLinkStatus.js
"use client";

import Link from "next/link";
import { useLocale } from "@/components/LocaleProvider";

// Loading spinner and error card for the /[lang]/blinded and /[lang]/screening links
export default function CodeLinkStatus({ errorKey }) {
  const { t, dir, locale } = useLocale();

  return (
    <main dir={dir} lang={locale} className="flex min-h-screen items-center justify-center p-6">
      {errorKey ? (
        <div className="w-full max-w-md rounded-2xl border border-white/70 bg-white/85 p-8 text-center shadow-sm backdrop-blur">
          <h1 className="font-serif text-2xl font-bold text-[#4f7cc0]">{t.HEADACHE_DIARY}</h1>
          <p role="alert" className="mt-3 text-sm leading-relaxed text-slate-600">
            {t[errorKey]}
          </p>
          <Link
            href="/"
            className="mt-6 inline-block rounded-full bg-[#6a9be0] px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
          >
            {t.CLOSE}
          </Link>
        </div>
      ) : (
        <div
          role="status"
          aria-label={t.COMMON_LOADING}
          className="h-8 w-8 animate-spin rounded-full border-[3px] border-[#6a9be0]/25 border-t-[#6a9be0] motion-reduce:animate-none"
        />
      )}
    </main>
  );
}
