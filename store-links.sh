#!/usr/bin/env bash
# store-links.sh
# Landing page: App Store and Google Play links under everything, centred, like kolskalender:
#    Available on the App Store and Google Play.
#    Download for free on your smartphone.
#    [  Download on the App Store ]  [ ▶ GET IT ON Google Play ]
#  - App Store:   https://apps.apple.com/us/app/hodepinedagboken/id1523651899
#  - Google Play: https://play.google.com/store/apps/details?id=com.doit.headache_app
#  - black badges with the Apple and Google Play logos; open in a new tab
#  - the two lines and the small line on each badge in all 35 languages
#    (new texts STORE_AVAILABLE, STORE_DOWNLOAD_FREE, STORE_APPLE_TOP, STORE_GOOGLE_TOP)
#  - safe to run again
# Run from the project root:  bash store-links.sh
set -euo pipefail

PAGE=src/app/page.js
if [ ! -f "$PAGE" ] || [ ! -d src/locales ]; then
  echo "✗ $PAGE or src/locales not found – run this from the project root." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > src/components/landing/StoreLinks.js <<'FILE_END'
// src/components/landing/StoreLinks.js
"use client";

import { useLocale } from "@/components/LocaleProvider";

const APP_STORE_URL = "https://apps.apple.com/us/app/hodepinedagboken/id1523651899";
const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=com.doit.headache_app";

function AppleLogo() {
  return (
    <svg viewBox="0 0 384 512" className="h-7 w-7 shrink-0" fill="currentColor" aria-hidden="true">
      <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
    </svg>
  );
}

function GooglePlayLogo() {
  return (
    <svg viewBox="0 0 512 512" className="h-7 w-7 shrink-0" aria-hidden="true">
      <path fill="#00d7fe" d="M48 26c-6 6-9 15-9 27v406c0 12 3 21 9 27l2 2 228-228v-6L50 24z" />
      <path fill="#ffce00" d="M354 335l-76-76v-6l76-76 2 1 90 51c26 15 26 39 0 54l-90 51z" />
      <path fill="#ff3a44" d="M356 334l-78-78L48 486c9 9 23 10 39 1l269-153" />
      <path fill="#00f076" d="M356 178L87 25c-16-9-30-8-39 1l230 230z" />
    </svg>
  );
}

function Badge({ href, logo, top, name }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      dir="ltr"
      className="inline-flex min-w-[10.5rem] items-center gap-3 rounded-xl border border-black bg-black px-4 py-2.5 text-white shadow-sm transition hover:bg-neutral-800 focus:outline-none focus:ring-2 focus:ring-blue-300 focus:ring-offset-2"
    >
      {logo}
      <span className="flex flex-col text-start leading-tight">
        <span className="text-[11px] font-medium">{top}</span>
        <span className="text-lg font-semibold tracking-tight">{name}</span>
      </span>
    </a>
  );
}

// "Available on the App Store and Google Play." + the two store badges
export default function StoreLinks() {
  const { t } = useLocale();

  return (
    <section className="flex flex-col items-center text-center">
      <p className="text-base leading-relaxed text-slate-600">
        {t.STORE_AVAILABLE}
        <br />
        {t.STORE_DOWNLOAD_FREE}
      </p>
      <div className="mt-5 flex flex-wrap justify-center gap-3">
        <Badge href={APP_STORE_URL} logo={<AppleLogo />} top={t.STORE_APPLE_TOP} name="App Store" />
        <Badge href={GOOGLE_PLAY_URL} logo={<GooglePlayLogo />} top={t.STORE_GOOGLE_TOP} name="Google Play" />
      </div>
    </section>
  );
}
FILE_END
echo "✓ src/components/landing/StoreLinks.js"

# ---- put the links on the landing page ---------------------------------------------------
node - "$PAGE" <<'NODE_END'
const fs = require("fs");
const file = process.argv[2];
let src = fs.readFileSync(file, "utf8");
if (src.includes("<StoreLinks")) {
  console.log(`✓ ${file} already has the store links`);
  process.exit(0);
}
const replace = (from, to, what) => {
  if (!src.includes(from)) {
    console.error(`✗ ${file}: could not find ${what} – run front-image.sh first`);
    process.exit(1);
  }
  src = src.replace(from, to);
};
replace(
  'import ReadMoreButton from "@/components/landing/ReadMoreButton";',
  'import ReadMoreButton from "@/components/landing/ReadMoreButton";\nimport StoreLinks from "@/components/landing/StoreLinks";',
  "the ReadMoreButton import"
);
replace(
  "          <ReadMoreButton />\n        </div>\n",
  "          <ReadMoreButton />\n        </div>\n\n        {/* App Store / Google Play, centred under everything */}\n        <div className=\"mt-6 lg:col-span-2 lg:row-start-4\">\n          <StoreLinks />\n        </div>\n",
  "the Read more button"
);
fs.writeFileSync(file, src);
console.log(`✓ ${file} (store links under everything)`);
NODE_END

