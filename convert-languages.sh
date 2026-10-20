#!/usr/bin/env bash
# convert-languages.sh
# Switches the site's languages to the new xx-XX.json format:
#  - src/locales/<code>.json  →  src/locales/<lang>-<REGION>.json (tab-indented)
#  - each new file = all keys from the given languages file + all existing web keys
#    (web keys are inserted before the "-------EOF-----------" key, which stays last)
#  - i18n.js, LocaleGate, AboutAppModal and layout.js use the new codes
#    (old cookies like "no"/"sv" are mapped to "nb-NO"/"sv-SE")
# Run from the project root:  bash convert-languages.sh path/to/languages   (folder or .zip)
set -euo pipefail

SRC="${1:-}"
if [ -z "$SRC" ]; then
  echo "Usage: bash convert-languages.sh path/to/languages (folder or .zip)" >&2
  exit 1
fi
if [ ! -f src/lib/i18n.js ]; then
  echo "✗ src/lib/i18n.js not found – run this from the project root." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Find the folder that holds en-US.json (works for a folder or a zip, ignores __MACOSX)
if [ -f "$SRC" ]; then
  unzip -q "$SRC" -d "$TMP/unzipped"
  SRC="$TMP/unzipped"
fi
LANG_DIR="$(find "$SRC" -name en-US.json -not -path '*__MACOSX*' -exec dirname {} \; | head -1)"
if [ -z "$LANG_DIR" ]; then
  echo "✗ No en-US.json found in $1" >&2
  exit 1
fi
echo "Using languages from: $LANG_DIR"

# ---------------------------------------------------------------- merge files
cat > "$TMP/merge.mjs" <<'FILE_END'
import fs from "node:fs";
import path from "node:path";

const [langDir, localesDir] = process.argv.slice(2);
const MAP = {
  ar: "ar-SA", bg: "bg-BG", bs: "bs-BA", ca: "ca-ES", cs: "cs-CZ", da: "da-DK", de: "de-DE",
  el: "el-GR", en: "en-US", es: "es-ES", et: "et-EE", fi: "fi-FI", fr: "fr-FR", he: "he-IL",
  hr: "hr-HR", hu: "hu-HU", is: "is-IS", it: "it-IT", ja: "ja-JP", lt: "lt-LT", lv: "lv-LV",
  mk: "mk-MK", nl: "nl-NL", no: "nb-NO", pl: "pl-PL", pt: "pt-PT", "pt-BR": "pt-BR",
  ro: "ro-RO", ru: "ru-RU", sk: "sk-SK", sl: "sl-SI", sr: "sr-RS", sv: "sv-SE", tr: "tr-TR",
  uk: "uk-UA",
};
const EOF_KEY = "-------EOF-----------";
const read = (f) => JSON.parse(fs.readFileSync(f, "utf8").replace(/^﻿/, ""));

for (const [oldCode, newCode] of Object.entries(MAP)) {
  const appFile = path.join(langDir, `${newCode}.json`);
  const oldFile = path.join(localesDir, `${oldCode}.json`);
  const outFile = path.join(localesDir, `${newCode}.json`);
  if (!fs.existsSync(appFile)) throw new Error(`Missing ${appFile}`);

  // Web keys: from the old short-code file, or (on a re-run) from the already converted file
  let web = {};
  if (fs.existsSync(oldFile) && oldFile !== outFile) web = read(oldFile);
  else if (fs.existsSync(outFile)) {
    const app = read(appFile);
    for (const [k, v] of Object.entries(read(outFile))) if (!(k in app)) web[k] = v;
  }

  const app = read(appFile);
  const merged = {};
  for (const [k, v] of Object.entries(app)) if (k !== EOF_KEY) merged[k] = v;
  for (const [k, v] of Object.entries(web)) if (!(k in merged)) merged[k] = v;
  if (EOF_KEY in app) merged[EOF_KEY] = app[EOF_KEY];

  fs.writeFileSync(outFile, JSON.stringify(merged, null, "\t") + "\n");
  if (fs.existsSync(oldFile) && oldFile !== outFile) fs.unlinkSync(oldFile);
  console.log(`✓ src/locales/${newCode}.json  (${Object.keys(app).length} app + ${Object.keys(web).length} web keys)`);
}
FILE_END
node "$TMP/merge.mjs" "$LANG_DIR" src/locales

# ---------------------------------------------------------------- i18n.js
cat > src/lib/i18n.js <<'FILE_END'
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
FILE_END
echo "✓ src/lib/i18n.js"

# ---------------------------------------------------------------- LocaleGate.js
cat > src/components/LocaleGate.js <<'FILE_END'
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
FILE_END
echo "✓ src/components/LocaleGate.js"

# ---------------------------------------------------------------- small edits
cat > "$TMP/edit.mjs" <<'FILE_END'
import fs from "node:fs";

function edit(file, pairs) {
  let s = fs.readFileSync(file, "utf8");
  for (const [from, to] of pairs) {
    if (s.includes(to)) continue; // already done
    if (!s.includes(from)) throw new Error(`${file}: could not find ${JSON.stringify(from)}`);
    s = s.replace(from, to);
  }
  fs.writeFileSync(file, s);
  console.log(`✓ ${file}`);
}

edit("src/components/landing/AboutAppModal.js", [
  [
    'import { useLocale } from "@/components/LocaleProvider";\n',
    'import { useLocale } from "@/components/LocaleProvider";\nimport { DEFAULT_LOCALE, getImageFolder } from "@/lib/i18n";\n',
  ],
  ['const FALLBACK_IMAGE_LOCALE = "no";', "const FALLBACK_IMAGE_LOCALE = DEFAULT_LOCALE;"],
  ["`/images/about-app/${locale}/", "`/images/about-app/${getImageFolder(locale)}/"],
]);

edit("src/app/layout.js", [['<html lang="no"', '<html lang="nb-NO"']]);
FILE_END
node "$TMP/edit.mjs"

echo "Done. Restart the dev server (npm run dev)."
