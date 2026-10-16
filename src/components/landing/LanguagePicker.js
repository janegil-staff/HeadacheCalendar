// src/components/landing/LanguagePicker.js
"use client";

import { useLocale } from "@/components/LocaleProvider";
import { LANGUAGES } from "@/lib/i18n";

const SORTED = [...LANGUAGES].sort((a, b) => a.name.localeCompare(b.name, "en"));

export default function LanguagePicker() {
  const { locale, setLocale, t } = useLocale();

  return (
    <select
      value={locale}
      onChange={(e) => setLocale(e.target.value)}
      aria-label={t.COMMON_LANGUAGE}
      className="w-52 rounded-md border border-white bg-white px-3 py-2 text-sm text-gray-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-200"
    >
      {SORTED.map((l) => (
        <option key={l.code} value={l.code}>
          {l.flag ? `${l.flag}  ` : ""}
          {l.name}
        </option>
      ))}
    </select>
  );
}