# ---- texts in all languages --------------------------------------------------------------
cat > "$TMP/texts.json" <<'FILE_END'
{
  "ar-SA": ["متوفر على App Store وGoogle Play.", "حمّله مجانًا على هاتفك الذكي.", "حمّله من", "احصل عليه من"],
  "bg-BG": ["Предлага се в App Store и Google Play.", "Изтеглете безплатно на смартфона си.", "Изтеглете от", "ВЗЕМЕТЕ ГО ОТ"],
  "bs-BA": ["Dostupno na App Storeu i Google Playu.", "Preuzmite besplatno na svoj pametni telefon.", "Preuzmite na", "NABAVITE NA"],
  "ca-ES": ["Disponible a l'App Store i a Google Play.", "Descarrega-la gratis al teu telèfon intel·ligent.", "Descarrega-la a", "DISPONIBLE A"],
  "cs-CZ": ["K dispozici v App Store a na Google Play.", "Stáhněte si ji zdarma do svého chytrého telefonu.", "Stáhnout v", "NYNÍ NA"],
  "da-DK": ["Fås i App Store og Google Play.", "Download gratis på din smartphone.", "Hent i", "NU PÅ"],
  "de-DE": ["Erhältlich im App Store und bei Google Play.", "Kostenlos auf Ihr Smartphone herunterladen.", "Laden im", "JETZT BEI"],
  "el-GR": ["Διαθέσιμο στο App Store και στο Google Play.", "Κατεβάστε το δωρεάν στο smartphone σας.", "Λήψη από το", "ΔΙΑΘΕΣΙΜΟ ΣΤΟ"],
  "en-US": ["Available on the App Store and Google Play.", "Download for free on your smartphone.", "Download on the", "GET IT ON"],
  "es-ES": ["Disponible en App Store y Google Play.", "Descárgala gratis en tu smartphone.", "Descárgala en", "DISPONIBLE EN"],
  "et-EE": ["Saadaval App Store'is ja Google Plays.", "Laadi tasuta oma nutitelefoni.", "Laadi alla", "LAADI ALLA"],
  "fi-FI": ["Saatavilla App Storesta ja Google Playsta.", "Lataa ilmaiseksi älypuhelimeesi.", "Lataa", "SAATAVILLA"],
  "fr-FR": ["Disponible sur l'App Store et Google Play.", "Téléchargez-la gratuitement sur votre smartphone.", "Télécharger dans l'", "DISPONIBLE SUR"],
  "he-IL": ["זמין ב-App Store וב-Google Play.", "הורידו בחינם לסמארטפון שלכם.", "הורדה מה-", "קבלו את זה ב-"],
  "hr-HR": ["Dostupno na App Storeu i Google Playu.", "Preuzmite besplatno na svoj pametni telefon.", "Preuzmite na", "NABAVITE NA"],
  "hu-HU": ["Elérhető az App Store-ban és a Google Playen.", "Töltse le ingyen okostelefonjára.", "Letöltés az", "SZEREZD MEG:"],
  "is-IS": ["Fáanlegt í App Store og Google Play.", "Sæktu ókeypis í snjallsímann þinn.", "Sækja í", "FÁÐU ÞAÐ Á"],
  "it-IT": ["Disponibile su App Store e Google Play.", "Scaricala gratis sul tuo smartphone.", "Scarica su", "DISPONIBILE SU"],
  "ja-JP": ["App Store と Google Play で配信中。", "スマートフォンに無料でダウンロードできます。", "ダウンロード", "今すぐ手に入れよう"],
  "lt-LT": ["Galima rasti App Store ir Google Play.", "Atsisiųskite nemokamai į savo išmanųjį telefoną.", "Atsisiųskite iš", "GAUKITE"],
  "lv-LV": ["Pieejama App Store un Google Play.", "Lejupielādējiet bez maksas savā viedtālrunī.", "Lejupielādējiet", "IEGŪSTIET"],
  "mk-MK": ["Достапно на App Store и Google Play.", "Преземете бесплатно на вашиот паметен телефон.", "Преземете од", "НАБАВЕТЕ НА"],
  "nb-NO": ["Tilgjengelig i App Store og Google Play.", "Last ned gratis på mobilen din.", "Last ned fra", "LAST NED PÅ"],
  "nl-NL": ["Verkrijgbaar in de App Store en op Google Play.", "Download gratis op je smartphone.", "Download in de", "ONTDEK HET OP"],
  "pl-PL": ["Dostępna w App Store i Google Play.", "Pobierz bezpłatnie na swój smartfon.", "Pobierz z", "POBIERZ Z"],
  "pt-BR": ["Disponível na App Store e no Google Play.", "Baixe grátis no seu smartphone.", "Baixar na", "DISPONÍVEL NO"],
  "pt-PT": ["Disponível na App Store e no Google Play.", "Descarregue gratuitamente no seu smartphone.", "Descarregar na", "DISPONÍVEL NO"],
  "ro-RO": ["Disponibilă în App Store și Google Play.", "Descarc-o gratuit pe smartphone.", "Descarcă din", "DESCARCĂ DE PE"],
  "ru-RU": ["Доступно в App Store и Google Play.", "Скачайте бесплатно на смартфон.", "Загрузите в", "ДОСТУПНО В"],
  "sk-SK": ["Dostupné v App Store a na Google Play.", "Stiahnite si ju zadarmo do smartfónu.", "Stiahnuť v", "TERAZ NA"],
  "sl-SI": ["Na voljo v App Store in Google Play.", "Brezplačno jo prenesite na pametni telefon.", "Prenesite iz", "PRENESITE Z"],
  "sr-RS": ["Доступно на App Store-у и Google Play-у.", "Преузмите бесплатно на свој паметни телефон.", "Преузмите на", "НАБАВИТЕ НА"],
  "sv-SE": ["Finns i App Store och på Google Play.", "Ladda ned gratis till din smartphone.", "Hämta i", "LADDA NED PÅ"],
  "tr-TR": ["App Store ve Google Play'de mevcut.", "Akıllı telefonunuza ücretsiz indirin.", "Şuradan indirin", "HEMEN İNDİRİN"],
  "uk-UA": ["Доступно в App Store і Google Play.", "Завантажте безкоштовно на смартфон.", "Завантажте в", "ДОСТУПНО В"]
}
FILE_END

