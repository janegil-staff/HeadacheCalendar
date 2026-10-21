#!/usr/bin/env bash
# front-image.sh
# Landing page:
#  - laid out like kolskalender: headline (HEADACHE_DIARY) and a new intro text
#    (LANDING_INTRO) top-left, the language's front.png (larger) under them with
#    "Read more" below, and the code card to the right of the image with the language
#    picker right-aligned above it (on phones the picker stays in the top corner)
#    (public/images/about-app/<folder>/front.png, the same folders as the "About the app"
#    screenshots, picked with getImageFolder(locale), e.g. nb-NO → no, sv-SE → se, pt-BR → br)
#  - the image switches instantly when another language is picked in the language picker
#  - if a language has no front.png, the Norwegian one is used; if that is missing too, the
#    image is hidden and the card stays centred
#  - the image shows from the lg breakpoint (≥1024 px); on phones/tablets: headline, text, card, read more
#  - Arabic and Hebrew (right-to-left) get the image on the right, mirroring the layout
#  - LANDING_INTRO added to all 35 files in src/locales/ (after LANDING_READ_MORE);
#    running the script again updates the text instead of adding a duplicate
#  - lists any language folder that is missing front.png
# Run from the project root:  bash front-image.sh
set -euo pipefail

if [ ! -f src/app/page.js ] || [ ! -f src/lib/i18n.js ]; then
  echo "✗ src/app/page.js or src/lib/i18n.js not found – run this from the project root." >&2
  exit 1
fi

mkdir -p src/components/landing

cat > src/components/landing/FrontImage.js <<'FILE_END'
// src/components/landing/FrontImage.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { DEFAULT_LOCALE, getImageFolder } from "@/lib/i18n";

const frontSrc = (locale) => `/images/about-app/${getImageFolder(locale)}/front.png`;

function Picture({ locale, alt, className }) {
  const fallback = frontSrc(DEFAULT_LOCALE);
  const [src, setSrc] = useState(frontSrc(locale));
  const [hidden, setHidden] = useState(false);

  if (hidden) return null;

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      className={className}
      draggable={false}
      onError={() => (src !== fallback ? setSrc(fallback) : setHidden(true))}
    />
  );
}

// key={locale} → a fresh image (and fallback state) every time the language changes
export default function FrontImage({ className = "" }) {
  const { locale, t } = useLocale();
  return <Picture key={locale} locale={locale} alt={t.HEADACHE_DIARY ?? ""} className={className} />;
}
FILE_END

cat > src/app/page.js <<'FILE_END'
// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import FrontImage from "@/components/landing/FrontImage";
import LanguagePicker from "@/components/landing/LanguagePicker";
import ReadMoreButton from "@/components/landing/ReadMoreButton";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 py-20">
      <Background />

      {/* Phone/tablet: headline, text, card, read more (no image).
          Desktop (lg+), like kolskalender: headline + text top-left, the image under it with
          "Read more" below, and the code card to the right of the image. */}
      <div className="grid w-full max-w-6xl grid-cols-1 gap-y-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-10 xl:gap-x-14">
        <header className="max-w-2xl text-center lg:col-start-1 lg:row-start-1 lg:text-start">
          <h1 className="font-serif text-4xl font-bold text-blue-800 sm:text-5xl xl:text-6xl">
            {t.HEADACHE_DIARY}
          </h1>
          {t.LANDING_INTRO && (
            <p className="mt-4 text-base leading-relaxed text-slate-700 sm:text-lg xl:text-xl">
              {t.LANDING_INTRO}
            </p>
          )}
        </header>

        {/* Phone/tablet: top corner of the page. Desktop: right column, just above the code card */}
        <div className="absolute end-4 top-4 sm:end-6 sm:top-6 lg:static lg:col-start-2 lg:row-start-1 lg:self-end lg:justify-self-end">
          <LanguagePicker />
        </div>

        <FrontImage className="hidden h-auto max-h-[72vh] w-full object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block" />

        <div className="mx-auto w-full max-w-md self-start lg:col-start-2 lg:row-start-2 lg:mx-0 lg:max-w-none">
          <CodeCard />
        </div>

        <div className="flex justify-center lg:col-start-1 lg:row-start-3 lg:justify-start">
          <ReadMoreButton />
        </div>
      </div>
    </main>
  );
}
FILE_END

echo "✓ src/components/landing/FrontImage.js"
echo "✓ src/app/page.js"

