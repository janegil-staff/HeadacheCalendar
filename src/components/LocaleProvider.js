// src/components/LocaleProvider.js
"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { getDictionary, getDir, isSupported, LOCALE_COOKIE } from "@/lib/i18n";

const LocaleContext = createContext(null);

export default function LocaleProvider({ initialLocale, children }) {
  const [locale, setLocaleState] = useState(initialLocale);
  const dir = getDir(locale);

  const setLocale = useCallback((code) => {
    if (!isSupported(code)) return;
    setLocaleState(code);
    document.cookie = `${LOCALE_COOKIE}=${encodeURIComponent(code)}; path=/; max-age=31536000; SameSite=Lax`;
  }, []);

  // Keep <html lang/dir> in sync (the wrapper div below already handles it on first paint)
  useEffect(() => {
    document.documentElement.lang = locale;
    document.documentElement.dir = dir;
  }, [locale, dir]);

  const value = useMemo(
    () => ({ locale, setLocale, t: getDictionary(locale), dir }),
    [locale, setLocale, dir]
  );

  return (
    <LocaleContext.Provider value={value}>
      {/* display:contents → no layout impact, but lang/dir apply from the first render */}
      <div lang={locale} dir={dir} style={{ display: "contents" }}>
        {children}
      </div>
    </LocaleContext.Provider>
  );
}

export function useLocale() {
  const ctx = useContext(LocaleContext);
  if (!ctx) throw new Error("useLocale must be used inside <LocaleProvider>");
  return ctx;
}
