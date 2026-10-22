// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import FrontImage from "@/components/landing/FrontImage";
import LanguagePicker from "@/components/landing/LanguagePicker";
import ReadMoreButton from "@/components/landing/ReadMoreButton";
import StoreLinks from "@/components/landing/StoreLinks";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 pb-28 pt-20 lg:pb-28 lg:pt-8">
      <Background />

      {/* Phone/tablet: headline, text, card, read more (no image).
          Desktop (lg+), like kolskalender: headline + text top-left, the image under it with
          "Read more" below, and the code card to the right of the image. */}
      <div className="grid w-full max-w-6xl grid-cols-1 gap-y-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-6 xl:gap-x-8">
        <header className="max-w-2xl text-center lg:col-start-1 lg:row-start-1 lg:w-[75%] lg:max-w-none lg:justify-self-end lg:text-start">
          <h1 className="font-serif text-4xl font-bold text-blue-800 sm:text-5xl">
            {t.HEADACHE_DIARY}
          </h1>
          {t.LANDING_INTRO && (
            <p className="mt-4 text-base leading-relaxed text-slate-700 sm:text-lg">
              {t.LANDING_INTRO}
            </p>
          )}
        </header>

        {/* Phone/tablet: top corner of the page. Desktop (like kolskalender): top of the right
            column, level with the bottom of the headline, right edge in line with the card */}
        <div className="absolute end-4 top-4 sm:end-6 sm:top-6 lg:static lg:col-start-2 lg:row-start-1 lg:mt-11 lg:self-start lg:justify-self-end">
          <LanguagePicker />
        </div>

        <FrontImage className="hidden h-auto w-[75%] drop-shadow-2xl lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-end" />

        <div className="mx-auto w-full max-w-md self-start lg:col-start-2 lg:row-start-2 lg:mx-0 lg:max-w-none">
          <CodeCard />
        </div>

        <div className="flex flex-col items-center lg:col-start-1 lg:row-start-3 lg:w-[75%] lg:items-start lg:justify-self-end">
          <ReadMoreButton />
          {t.LANDING_DISCLAIMER && (
            <p className="mt-4 max-w-2xl text-center text-[13px] italic leading-relaxed text-slate-600 lg:text-start">
              {t.LANDING_DISCLAIMER}
            </p>
          )}
        </div>

        {/* App Store / Google Play, centred under everything */}
        <div className="mt-6 lg:col-span-2 lg:row-start-4">
          <StoreLinks />
        </div>

        {/* Copyright and contact, centred at the very bottom */}
        <footer className="mt-2 text-center text-sm leading-relaxed text-slate-600 lg:col-span-2 lg:row-start-5">
          <p>Copyright {new Date().getFullYear()} - KBB Medic AS (org: 912 372 022)</p>
          <p>
            <a href="mailto:post@kbbmedic.com" className="hover:text-blue-800 hover:underline">
              <span aria-hidden="true">✉</span> post@kbbmedic.com
            </a>
          </p>
        </footer>
      </div>
    </main>
  );
}
