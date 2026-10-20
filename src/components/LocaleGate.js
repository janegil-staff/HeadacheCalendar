// src/components/LocaleGate.js
import { cookies, headers } from "next/headers";
import LocaleProvider from "@/components/LocaleProvider";
import { LOCALE_COOKIE, matchAcceptLanguage, normalizeLocale } from "@/lib/i18n";

export default async function LocaleGate({ children }) {
  // Saved choice first, then the browser's language, then Norwegian
  // (old short codes like "no" or "sv" in the cookie are mapped to "nb-NO" / "sv-SE")
  const saved = normalizeLocale((await cookies()).get(LOCALE_COOKIE)?.value);
  const locale = saved ?? matchAcceptLanguage((await headers()).get("accept-language") ?? "");

  return <LocaleProvider initialLocale={locale}>{children}</LocaleProvider>;
}
