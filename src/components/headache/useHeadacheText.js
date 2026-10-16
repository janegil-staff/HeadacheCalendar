// src/components/headache/useHeadacheText.js
"use client";

import { useEffect, useState } from "react";
import { TEXTS } from "@/components/headache/texts";

const DEFAULT = "no";
const RTL = new Set(["ar", "he"]);

// Maps codes like "nb-NO", "pt-br", "en-GB" to one of the 35 supported languages
function normalize(code) {
  if (!code) return null;
  const c = String(code).trim();
  if (TEXTS[c]) return c;
  const lower = c.toLowerCase();
  if (lower === "pt-br") return "pt-BR";
  const base = lower.split(/[-_]/)[0];
  if (["nb", "nn", "no"].includes(base)) return "no";
  if (base === "se") return "sv";
  return TEXTS[base] ? base : null;
}

// Uses whatever language the rest of the site has chosen:
// a "locale"/"lang" cookie, a value in localStorage, <html lang>, then the browser
function detectLocale() {
  try {
    const cookie = document.cookie.match(/(?:^|;\s*)(?:locale|lang|language|NEXT_LOCALE)=([^;]+)/);
    const fromCookie = normalize(cookie && decodeURIComponent(cookie[1]));
    if (fromCookie) return fromCookie;
  } catch {}
  try {
    for (const key of ["locale", "language", "lang", "i18nextLng"]) {
      const v = normalize(localStorage.getItem(key)?.replace(/"/g, ""));
      if (v) return v;
    }
  } catch {}
  return normalize(document.documentElement.lang) ?? normalize(navigator.language) ?? DEFAULT;
}

export function useHeadacheText() {
  const [locale, setLocale] = useState(DEFAULT);

  useEffect(() => {
    const update = () => setLocale(detectLocale());
    update();
    // Pick up a language change made elsewhere on the site
    window.addEventListener("focus", update);
    window.addEventListener("storage", update);
    const observer = new MutationObserver(update);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });
    return () => {
      window.removeEventListener("focus", update);
      window.removeEventListener("storage", update);
      observer.disconnect();
    };
  }, []);

  return {
    locale,
    dir: RTL.has(locale) ? "rtl" : "ltr",
    t: { ...TEXTS[DEFAULT], ...(TEXTS[locale] ?? {}) },
  };
}