node - "$TMP/texts.json" <<'NODE_END'
const fs = require("fs");
const texts = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const KEYS = ["STORE_AVAILABLE", "STORE_DOWNLOAD_FREE", "STORE_APPLE_TOP", "STORE_GOOGLE_TOP"];
const dir = "src/locales";
let failed = false;

for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json")).sort()) {
  const code = file.replace(/\.json$/, "");
  if (!texts[code]) console.log(`! ${file}: no translation, using English`);
  const values = texts[code] ?? texts["en-US"];
  const p = `${dir}/${file}`;
  let src = fs.readFileSync(p, "utf8");
  const before = JSON.parse(src);
  const indent = (src.match(/^([ \t]+)"/m) || [, "\t"])[1];

  KEYS.forEach((key, i) => {
    const re = new RegExp(`^([ \\t]*)"${key}":.*$`, "m");
    if (re.test(src)) src = src.replace(re, (line, ind) => `${ind}"${key}": ${JSON.stringify(values[i])}${line.trimEnd().endsWith(",") ? "," : ""}`);
  });

  const missing = KEYS.filter((k) => !new RegExp(`^[ \\t]*"${k}":`, "m").test(src));
  if (missing.length) {
    const lines = missing.map((k) => `${indent}"${k}": ${JSON.stringify(values[KEYS.indexOf(k)])},`).join("\n");
    const anchor = /^[ \t]*"LANDING_READ_MORE":.*,[ \t]*$/m;
    if (anchor.test(src)) src = src.replace(anchor, (line) => `${line}\n${lines}`);
    else src = src.replace(/\s*}\s*$/, `,\n${lines.replace(/,$/, "")}\n}\n`);
  }

  const after = JSON.parse(src);
  if (KEYS.some((k, i) => after[k] !== values[i]) || Object.keys(after).length < Object.keys(before).length) {
    console.error(`✗ ${file}: could not add the texts`);
    failed = true;
    continue;
  }
  fs.writeFileSync(p, src);
}
if (failed) process.exit(1);
console.log(`✓ STORE_* texts in all src/locales/*.json`);
NODE_END
