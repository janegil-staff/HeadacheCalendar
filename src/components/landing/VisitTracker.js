// src/components/landing/VisitTracker.js
"use client";

import { useEffect, useRef } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { track } from "@/lib/track";

// Counts a visit to the front page in the language shown. Changing language counts the
// visitor in the new language too, but not as a new page view. Renders nothing.
export default function VisitTracker() {
  const { locale } = useLocale();
  const seen = useRef(new Set());

  useEffect(() => {
    if (seen.current.has(locale)) return;
    const pageView = seen.current.size === 0;
    seen.current.add(locale);
    track({ type: "visit", locale, pageView });
  }, [locale]);

  return null;
}
