// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import LanguagePicker from "@/components/landing/LanguagePicker";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 py-20">
      <Background />

      <div className="absolute end-4 top-4 sm:end-6 sm:top-6">
        <LanguagePicker />
      </div>

      <div className="w-full max-w-md">
        <h1 className="mb-8 text-center font-serif text-4xl font-bold text-blue-800 sm:text-5xl">
          {t.LANDING_TITLE}
        </h1>

        <CodeCard />
      </div>
    </main>
  );
}
