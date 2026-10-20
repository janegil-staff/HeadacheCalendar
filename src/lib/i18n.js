// src/lib/i18n.js
import arSA from "@/locales/ar-SA.json";
import bgBG from "@/locales/bg-BG.json";
import bsBA from "@/locales/bs-BA.json";
import caES from "@/locales/ca-ES.json";
import csCZ from "@/locales/cs-CZ.json";
import daDK from "@/locales/da-DK.json";
import deDE from "@/locales/de-DE.json";
import elGR from "@/locales/el-GR.json";
import enUS from "@/locales/en-US.json";
import esES from "@/locales/es-ES.json";
import etEE from "@/locales/et-EE.json";
import fiFI from "@/locales/fi-FI.json";
import frFR from "@/locales/fr-FR.json";
import heIL from "@/locales/he-IL.json";
import hrHR from "@/locales/hr-HR.json";
import huHU from "@/locales/hu-HU.json";
import isIS from "@/locales/is-IS.json";
import itIT from "@/locales/it-IT.json";
import jaJP from "@/locales/ja-JP.json";
import ltLT from "@/locales/lt-LT.json";
import lvLV from "@/locales/lv-LV.json";
import mkMK from "@/locales/mk-MK.json";
import nbNO from "@/locales/nb-NO.json";
import nlNL from "@/locales/nl-NL.json";
import plPL from "@/locales/pl-PL.json";
import ptBR from "@/locales/pt-BR.json";
import ptPT from "@/locales/pt-PT.json";
import roRO from "@/locales/ro-RO.json";
import ruRU from "@/locales/ru-RU.json";
import skSK from "@/locales/sk-SK.json";
import slSI from "@/locales/sl-SI.json";
import srRS from "@/locales/sr-RS.json";
import svSE from "@/locales/sv-SE.json";
import trTR from "@/locales/tr-TR.json";
import ukUA from "@/locales/uk-UA.json";

export const DEFAULT_LOCALE = "nb-NO";
export const LOCALE_COOKIE = "locale";

export const DICTIONARIES = {
  "ar-SA": arSA, "bg-BG": bgBG, "bs-BA": bsBA, "ca-ES": caES, "cs-CZ": csCZ,
  "da-DK": daDK, "de-DE": deDE, "el-GR": elGR, "en-US": enUS, "es-ES": esES,
  "et-EE": etEE, "fi-FI": fiFI, "fr-FR": frFR, "he-IL": heIL, "hr-HR": hrHR,
  "hu-HU": huHU, "is-IS": isIS, "it-IT": itIT, "ja-JP": jaJP, "lt-LT": ltLT,
  "lv-LV": lvLV, "mk-MK": mkMK, "nb-NO": nbNO, "nl-NL": nlNL, "pl-PL": plPL,
  "pt-BR": ptBR, "pt-PT": ptPT, "ro-RO": roRO, "ru-RU": ruRU, "sk-SK": skSK,
  "sl-SI": slSI, "sr-RS": srRS, "sv-SE": svSE, "tr-TR": trTR, "uk-UA": ukUA,
};

