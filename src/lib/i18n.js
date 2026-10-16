// src/lib/i18n.js
import ar from "@/locales/ar.json";
import bg from "@/locales/bg.json";
import bs from "@/locales/bs.json";
import ca from "@/locales/ca.json";
import cs from "@/locales/cs.json";
import da from "@/locales/da.json";
import de from "@/locales/de.json";
import el from "@/locales/el.json";
import en from "@/locales/en.json";
import es from "@/locales/es.json";
import et from "@/locales/et.json";
import fi from "@/locales/fi.json";
import fr from "@/locales/fr.json";
import he from "@/locales/he.json";
import hr from "@/locales/hr.json";
import hu from "@/locales/hu.json";
import is from "@/locales/is.json";
import it from "@/locales/it.json";
import ja from "@/locales/ja.json";
import lt from "@/locales/lt.json";
import lv from "@/locales/lv.json";
import mk from "@/locales/mk.json";
import nl from "@/locales/nl.json";
import no from "@/locales/no.json";
import pl from "@/locales/pl.json";
import pt from "@/locales/pt.json";
import ptBR from "@/locales/pt-BR.json";
import ro from "@/locales/ro.json";
import ru from "@/locales/ru.json";
import sk from "@/locales/sk.json";
import sl from "@/locales/sl.json";
import sr from "@/locales/sr.json";
import sv from "@/locales/sv.json";
import tr from "@/locales/tr.json";
import uk from "@/locales/uk.json";

export const DEFAULT_LOCALE = "no";
export const LOCALE_COOKIE = "locale";

export const DICTIONARIES = {
  ar, bg, bs, ca, cs, da, de, el, en, es, et, fi, fr, he, hr, hu, is, it, ja,
  lt, lv, mk, nl, no, pl, pt, "pt-BR": ptBR, ro, ru, sk, sl, sr, sv, tr, uk,
};

// Shown in the language picker, sorted by native name at render time
export const LANGUAGES = [
  { code: "ar", name: "العربية", flag: "🇸🇦", dir: "rtl" },
  { code: "bg", name: "Български", flag: "🇧🇬" },
  { code: "bs", name: "Bosanski", flag: "🇧🇦" },
  { code: "ca", name: "Català", flag: "" },
  { code: "cs", name: "Čeština", flag: "🇨🇿" },
  { code: "da", name: "Dansk", flag: "🇩🇰" },
  { code: "de", name: "Deutsch", flag: "🇩🇪" },
  { code: "el", name: "Ελληνικά", flag: "🇬🇷" },
  { code: "en", name: "English", flag: "🇬🇧" },
  { code: "es", name: "Español", flag: "🇪🇸" },
  { code: "et", name: "Eesti", flag: "🇪🇪" },
  { code: "fi", name: "Suomi", flag: "🇫🇮" },
  { code: "fr", name: "Français", flag: "🇫🇷" },
  { code: "he", name: "עברית", flag: "🇮🇱", dir: "rtl" },
  { code: "hr", name: "Hrvatski", flag: "🇭🇷" },
  { code: "hu", name: "Magyar", flag: "🇭🇺" },
  { code: "is", name: "Íslenska", flag: "🇮🇸" },
  { code: "it", name: "Italiano", flag: "🇮🇹" },
  { code: "ja", name: "日本語", flag: "🇯🇵" },
  { code: "lt", name: "Lietuvių", flag: "🇱🇹" },
  { code: "lv", name: "Latviešu", flag: "🇱🇻" },
  { code: "mk", name: "Македонски", flag: "🇲🇰" },
  { code: "nl", name: "Nederlands", flag: "🇳🇱" },
  { code: "no", name: "Norsk", flag: "🇳🇴" },
  { code: "pl", name: "Polski", flag: "🇵🇱" },
  { code: "pt", name: "Português", flag: "🇵🇹" },
  { code: "pt-BR", name: "Português (Brasil)", flag: "🇧🇷" },
  { code: "ro", name: "Română", flag: "🇷🇴" },
  { code: "ru", name: "Русский", flag: "🇷🇺" },
  { code: "sk", name: "Slovenčina", flag: "🇸🇰" },
  { code: "sl", name: "Slovenščina", flag: "🇸🇮" },
  { code: "sr", name: "Српски", flag: "🇷🇸" },
  { code: "sv", name: "Svenska", flag: "🇸🇪" },
  { code: "tr", name: "Türkçe", flag: "🇹🇷" },
  { code: "uk", name: "Українська", flag: "🇺🇦" },
];

export const isSupported = (code) => Object.hasOwn(DICTIONARIES, code ?? "");

export const getDir = (code) =>
  LANGUAGES.find((l) => l.code === code)?.dir ?? "ltr";

// Missing keys fall back to Norwegian
export const getDictionary = (code) => ({
  ...DICTIONARIES[DEFAULT_LOCALE],
  ...(DICTIONARIES[code] ?? {}),
});

// Picks the best supported locale from an Accept-Language header
export function matchAcceptLanguage(header = "") {
  const wanted = header
    .split(",")
    .map((part) => part.split(";")[0].trim())
    .filter(Boolean);

  for (const tag of wanted) {
    const lower = tag.toLowerCase();
    if (lower === "pt-br") return "pt-BR";
    if (["nb", "nn", "no"].includes(lower.split("-")[0])) return "no";
    const base = lower.split("-")[0];
    if (isSupported(base)) return base;
  }
  return DEFAULT_LOCALE;
}
