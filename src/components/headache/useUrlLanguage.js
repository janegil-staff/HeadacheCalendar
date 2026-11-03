// src/components/headache/useUrlLanguage.js
"use client";

import { useEffect } from "react";
import { notFound, useParams } from "next/navigation";
import { useLocale } from "@/components/LocaleProvider";
import { normalizeLocale } from "@/lib/i18n";

// The language in links like /no/blinded or /en-US/screening becomes the site language.
// Short codes work too ("no" → nb-NO, "sv" → sv-SE); an unknown one is a 404.
export function useUrlLanguage() {
  const { lang } = useParams();
  const wanted = normalizeLocale(decodeURIComponent(String(lang ?? "")));
  const { locale, setLocale } = useLocale();

  if (!wanted) notFound();

  useEffect(() => {
    if (wanted !== locale) setLocale(wanted);
  }, [wanted, locale, setLocale]);
}