// Shown in the language picker, sorted by native name at render time.
// `images` is the folder under /public/images/about-app/
export const LANGUAGES = [
  { code: "ar-SA", name: "العربية", flag: "🇸🇦", images: "ar", dir: "rtl" },
  { code: "bg-BG", name: "Български", flag: "🇧🇬", images: "bg" },
  { code: "bs-BA", name: "Bosanski", flag: "🇧🇦", images: "bs" },
  { code: "ca-ES", name: "Català", flag: "", images: "ca" },
  { code: "cs-CZ", name: "Čeština", flag: "🇨🇿", images: "cs" },
  { code: "da-DK", name: "Dansk", flag: "🇩🇰", images: "da" },
  { code: "de-DE", name: "Deutsch", flag: "🇩🇪", images: "de" },
  { code: "el-GR", name: "Ελληνικά", flag: "🇬🇷", images: "el" },
  { code: "en-US", name: "English", flag: "🇬🇧", images: "en" },
  { code: "es-ES", name: "Español", flag: "🇪🇸", images: "es" },
  { code: "et-EE", name: "Eesti", flag: "🇪🇪", images: "et" },
  { code: "fi-FI", name: "Suomi", flag: "🇫🇮", images: "fi" },
  { code: "fr-FR", name: "Français", flag: "🇫🇷", images: "fr" },
  { code: "he-IL", name: "עברית", flag: "🇮🇱", images: "he", dir: "rtl" },
  { code: "hr-HR", name: "Hrvatski", flag: "🇭🇷", images: "hr" },
  { code: "hu-HU", name: "Magyar", flag: "🇭🇺", images: "hu" },
  { code: "is-IS", name: "Íslenska", flag: "🇮🇸", images: "is" },
  { code: "it-IT", name: "Italiano", flag: "🇮🇹", images: "it" },
  { code: "ja-JP", name: "日本語", flag: "🇯🇵", images: "ja" },
  { code: "lt-LT", name: "Lietuvių", flag: "🇱🇹", images: "lt" },
  { code: "lv-LV", name: "Latviešu", flag: "🇱🇻", images: "lv" },
  { code: "mk-MK", name: "Македонски", flag: "🇲🇰", images: "mk" },
  { code: "nb-NO", name: "Norsk", flag: "🇳🇴", images: "no" },
  { code: "nl-NL", name: "Nederlands", flag: "🇳🇱", images: "nl" },
  { code: "pl-PL", name: "Polski", flag: "🇵🇱", images: "pl" },
  { code: "pt-BR", name: "Português (Brasil)", flag: "🇧🇷", images: "br" },
  { code: "pt-PT", name: "Português", flag: "🇵🇹", images: "pt" },
  { code: "ro-RO", name: "Română", flag: "🇷🇴", images: "ro" },
  { code: "ru-RU", name: "Русский", flag: "🇷🇺", images: "ru" },
  { code: "sk-SK", name: "Slovenčina", flag: "🇸🇰", images: "sk" },
  { code: "sl-SI", name: "Slovenščina", flag: "🇸🇮", images: "sl" },
  { code: "sr-RS", name: "Српски", flag: "🇷🇸", images: "sr" },
  { code: "sv-SE", name: "Svenska", flag: "🇸🇪", images: "se" },
  { code: "tr-TR", name: "Türkçe", flag: "🇹🇷", images: "tr" },
  { code: "uk-UA", name: "Українська", flag: "🇺🇦", images: "uk" },
];

export const isSupported = (code) => Object.hasOwn(DICTIONARIES, code ?? "");

const findLanguage = (code) => LANGUAGES.find((l) => l.code === code);

export const getDir = (code) => findLanguage(code)?.dir ?? "ltr";

// Folder with the "About the app" screenshots for a locale
export const getImageFolder = (code) =>
  findLanguage(code)?.images ?? findLanguage(DEFAULT_LOCALE).images;

// Language part only ("pt-PT" → "pt"); the first code listed wins for a shared language
const BY_LANGUAGE = {};
for (const { code } of LANGUAGES) BY_LANGUAGE[code.split("-")[0].toLowerCase()] ??= code;
BY_LANGUAGE.no = BY_LANGUAGE.nn = "nb-NO";
BY_LANGUAGE.pt = "pt-PT";

// Maps any tag ("en", "en-GB", "no", "sv", "pt_br", the old short codes) to a supported locale, or null
export function normalizeLocale(code) {
  if (!code) return null;
  const tag = String(code).trim().replace("_", "-");
  const exact = Object.keys(DICTIONARIES).find((c) => c.toLowerCase() === tag.toLowerCase());
  if (exact) return exact;
  return BY_LANGUAGE[tag.split("-")[0].toLowerCase()] ?? null;
}

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
    const match = normalizeLocale(tag);
    if (match) return match;
  }
  return DEFAULT_LOCALE;
}
