// src/components/LocaleGate.js
import { cookies, headers } from "next/headers";
import LocaleProvider from "@/components/LocaleProvider";
import { isSupported, LOCALE_COOKIE, matchAcceptLanguage } from "@/lib/i18n";

export default async function LocaleGate({ children }) {
  // Saved choice first, then the browser's language, then Norwegian
  const saved = (await cookies()).get(LOCALE_COOKIE)?.value;
  const locale = isSupported(saved)
    ? saved
    : matchAcceptLanguage((await headers()).get("accept-language") ?? "");

  return <LocaleProvider initialLocale={locale}>{children}</LocaleProvider>;
}
