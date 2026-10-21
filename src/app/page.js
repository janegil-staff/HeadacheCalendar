// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import FrontImage from "@/components/landing/FrontImage";
import LanguagePicker from "@/components/landing/LanguagePicker";
import ReadMoreButton from "@/components/landing/ReadMoreButton";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 pb-28 pt-20 lg:pb-28 lg:pt-8">
      <Background />

      {/* Phone/tablet: headline, text, card, read more (no image).
          Desktop (lg+), like kolskalender: headline + text top-left, the image under it with
          "Read more" below, and the code card to the right of the image. */}
      <div className="grid w-full max-w-6xl grid-cols-1 gap-y-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-10 xl:gap-x-14">
        <header className="max-w-2xl text-center lg:col-start-1 lg:row-start-1 lg:text-start">
          <h1 className="font-serif text-4xl font-bold text-blue-800 sm:text-5xl xl:text-6xl">
            {t.HEADACHE_DIARY}
          </h1>
          {t.LANDING_INTRO && (
            <p className="mt-4 text-base leading-relaxed text-slate-700 sm:text-lg xl:text-xl">
              {t.LANDING_INTRO}
            </p>
          )}
        </header>

        {/* Phone/tablet: top corner of the page. Desktop (like kolskalender): top of the right
            column, level with the bottom of the headline, right edge in line with the card */}
        <div className="absolute end-4 top-4 sm:end-6 sm:top-6 lg:static lg:col-start-2 lg:row-start-1 lg:mt-11 lg:self-start lg:justify-self-end xl:mt-14">
          <LanguagePicker />
        </div>

        <FrontImage className="hidden h-auto max-h-[72vh] w-full object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block" />

        <div className="mx-auto w-full max-w-md self-start lg:col-start-2 lg:row-start-2 lg:mx-0 lg:max-w-none">
          <CodeCard />
        </div>

        <div className="flex justify-center lg:col-start-1 lg:row-start-3 lg:justify-start">
          <ReadMoreButton />
        </div>
      </div>
    </main>
  );
}