# ---- LANDING_INTRO in every locale file -------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/intro.json" <<'FILE_END'
{
  "ar-SA": "احصل على نظرة شاملة من خلال تسجيل بسيط وتذكير يومي. استيراد سهل للبيانات من هذه الصفحة. تم تطويره بالتعاون مع أخصائيي الصداع وأطباء الأعصاب.",
  "bg-BG": "Получете пълен преглед с лесно отбелязване и ежедневно напомняне. Лесно импортиране на данни на тази страница. Разработено в сътрудничество със специалисти по главоболие и невролози.",
  "bs-BA": "Dobijte potpun pregled uz jednostavno bilježenje i dnevni podsjetnik. Jednostavan uvoz podataka na ovoj stranici. Razvijeno u saradnji sa specijalistima za glavobolju i neurolozima.",
  "ca-ES": "Obtén una visió completa amb un registre senzill i un recordatori diari. Importa les teves dades fàcilment en aquesta pàgina. Desenvolupat en col·laboració amb especialistes en cefalea i neuròlegs.",
  "cs-CZ": "Získejte úplný přehled díky jednoduchému zaznamenávání a dennímu připomenutí. Snadný import dat na této stránce. Vyvinuto ve spolupráci se specialisty na bolesti hlavy a neurology.",
  "da-DK": "Få fuldt overblik med enkel registrering og daglig påmindelse. Nem import af data på denne side. Udviklet i samarbejde med hovedpinespecialister og neurologer.",
  "de-DE": "Behalten Sie den vollen Überblick mit einfacher Erfassung und täglicher Erinnerung. Einfacher Datenimport auf dieser Seite. Entwickelt in Zusammenarbeit mit Kopfschmerzspezialisten und Neurologen.",
  "el-GR": "Αποκτήστε πλήρη εικόνα με απλή καταγραφή και καθημερινή υπενθύμιση. Εύκολη εισαγωγή δεδομένων σε αυτή τη σελίδα. Αναπτύχθηκε σε συνεργασία με ειδικούς στους πονοκεφάλους και νευρολόγους.",
  "en-US": "Get a full overview with simple logging and a daily reminder. Easily import your data on this page. Developed in collaboration with headache specialists and neurologists.",
  "es-ES": "Obtén una visión completa con un registro sencillo y un recordatorio diario. Importa tus datos fácilmente en esta página. Desarrollado en colaboración con especialistas en cefalea y neurólogos.",
  "et-EE": "Saa täielik ülevaade lihtsa registreerimise ja igapäevase meeldetuletusega. Lihtne andmete importimine sellel lehel. Välja töötatud koostöös peavalu spetsialistide ja neuroloogidega.",
  "fi-FI": "Saat täyden kokonaiskuvan helpon kirjaamisen ja päivittäisen muistutuksen avulla. Tietojen tuonti onnistuu helposti tällä sivulla. Kehitetty yhteistyössä päänsärkyyn erikoistuneiden lääkärien ja neurologien kanssa.",
  "fr-FR": "Gardez une vue d'ensemble complète grâce à un enregistrement simple et un rappel quotidien. Importez facilement vos données sur cette page. Développé en collaboration avec des spécialistes des céphalées et des neurologues.",
  "he-IL": "קבלו תמונה מלאה בעזרת רישום פשוט ותזכורת יומית. ייבוא נתונים קל בעמוד זה. פותח בשיתוף מומחים לכאבי ראש ונוירולוגים.",
  "hr-HR": "Dobijte potpuni pregled uz jednostavno bilježenje i dnevni podsjetnik. Jednostavan uvoz podataka na ovoj stranici. Razvijeno u suradnji sa specijalistima za glavobolju i neurolozima.",
  "hu-HU": "Teljes áttekintés egyszerű rögzítéssel és napi emlékeztetővel. Egyszerű adatimportálás ezen az oldalon. Fejfájás-specialistákkal és neurológusokkal együttműködésben fejlesztve.",
  "is-IS": "Fáðu fulla yfirsýn með einfaldri skráningu og daglegri áminningu. Auðveldur innflutningur gagna á þessari síðu. Þróað í samstarfi við sérfræðinga í höfuðverk og taugalækna.",
  "it-IT": "Ottieni una visione completa con una registrazione semplice e un promemoria quotidiano. Importa facilmente i tuoi dati in questa pagina. Sviluppato in collaborazione con specialisti delle cefalee e neurologi.",
  "ja-JP": "簡単な記録と毎日のリマインダーで、全体をしっかり把握できます。このページで簡単にデータをインポートできます。頭痛専門医および脳神経内科医と協力して開発されました。",
  "lt-LT": "Gaukite visą apžvalgą paprastai registruodami ir gaudami kasdienį priminimą. Paprastas duomenų importavimas šiame puslapyje. Sukurta bendradarbiaujant su galvos skausmo specialistais ir neurologais.",
  "lv-LV": "Iegūstiet pilnu pārskatu ar vienkāršu reģistrēšanu un ikdienas atgādinājumu. Vienkārša datu importēšana šajā lapā. Izstrādāts sadarbībā ar galvassāpju speciālistiem un neirologiem.",
  "mk-MK": "Добијте целосен преглед со едноставно евидентирање и дневен потсетник. Едноставен увоз на податоци на оваа страница. Развиено во соработка со специјалисти за главоболка и невролози.",
  "nb-NO": "Få full oversikt med enkel registrering og daglig påminnelse. Enkel import av data på denne siden. Utviklet i samarbeid med hodepinespesialister og nevrologer.",
  "nl-NL": "Krijg volledig overzicht met eenvoudige registratie en een dagelijkse herinnering. Eenvoudig gegevens importeren op deze pagina. Ontwikkeld in samenwerking met hoofdpijnspecialisten en neurologen.",
  "pl-PL": "Zyskaj pełny przegląd dzięki prostej rejestracji i codziennemu przypomnieniu. Łatwy import danych na tej stronie. Opracowane we współpracy ze specjalistami od bólów głowy i neurologami.",
  "pt-BR": "Tenha uma visão completa com registro simples e lembrete diário. Importe seus dados facilmente nesta página. Desenvolvido em parceria com especialistas em cefaleia e neurologistas.",
  "pt-PT": "Tenha uma visão completa com um registo simples e um lembrete diário. Importe facilmente os seus dados nesta página. Desenvolvido em colaboração com especialistas em cefaleias e neurologistas.",
  "ro-RO": "Obțineți o imagine completă prin înregistrare simplă și memento zilnic. Importați ușor datele pe această pagină. Dezvoltat în colaborare cu specialiști în cefalee și neurologi.",
  "ru-RU": "Получите полную картину благодаря простой регистрации и ежедневному напоминанию. Удобный импорт данных на этой странице. Разработано совместно со специалистами по головной боли и неврологами.",
  "sk-SK": "Získajte úplný prehľad vďaka jednoduchému zaznamenávaniu a dennému pripomenutiu. Jednoduchý import údajov na tejto stránke. Vyvinuté v spolupráci so špecialistami na bolesti hlavy a neurológmi.",
  "sl-SI": "Pridobite popoln pregled s preprostim beleženjem in dnevnim opomnikom. Enostaven uvoz podatkov na tej strani. Razvito v sodelovanju s specialisti za glavobol in nevrologi.",
  "sr-RS": "Добијте потпун преглед уз једноставно бележење и дневни подсетник. Једноставан увоз података на овој страници. Развијено у сарадњи са специјалистима за главобољу и неуролозима.",
  "sv-SE": "Få full överblick med enkel registrering och daglig påminnelse. Enkel import av data på den här sidan. Utvecklad i samarbete med huvudvärksspecialister och neurologer.",
  "tr-TR": "Basit kayıt ve günlük hatırlatma ile tam bir genel bakış elde edin. Bu sayfada verilerinizi kolayca içe aktarın. Baş ağrısı uzmanları ve nörologlarla iş birliği içinde geliştirilmiştir.",
  "uk-UA": "Отримайте повну картину завдяки простій реєстрації та щоденному нагадуванню. Зручний імпорт даних на цій сторінці. Розроблено у співпраці з фахівцями з головного болю та неврологами."
}
FILE_END

