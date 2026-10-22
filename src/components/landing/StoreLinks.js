// src/components/landing/StoreLinks.js
"use client";

import { useLocale } from "@/components/LocaleProvider";

const APP_STORE_URL = "https://apps.apple.com/us/app/hodepinedagboken/id1523651899";
const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=com.doit.headache_app";

function AppleLogo() {
  return (
    <svg viewBox="0 0 384 512" className="h-7 w-7 shrink-0" fill="currentColor" aria-hidden="true">
      <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
    </svg>
  );
}

function GooglePlayLogo() {
  return (
    <svg viewBox="0 0 512 512" className="h-7 w-7 shrink-0" aria-hidden="true">
      <path fill="#00d7fe" d="M48 26c-6 6-9 15-9 27v406c0 12 3 21 9 27l2 2 228-228v-6L50 24z" />
      <path fill="#ffce00" d="M354 335l-76-76v-6l76-76 2 1 90 51c26 15 26 39 0 54l-90 51z" />
      <path fill="#ff3a44" d="M356 334l-78-78L48 486c9 9 23 10 39 1l269-153" />
      <path fill="#00f076" d="M356 178L87 25c-16-9-30-8-39 1l230 230z" />
    </svg>
  );
}

function Badge({ href, logo, top, name }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      dir="ltr"
      className="inline-flex min-w-[10.5rem] items-center gap-3 rounded-xl border border-black bg-black px-4 py-2.5 text-white shadow-sm transition hover:bg-neutral-800 focus:outline-none focus:ring-2 focus:ring-blue-300 focus:ring-offset-2"
    >
      {logo}
      <span className="flex flex-col text-start leading-tight">
        <span className="text-[11px] font-medium">{top}</span>
        <span className="text-lg font-semibold tracking-tight">{name}</span>
      </span>
    </a>
  );
}

// "Available on the App Store and Google Play." + the two store badges
export default function StoreLinks() {
  const { t } = useLocale();

  return (
    <section className="flex flex-col items-center text-center">
      <p className="text-base leading-relaxed text-slate-600">
        {t.STORE_AVAILABLE}
        <br />
        {t.STORE_DOWNLOAD_FREE}
      </p>
      <div className="mt-5 flex flex-wrap justify-center gap-3">
        <Badge href={APP_STORE_URL} logo={<AppleLogo />} top={t.STORE_APPLE_TOP} name="App Store" />
        <Badge href={GOOGLE_PLAY_URL} logo={<GooglePlayLogo />} top={t.STORE_GOOGLE_TOP} name="Google Play" />
      </div>
    </section>
  );
}