node - "$TMP/intro.json" <<'NODE_END'
const fs = require("fs");
const path = require("path");
const texts = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const dir = "src/locales";
const KEY = "LANDING_INTRO";
let failed = false;

for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json")).sort()) {
  const code = file.replace(/\.json$/, "");
  const text = texts[code] ?? texts["en-US"];
  if (!texts[code]) console.log(`! ${file}: no translation, using English`);
  const p = path.join(dir, file);
  const src = fs.readFileSync(p, "utf8");
  const json = JSON.parse(src); // fails loudly on a broken file
  const value = JSON.stringify(text);
  let out;

  const existing = new RegExp(`^([ \\t]*)"${KEY}":.*$`, "m");
  if (existing.test(src)) {
    out = src.replace(existing, (line, indent) => `${indent}"${KEY}": ${value}${line.trimEnd().endsWith(",") ? "," : ""}`);
  } else {
    const anchor = /^([ \t]*)"LANDING_READ_MORE":.*,[ \t]*$/m;
    const m = src.match(anchor);
    if (m) {
      out = src.replace(anchor, (line, indent) => `${line}\n${indent}"${KEY}": ${value},`);
    } else {
      // no anchor: add as the last key, keeping the file's indentation
      const indent = (src.match(/^([ \t]+)"/m) || [, "\t"])[1];
      out = src.replace(/\s*}\s*$/, `,\n${indent}"${KEY}": ${value}\n}\n`);
    }
  }

  const check = JSON.parse(out);
  if (check[KEY] !== text || Object.keys(check).length < Object.keys(json).length) {
    console.error(`✗ ${file}: could not add ${KEY}`);
    failed = true;
    continue;
  }
  fs.writeFileSync(p, out);
}
if (failed) process.exit(1);
console.log(`✓ ${KEY} in all src/locales/*.json`);
NODE_END

# Report language folders without front.png
if [ -d public/images/about-app ]; then
  missing=""
  for dir in public/images/about-app/*/; do
    [ -f "${dir}front.png" ] || missing="$missing $(basename "$dir")"
  done
  if [ -n "$missing" ]; then
    echo "! front.png missing in:$missing (those languages show the Norwegian image)"
  else
    echo "✓ front.png found in every language folder"
  fi
fi
