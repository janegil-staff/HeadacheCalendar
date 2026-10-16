#!/usr/bin/env bash
# add-about-modal.sh
# Adds "Read more about the app" + a 9-page About modal (35 languages)
# Run from the project root:  bash add-about-modal.sh
set -euo pipefail

if [ ! -f package.json ] || ! grep -q '"next"' package.json; then
  echo "✗ Run this from the headache_calendar project root." >&2
  exit 1
fi
[ -d src/locales ] || { echo "✗ src/locales not found – run the language setup first." >&2; exit 1; }

mkdir -p src/components/landing src/app

cat > src/components/landing/AboutAppModal.js <<'FILE_END'
// src/components/landing/AboutAppModal.js
"use client";

import { useEffect, useRef, useState } from "react";
import { useLocale } from "@/components/LocaleProvider";

export const ABOUT_PAGE_COUNT = 9;
const FALLBACK_IMAGE_LOCALE = "no";

const imageSrc = (locale, page) => `/images/about-app/${locale}/${page}.png`;

export default function AboutAppModal({ open, onClose }) {
  const { t, locale, dir } = useLocale();
  const [page, setPage] = useState(1);
  const dialogRef = useRef(null);
  const closeRef = useRef(null);

  const isFirst = page === 1;
  const isLast = page === ABOUT_PAGE_COUNT;
  const next = () => setPage((p) => Math.min(p + 1, ABOUT_PAGE_COUNT));
  const prev = () => setPage((p) => Math.max(p - 1, 1));

  // Start on page 1 every time it opens; lock page scroll while open
  useEffect(() => {
    if (!open) return;
    setPage(1);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [open]);

  // Esc closes, arrow keys flip pages (mirrored for right-to-left languages)
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => {
      if (e.key === "Escape") onClose();
      const forward = dir === "rtl" ? "ArrowLeft" : "ArrowRight";
      const back = dir === "rtl" ? "ArrowRight" : "ArrowLeft";
      if (e.key === forward) next();
      if (e.key === back) prev();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, dir, onClose]);

  // Preload the next image so flipping feels instant
  useEffect(() => {
    if (!open || isLast) return;
    const img = new Image();
    img.src = imageSrc(locale, page + 1);
  }, [open, page, locale, isLast]);

  if (!open) return null;

  const title = t[`ABOUT_PAGE_${page}_TITLE`];
  const text = t[`ABOUT_PAGE_${page}_TEXT`];
  const stepLabel = (t.ABOUT_STEP_OF ?? "{current} / {total}")
    .replace("{current}", page)
    .replace("{total}", ABOUT_PAGE_COUNT);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-3 backdrop-blur-sm sm:p-6"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="about-app-title"
        className="flex max-h-full w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-gray-100 px-5 py-4 sm:px-7">
          <h2 id="about-app-title" className="text-xl font-bold text-blue-900 sm:text-2xl">
            {t.ABOUT_TITLE}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            aria-label={t.ABOUT_CLOSE}
            className="rounded-lg p-2 text-gray-700 transition hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-200"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-5 sm:px-7 sm:py-6">
          <p className="rounded-lg border-s-4 border-blue-700 bg-blue-50 px-4 py-3 text-base font-semibold leading-relaxed text-blue-900 sm:px-5 sm:text-lg">
            {t.ABOUT_INTRO}
          </p>

          <div className="mt-5 grid items-center gap-6 sm:mt-6 sm:grid-cols-[minmax(0,280px)_1fr] sm:gap-10">
            <div className="mx-auto w-full max-w-[280px] rounded-2xl bg-blue-50 p-4">
              <AboutImage key={`${locale}-${page}`} locale={locale} page={page} alt={title} />
            </div>

            <div aria-live="polite">
              <p className="text-sm font-semibold text-blue-700">{stepLabel}</p>
              <h3 className="mt-1 text-xl font-bold text-gray-900 sm:text-2xl">{title}</h3>
              <p className="mt-3 text-base leading-relaxed text-gray-700 sm:text-lg">{text}</p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between gap-3 border-t border-gray-100 px-5 py-4 sm:px-7">
          <div className="w-24 sm:w-28">
            {!isFirst && (
              <button
                type="button"
                onClick={prev}
                className="rounded-lg px-3 py-2 text-sm font-semibold text-blue-800 transition hover:bg-blue-50"
              >
                {t.ABOUT_PREVIOUS}
              </button>
            )}
          </div>

          <div className="flex gap-1.5" role="tablist">
            {Array.from({ length: ABOUT_PAGE_COUNT }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                type="button"
                role="tab"
                aria-selected={n === page}
                aria-label={(t.ABOUT_STEP_OF ?? "{current} / {total}")
                  .replace("{current}", n)
                  .replace("{total}", ABOUT_PAGE_COUNT)}
                onClick={() => setPage(n)}
                className={`h-2.5 rounded-full transition-all ${
                  n === page ? "w-6 bg-blue-700" : "w-2.5 bg-gray-300 hover:bg-gray-400"
                }`}
              />
            ))}
          </div>

          <div className="flex w-24 justify-end sm:w-28">
            <button
              type="button"
              onClick={isLast ? onClose : next}
              className="rounded-lg bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-800 sm:px-7 sm:text-base"
            >
              {isLast ? t.ABOUT_CLOSE : t.ABOUT_NEXT}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Uses the language's own screenshot, or the Norwegian one if that folder doesn't exist
function AboutImage({ locale, page, alt }) {
  const [src, setSrc] = useState(imageSrc(locale, page));

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt ?? ""}
      onError={() => {
        const fallback = imageSrc(FALLBACK_IMAGE_LOCALE, page);
        if (src !== fallback) setSrc(fallback);
      }}
      className="mx-auto h-auto max-h-[52vh] w-auto rounded-xl object-contain"
    />
  );
}
FILE_END

cat > src/components/landing/ReadMoreButton.js <<'FILE_END'
// src/components/landing/ReadMoreButton.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import AboutAppModal from "@/components/landing/AboutAppModal";

export default function ReadMoreButton() {
  const { t } = useLocale();
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-2 rounded-full border-2 border-blue-700 bg-white px-6 py-3 text-lg font-semibold text-blue-800 shadow-sm transition hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-200"
      >
        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <rect x="6" y="2" width="12" height="20" rx="2" />
          <path d="M11 18h2" />
        </svg>
        {t.LANDING_READ_MORE}
      </button>

      <AboutAppModal open={open} onClose={() => setOpen(false)} />
    </>
  );
}
FILE_END

cat > src/app/page.js <<'FILE_END'
// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import LanguagePicker from "@/components/landing/LanguagePicker";
import ReadMoreButton from "@/components/landing/ReadMoreButton";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 py-20">
      <Background />

      <div className="absolute end-4 top-4 sm:end-6 sm:top-6">
        <LanguagePicker />
      </div>

      <div className="w-full max-w-md">
        <h1 className="mb-8 text-center font-serif text-4xl font-bold text-blue-800 sm:text-5xl">
          {t.LANDING_TITLE}
        </h1>

        <CodeCard />

        <div className="mt-6 flex justify-center">
          <ReadMoreButton />
        </div>
      </div>
    </main>
  );
}
FILE_END

echo "✓ src/components/landing/AboutAppModal.js"
echo "✓ src/components/landing/ReadMoreButton.js"
echo "✓ src/app/page.js (adds the Read more button)"

# Merge the new texts into the existing locale files (existing keys are kept)
cat > .about-texts.json <<'FILE_END'
{
 "ar": {
  "LANDING_READ_MORE": "اقرأ المزيد عن التطبيق",
  "ABOUT_TITLE": "حول التطبيق",
  "ABOUT_INTRO": "إن الاطلاع الواضح على أيام الصداع وشدّته واستخدام الأدوية يسهّل إيجاد العلاج المناسب بالتعاون مع طبيبك. ويساعدك التطبيق على متابعة كل ذلك.",
  "ABOUT_STEP_OF": "{current} من {total}",
  "ABOUT_PREVIOUS": "السابق",
  "ABOUT_NEXT": "التالي",
  "ABOUT_CLOSE": "إغلاق",
  "ABOUT_PAGE_1_TITLE": "الشاشة الرئيسية",
  "ABOUT_PAGE_1_TEXT": "نزّل التطبيق. تعرض الشاشة الرئيسية آخر 30 يومًا بنظرة سريعة: الأيام الخالية من الألم، وأيام الصداع الخفيف أو المتوسط أو الشديد، والأيام التي تناولت فيها دواء النوبة. اضغط على «الإدخال اليومي» لتسجيل يومك.",
  "ABOUT_PAGE_2_TITLE": "التقويم",
  "ABOUT_PAGE_2_TEXT": "في «مذكراتي» يُلوَّن كل يوم في التقويم حسب شدة الصداع، مع علامات لدواء النوبة والأورة. وأسفله تجد ملخصًا للشهر: ساعات الصداع، والأيام حسب الشدة، وأيام تناول الأدوية.",
  "ABOUT_PAGE_3_TITLE": "احصل على رؤى",
  "ABOUT_PAGE_3_TEXT": "راجع تسجيلاتك واحصل على نظرة شاملة من خلال التقويم والمذكرات ومجموعة من الرسوم البيانية، مثل تطوّر استخدامك للأدوية بمرور الوقت.",
  "ABOUT_PAGE_4_TITLE": "بياناتي",
  "ABOUT_PAGE_4_TEXT": "تابع شدة الصداع بمرور الوقت، واعرف مدى فعالية كل دواء من أدوية النوبة، واكتشف العوامل المرتبطة بنوبات الصداع لديك، لفترات تمتد حتى عدة سنوات.",
  "ABOUT_PAGE_5_TITLE": "شارك مع طبيبك",
  "ABOUT_PAGE_5_TEXT": "شارك بياناتك مع طبيبك بسهولة. ينشئ التطبيق رمزًا لمرة واحدة يُدخله طبيبك على headachecalendar.com للاطلاع على تسجيلاتك.",
  "ABOUT_PAGE_6_TITLE": "نصائح",
  "ABOUT_PAGE_6_TEXT": "احصل على نصائح عملية حول الصداع، مثل المحفّزات الشائعة وأهمية النشاط البدني المنتظم والنوم الكافي، حتى في عطلات نهاية الأسبوع.",
  "ABOUT_PAGE_7_TITLE": "الوضع الداكن",
  "ABOUT_PAGE_7_TEXT": "هل أنت حساس للضوء؟ فعّل الوضع الداكن. ويمكنك أيضًا تشغيله أو إيقافه لاحقًا من إعداداتك الشخصية.",
  "ABOUT_PAGE_8_TITLE": "استخدام الأدوية",
  "ABOUT_PAGE_8_TEXT": "اطّلع على الأدوية التي استخدمتها ومتى، سواء أدوية النوبة أو الأدوية الوقائية أو الحقن، ومدى فعالية كل دواء من أدوية النوبة.",
  "ABOUT_PAGE_9_TITLE": "عوامل الصداع",
  "ABOUT_PAGE_9_TEXT": "تعرّف على الأنماط المتعلقة بالشدة والصداع النصفي والأورة والدورة الشهرية والنوبات الطويلة أو القصيرة، وتابع استخدامك للمسكنات والتريبتانات بمرور الوقت."
 },
 "bg": {
  "LANDING_READ_MORE": "Научете повече за приложението",
  "ABOUT_TITLE": "За приложението",
  "ABOUT_INTRO": "Ясният преглед на дните с главоболие, неговата интензивност и приема на лекарства улеснява намирането на правилното лечение заедно с вашия лекар. Приложението ви помага да следите всичко.",
  "ABOUT_STEP_OF": "{current} от {total}",
  "ABOUT_PREVIOUS": "Назад",
  "ABOUT_NEXT": "Напред",
  "ABOUT_CLOSE": "Затвори",
  "ABOUT_PAGE_1_TITLE": "Начален екран",
  "ABOUT_PAGE_1_TEXT": "Изтеглете приложението. Началният екран показва с един поглед последните ви 30 дни: дни без болка, с леко, умерено или силно главоболие и дни, в които сте приели лекарство при пристъп. Докоснете Дневен запис, за да въведете днешния ден.",
  "ABOUT_PAGE_2_TITLE": "Календар",
  "ABOUT_PAGE_2_TEXT": "В Моят дневник всеки ден в календара е оцветен според интензивността на главоболието, с отметки за лекарства при пристъп и аура. Под него ще намерите обобщение на месеца: часове с главоболие, дни по интензивност и дни с лекарства.",
  "ABOUT_PAGE_3_TITLE": "Получете представа",
  "ABOUT_PAGE_3_TEXT": "Прегледайте записите си и получете обща картина чрез календара, дневника и редица графики – например как се променя приемът ви на лекарства с времето.",
  "ABOUT_PAGE_4_TITLE": "Моите данни",
  "ABOUT_PAGE_4_TEXT": "Проследявайте интензивността на главоболието във времето, вижте колко добре действа всяко лекарство при пристъп и открийте кои фактори са свързани с главоболията ви – за периоди до няколко години.",
  "ABOUT_PAGE_5_TITLE": "Споделете с лекаря си",
  "ABOUT_PAGE_5_TEXT": "Лесно споделете данните си с лекаря си. Приложението създава еднократен код, който лекарят въвежда на headachecalendar.com, за да види вашите записи.",
  "ABOUT_PAGE_6_TITLE": "Съвети",
  "ABOUT_PAGE_6_TEXT": "Получете практични съвети за главоболието, например за честите отключващи фактори и защо редовната физическа активност и достатъчният сън са важни – и през уикендите.",
  "ABOUT_PAGE_7_TITLE": "Тъмен режим",
  "ABOUT_PAGE_7_TEXT": "Чувствителни сте към светлина? Включете тъмния режим. По-късно можете да го включите или изключите и в личните настройки.",
  "ABOUT_PAGE_8_TITLE": "Прием на лекарства",
  "ABOUT_PAGE_8_TEXT": "Вижте кои лекарства сте приемали и кога – лекарства при пристъп, профилактични лекарства и инжекции – и колко добре е подействало всяко лекарство при пристъп.",
  "ABOUT_PAGE_9_TITLE": "Фактори за главоболието",
  "ABOUT_PAGE_9_TEXT": "Открийте закономерности в тежестта, мигрената, аурата, менструацията и дългите или кратките пристъпи и следете приема на обезболяващи и триптани във времето."
 },
 "bs": {
  "LANDING_READ_MORE": "Saznajte više o aplikaciji",
  "ABOUT_TITLE": "O aplikaciji",
  "ABOUT_INTRO": "Jasan pregled dana s glavoboljom, njenog intenziteta i upotrebe lijekova olakšava pronalazak prave terapije zajedno s Vašim ljekarom. Aplikacija Vam pomaže da sve pratite.",
  "ABOUT_STEP_OF": "{current} od {total}",
  "ABOUT_PREVIOUS": "Prethodno",
  "ABOUT_NEXT": "Sljedeće",
  "ABOUT_CLOSE": "Zatvori",
  "ABOUT_PAGE_1_TITLE": "Početni ekran",
  "ABOUT_PAGE_1_TEXT": "Preuzmite aplikaciju. Početni ekran na prvi pogled prikazuje Vaših posljednjih 30 dana: dane bez bolova, s blagom, umjerenom ili jakom glavoboljom i dane kada ste uzeli lijek za napad. Dodirnite Dnevni unos da zabilježite današnji dan.",
  "ABOUT_PAGE_2_TITLE": "Kalendar",
  "ABOUT_PAGE_2_TEXT": "U dijelu Moj dnevnik svaki dan u kalendaru obojen je prema intenzitetu glavobolje, s oznakama za lijekove za napad i auru. Ispod je sažetak mjeseca: sati glavobolje, dani po intenzitetu i dani s lijekovima.",
  "ABOUT_PAGE_3_TITLE": "Steknite uvid",
  "ABOUT_PAGE_3_TEXT": "Pregledajte svoje unose i steknite pregled kroz kalendar, dnevnik i niz grafikona – na primjer kako se Vaša upotreba lijekova mijenja tokom vremena.",
  "ABOUT_PAGE_4_TITLE": "Moji podaci",
  "ABOUT_PAGE_4_TEXT": "Pratite intenzitet glavobolje tokom vremena, pogledajte koliko dobro djeluje svaki lijek za napad i otkrijte koji su faktori povezani s Vašim glavoboljama – za periode i do nekoliko godina.",
  "ABOUT_PAGE_5_TITLE": "Podijelite s ljekarom",
  "ABOUT_PAGE_5_TEXT": "Jednostavno podijelite svoje podatke s ljekarom. Aplikacija kreira jednokratni kod koji ljekar unosi na headachecalendar.com kako bi vidio Vaše unose.",
  "ABOUT_PAGE_6_TITLE": "Savjeti",
  "ABOUT_PAGE_6_TEXT": "Dobijte praktične savjete o glavobolji, npr. o čestim okidačima i zašto su redovna fizička aktivnost i dovoljno sna važni – i vikendom.",
  "ABOUT_PAGE_7_TITLE": "Tamni način rada",
  "ABOUT_PAGE_7_TEXT": "Osjetljivi ste na svjetlo? Uključite tamni način rada. Kasnije ga možete uključiti ili isključiti i u ličnim postavkama.",
  "ABOUT_PAGE_8_TITLE": "Upotreba lijekova",
  "ABOUT_PAGE_8_TEXT": "Pogledajte koje ste lijekove koristili i kada – lijekove za napad, preventivne lijekove i injekcije – i koliko je dobro djelovao svaki lijek za napad.",
  "ABOUT_PAGE_9_TITLE": "Faktori glavobolje",
  "ABOUT_PAGE_9_TEXT": "Uočite obrasce u jačini, migreni, auri, menstruaciji te dugim ili kratkim napadima i pratite upotrebu lijekova protiv bolova i triptana tokom vremena."
 },
 "ca": {
  "LANDING_READ_MORE": "Més informació sobre l'aplicació",
  "ABOUT_TITLE": "Sobre l'aplicació",
  "ABOUT_INTRO": "Tenir una visió clara dels dies amb mal de cap, la intensitat i l'ús de medicació facilita trobar el tractament adequat juntament amb el vostre metge. L'aplicació us ajuda a fer-ne el seguiment.",
  "ABOUT_STEP_OF": "{current} de {total}",
  "ABOUT_PREVIOUS": "Anterior",
  "ABOUT_NEXT": "Següent",
  "ABOUT_CLOSE": "Tanca",
  "ABOUT_PAGE_1_TITLE": "Pantalla d'inici",
  "ABOUT_PAGE_1_TEXT": "Descarregueu l'aplicació. La pantalla d'inici mostra els darrers 30 dies d'un cop d'ull: dies sense dolor, amb mal de cap lleu, moderat o intens, i dies en què vau prendre medicació per a les crisis. Toqueu Registre diari per anotar el dia d'avui.",
  "ABOUT_PAGE_2_TITLE": "Calendari",
  "ABOUT_PAGE_2_TEXT": "A El meu diari, cada dia del calendari té un color segons la intensitat del mal de cap, amb marques per a la medicació per a les crisis i l'aura. A sota hi trobareu un resum del mes: hores de mal de cap, dies per intensitat i dies amb medicació.",
  "ABOUT_PAGE_3_TITLE": "Obteniu informació",
  "ABOUT_PAGE_3_TEXT": "Reviseu els vostres registres i obteniu una visió general a través del calendari, el diari i diversos gràfics; per exemple, com evoluciona el vostre ús de medicació amb el temps.",
  "ABOUT_PAGE_4_TITLE": "Les meves dades",
  "ABOUT_PAGE_4_TEXT": "Seguiu la intensitat del mal de cap al llarg del temps, vegeu com funciona cada medicació per a les crisis i descobriu quins factors es relacionen amb els vostres mals de cap, en períodes de fins a diversos anys.",
  "ABOUT_PAGE_5_TITLE": "Compartiu-ho amb el vostre metge",
  "ABOUT_PAGE_5_TEXT": "Compartiu fàcilment les vostres dades amb el vostre metge. L'aplicació genera un codi d'un sol ús que el metge introdueix a headachecalendar.com per veure els vostres registres.",
  "ABOUT_PAGE_6_TITLE": "Consells",
  "ABOUT_PAGE_6_TEXT": "Rebeu consells pràctics sobre el mal de cap, com ara els desencadenants més habituals i per què és important fer activitat física regular i dormir prou, també els caps de setmana.",
  "ABOUT_PAGE_7_TITLE": "Mode fosc",
  "ABOUT_PAGE_7_TEXT": "Sou sensible a la llum? Activeu el mode fosc. També podeu activar-lo o desactivar-lo més endavant a la configuració personal.",
  "ABOUT_PAGE_8_TITLE": "Ús de medicació",
  "ABOUT_PAGE_8_TEXT": "Vegeu quins medicaments heu pres i quan (medicació per a les crisis, tractament preventiu i injeccions) i com ha funcionat cada medicació per a les crisis.",
  "ABOUT_PAGE_9_TITLE": "Factors del mal de cap",
  "ABOUT_PAGE_9_TEXT": "Descobriu patrons en la gravetat, la migranya, l'aura, la menstruació i les crisis llargues o curtes, i seguiu el vostre ús d'analgèsics i triptans al llarg del temps."
 },
 "cs": {
  "LANDING_READ_MORE": "Více o aplikaci",
  "ABOUT_TITLE": "O aplikaci",
  "ABOUT_INTRO": "Přehled o dnech s bolestí hlavy, její intenzitě a užívání léků usnadňuje najít spolu s lékařem správnou léčbu. Aplikace vám pomůže mít vše pod kontrolou.",
  "ABOUT_STEP_OF": "{current} z {total}",
  "ABOUT_PREVIOUS": "Předchozí",
  "ABOUT_NEXT": "Další",
  "ABOUT_CLOSE": "Zavřít",
  "ABOUT_PAGE_1_TITLE": "Úvodní obrazovka",
  "ABOUT_PAGE_1_TEXT": "Stáhněte si aplikaci. Úvodní obrazovka přehledně ukazuje posledních 30 dní: dny bez bolesti, s mírnou, střední nebo silnou bolestí hlavy a dny, kdy jste užili akutní lék. Dnešní den zaznamenáte klepnutím na Denní záznam.",
  "ABOUT_PAGE_2_TITLE": "Kalendář",
  "ABOUT_PAGE_2_TEXT": "V sekci Můj deník je každý den v kalendáři zbarven podle intenzity bolesti hlavy, se značkami pro akutní léky a auru. Pod ním najdete souhrn měsíce: hodiny bolesti hlavy, dny podle intenzity a dny s léky.",
  "ABOUT_PAGE_3_TITLE": "Získejte přehled",
  "ABOUT_PAGE_3_TEXT": "Projděte si své záznamy a získejte přehled pomocí kalendáře, deníku a řady grafů – například jak se v čase vyvíjí vaše užívání léků.",
  "ABOUT_PAGE_4_TITLE": "Moje data",
  "ABOUT_PAGE_4_TEXT": "Sledujte intenzitu bolesti hlavy v čase, zjistěte, jak dobře účinkuje každý akutní lék, a odhalte, které faktory souvisejí s vašimi bolestmi hlavy – i za období několika let.",
  "ABOUT_PAGE_5_TITLE": "Sdílejte s lékařem",
  "ABOUT_PAGE_5_TEXT": "Snadno sdílejte svá data se svým lékařem. Aplikace vytvoří jednorázový kód, který lékař zadá na headachecalendar.com, aby viděl vaše záznamy.",
  "ABOUT_PAGE_6_TITLE": "Tipy",
  "ABOUT_PAGE_6_TEXT": "Získejte praktické tipy k bolesti hlavy, například o častých spouštěčích a o tom, proč je důležitý pravidelný pohyb a dostatek spánku – i o víkendu.",
  "ABOUT_PAGE_7_TITLE": "Tmavý režim",
  "ABOUT_PAGE_7_TEXT": "Vadí vám světlo? Zapněte tmavý režim. Později ho můžete zapnout nebo vypnout i v osobním nastavení.",
  "ABOUT_PAGE_8_TITLE": "Užívání léků",
  "ABOUT_PAGE_8_TEXT": "Podívejte se, které léky jste užívali a kdy – akutní léky, preventivní léky i injekce – a jak dobře jednotlivé akutní léky zabíraly.",
  "ABOUT_PAGE_9_TITLE": "Faktory bolesti hlavy",
  "ABOUT_PAGE_9_TEXT": "Odhalte souvislosti mezi závažností, migrénou, aurou, menstruací a dlouhými či krátkými záchvaty a sledujte užívání léků proti bolesti a triptanů v čase."
 },
 "da": {
  "LANDING_READ_MORE": "Læs mere om appen",
  "ABOUT_TITLE": "Om appen",
  "ABOUT_INTRO": "Et godt overblik over hovedpinedage, intensitet og medicinforbrug gør det lettere at finde den rette behandling sammen med din læge. Appen hjælper dig med at holde overblikket.",
  "ABOUT_STEP_OF": "{current} af {total}",
  "ABOUT_PREVIOUS": "Forrige",
  "ABOUT_NEXT": "Næste",
  "ABOUT_CLOSE": "Luk",
  "ABOUT_PAGE_1_TITLE": "Startskærm",
  "ABOUT_PAGE_1_TEXT": "Download appen. Startskærmen viser dine seneste 30 dage på et øjeblik: dage uden smerter, med let, moderat eller svær hovedpine, og dage hvor du tog anfaldsmedicin. Tryk på Daglig registrering for at registrere i dag.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "I Min dagbog er hver dag i kalenderen farvet efter hovedpinens intensitet, med markeringer for anfaldsmedicin og aura. Nedenunder får du en opsummering af måneden: timer med hovedpine, dage pr. intensitet og medicindage.",
  "ABOUT_PAGE_3_TITLE": "Få indsigt",
  "ABOUT_PAGE_3_TEXT": "Gennemgå dine registreringer og få overblik via kalenderen, dagbogen og en række grafer – for eksempel hvordan dit medicinforbrug udvikler sig over tid.",
  "ABOUT_PAGE_4_TITLE": "Mine data",
  "ABOUT_PAGE_4_TEXT": "Følg hovedpinens intensitet over tid, se hvor godt hver anfaldsmedicin virker, og find ud af, hvilke faktorer der hænger sammen med din hovedpine – for perioder på op til flere år.",
  "ABOUT_PAGE_5_TITLE": "Del med din læge",
  "ABOUT_PAGE_5_TEXT": "Del nemt dine data med din læge. Appen laver en engangskode, som lægen indtaster på headachecalendar.com for at se dine registreringer.",
  "ABOUT_PAGE_6_TITLE": "Råd",
  "ABOUT_PAGE_6_TEXT": "Få praktiske råd om hovedpine, for eksempel almindelige udløsende faktorer og hvorfor regelmæssig fysisk aktivitet og nok søvn er vigtigt – også i weekenden.",
  "ABOUT_PAGE_7_TITLE": "Mørk tilstand",
  "ABOUT_PAGE_7_TEXT": "Lysfølsom? Slå mørk tilstand til. Du kan også slå den til eller fra senere i dine personlige indstillinger.",
  "ABOUT_PAGE_8_TITLE": "Medicinforbrug",
  "ABOUT_PAGE_8_TEXT": "Se hvilken medicin du har brugt og hvornår – anfaldsmedicin, forebyggende medicin og injektioner – og hvor godt hver anfaldsmedicin har virket.",
  "ABOUT_PAGE_9_TITLE": "Hovedpinefaktorer",
  "ABOUT_PAGE_9_TEXT": "Se mønstre i sværhedsgrad, migræne, aura, menstruation og lange eller korte anfald, og følg dit forbrug af smertestillende medicin og triptaner over tid."
 },
 "de": {
  "LANDING_READ_MORE": "Mehr über die App erfahren",
  "ABOUT_TITLE": "Über die App",
  "ABOUT_INTRO": "Ein klarer Überblick über Kopfschmerztage, Intensität und Medikamenteneinnahme erleichtert es, gemeinsam mit Ihrer Ärztin oder Ihrem Arzt die passende Behandlung zu finden. Die App hilft Ihnen dabei.",
  "ABOUT_STEP_OF": "{current} von {total}",
  "ABOUT_PREVIOUS": "Zurück",
  "ABOUT_NEXT": "Weiter",
  "ABOUT_CLOSE": "Schließen",
  "ABOUT_PAGE_1_TITLE": "Startbildschirm",
  "ABOUT_PAGE_1_TEXT": "Laden Sie die App herunter. Der Startbildschirm zeigt Ihre letzten 30 Tage auf einen Blick: Tage ohne Schmerzen, mit leichten, mittelstarken oder starken Kopfschmerzen und Tage mit Akutmedikation. Tippen Sie auf Täglicher Eintrag, um den heutigen Tag zu erfassen.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "In Mein Tagebuch ist jeder Kalendertag nach Kopfschmerzintensität eingefärbt, mit Markierungen für Akutmedikation und Aura. Darunter finden Sie eine Monatsübersicht: Kopfschmerzstunden, Tage pro Intensität und Medikamententage.",
  "ABOUT_PAGE_3_TITLE": "Einblicke erhalten",
  "ABOUT_PAGE_3_TEXT": "Sehen Sie Ihre Einträge durch und behalten Sie den Überblick mit Kalender, Tagebuch und verschiedenen Diagrammen – zum Beispiel, wie sich Ihre Medikamenteneinnahme im Laufe der Zeit entwickelt.",
  "ABOUT_PAGE_4_TITLE": "Meine Daten",
  "ABOUT_PAGE_4_TEXT": "Verfolgen Sie die Kopfschmerzintensität im Zeitverlauf, sehen Sie, wie gut jedes Akutmedikament wirkt, und erkennen Sie, welche Faktoren mit Ihren Kopfschmerzen zusammenhängen – über Zeiträume von bis zu mehreren Jahren.",
  "ABOUT_PAGE_5_TITLE": "Mit der Arztpraxis teilen",
  "ABOUT_PAGE_5_TEXT": "Teilen Sie Ihre Daten ganz einfach mit Ihrer Ärztin oder Ihrem Arzt. Die App erstellt einen Einmalcode, der auf headachecalendar.com eingegeben wird, um Ihre Einträge einzusehen.",
  "ABOUT_PAGE_6_TITLE": "Tipps",
  "ABOUT_PAGE_6_TEXT": "Erhalten Sie praktische Tipps rund um Kopfschmerzen, etwa zu häufigen Auslösern und warum regelmäßige Bewegung und ausreichend Schlaf wichtig sind – auch am Wochenende.",
  "ABOUT_PAGE_7_TITLE": "Dunkelmodus",
  "ABOUT_PAGE_7_TEXT": "Lichtempfindlich? Aktivieren Sie den Dunkelmodus. Sie können ihn auch später in Ihren persönlichen Einstellungen ein- oder ausschalten.",
  "ABOUT_PAGE_8_TITLE": "Medikamenteneinnahme",
  "ABOUT_PAGE_8_TEXT": "Sehen Sie, welche Medikamente Sie wann eingenommen haben – Akutmedikation, vorbeugende Medikation und Injektionen – und wie gut jedes Akutmedikament gewirkt hat.",
  "ABOUT_PAGE_9_TITLE": "Kopfschmerzfaktoren",
  "ABOUT_PAGE_9_TEXT": "Erkennen Sie Muster bei Schweregrad, Migräne, Aura, Menstruation sowie langen oder kurzen Attacken, und verfolgen Sie Ihre Einnahme von Schmerzmitteln und Triptanen im Zeitverlauf."
 },
 "el": {
  "LANDING_READ_MORE": "Διαβάστε περισσότερα για την εφαρμογή",
  "ABOUT_TITLE": "Σχετικά με την εφαρμογή",
  "ABOUT_INTRO": "Μια σαφής εικόνα των ημερών με πονοκέφαλο, της έντασης και της χρήσης φαρμάκων διευκολύνει την εύρεση της κατάλληλης θεραπείας μαζί με τον γιατρό σας. Η εφαρμογή σάς βοηθά να έχετε τον έλεγχο.",
  "ABOUT_STEP_OF": "{current} από {total}",
  "ABOUT_PREVIOUS": "Προηγούμενο",
  "ABOUT_NEXT": "Επόμενο",
  "ABOUT_CLOSE": "Κλείσιμο",
  "ABOUT_PAGE_1_TITLE": "Αρχική οθόνη",
  "ABOUT_PAGE_1_TEXT": "Κατεβάστε την εφαρμογή. Η αρχική οθόνη δείχνει με μια ματιά τις τελευταίες 30 ημέρες: ημέρες χωρίς πόνο, με ήπιο, μέτριο ή έντονο πονοκέφαλο, καθώς και ημέρες που πήρατε φάρμακο για την κρίση. Πατήστε «Ημερήσια καταγραφή» για να καταγράψετε τη σημερινή ημέρα.",
  "ABOUT_PAGE_2_TITLE": "Ημερολόγιο",
  "ABOUT_PAGE_2_TEXT": "Στο «Το ημερολόγιό μου», κάθε ημέρα χρωματίζεται ανάλογα με την ένταση του πονοκεφάλου, με σημάνσεις για φάρμακα κρίσης και αύρα. Από κάτω βλέπετε μια σύνοψη του μήνα: ώρες πονοκεφάλου, ημέρες ανά ένταση και ημέρες με φάρμακα.",
  "ABOUT_PAGE_3_TITLE": "Αποκτήστε εικόνα",
  "ABOUT_PAGE_3_TEXT": "Δείτε τις καταγραφές σας και αποκτήστε συνολική εικόνα μέσα από το ημερολόγιο, την ενότητα «Το ημερολόγιό μου» και μια σειρά γραφημάτων – για παράδειγμα, πώς εξελίσσεται η χρήση φαρμάκων με τον καιρό.",
  "ABOUT_PAGE_4_TITLE": "Τα δεδομένα μου",
  "ABOUT_PAGE_4_TEXT": "Παρακολουθήστε την ένταση του πονοκεφάλου στον χρόνο, δείτε πόσο καλά δρα κάθε φάρμακο κρίσης και εντοπίστε ποιοι παράγοντες συνδέονται με τους πονοκεφάλους σας – για περιόδους έως και αρκετών ετών.",
  "ABOUT_PAGE_5_TITLE": "Μοιραστείτε με τον γιατρό σας",
  "ABOUT_PAGE_5_TEXT": "Μοιραστείτε εύκολα τα δεδομένα σας με τον γιατρό σας. Η εφαρμογή δημιουργεί έναν κωδικό μίας χρήσης, τον οποίο ο γιατρός σας εισάγει στο headachecalendar.com για να δει τις καταγραφές σας.",
  "ABOUT_PAGE_6_TITLE": "Συμβουλές",
  "ABOUT_PAGE_6_TEXT": "Λάβετε πρακτικές συμβουλές για τον πονοκέφαλο, όπως οι συνηθισμένοι εκλυτικοί παράγοντες και γιατί έχουν σημασία η τακτική σωματική δραστηριότητα και ο επαρκής ύπνος – και τα Σαββατοκύριακα.",
  "ABOUT_PAGE_7_TITLE": "Σκοτεινή λειτουργία",
  "ABOUT_PAGE_7_TEXT": "Είστε ευαίσθητοι στο φως; Ενεργοποιήστε τη σκοτεινή λειτουργία. Μπορείτε επίσης να την ενεργοποιήσετε ή να την απενεργοποιήσετε αργότερα στις προσωπικές σας ρυθμίσεις.",
  "ABOUT_PAGE_8_TITLE": "Χρήση φαρμάκων",
  "ABOUT_PAGE_8_TEXT": "Δείτε ποια φάρμακα έχετε πάρει και πότε – φάρμακα κρίσης, προληπτικά φάρμακα και ενέσεις – και πόσο καλά έχει δράσει κάθε φάρμακο κρίσης.",
  "ABOUT_PAGE_9_TITLE": "Παράγοντες πονοκεφάλου",
  "ABOUT_PAGE_9_TEXT": "Δείτε μοτίβα ως προς τη σοβαρότητα, την ημικρανία, την αύρα, την έμμηνο ρύση και τις μεγάλες ή σύντομες κρίσεις, και παρακολουθήστε τη χρήση παυσίπονων και τριπτανών στον χρόνο."
 },
 "en": {
  "LANDING_READ_MORE": "Read more about the app",
  "ABOUT_TITLE": "About the app",
  "ABOUT_INTRO": "A clear overview of headache days, intensity and medication use makes it easier to find the right treatment together with your doctor. The app helps you keep track.",
  "ABOUT_STEP_OF": "{current} of {total}",
  "ABOUT_PREVIOUS": "Previous",
  "ABOUT_NEXT": "Next",
  "ABOUT_CLOSE": "Close",
  "ABOUT_PAGE_1_TITLE": "Home screen",
  "ABOUT_PAGE_1_TEXT": "Download the app. The home screen shows your last 30 days at a glance: days without pain, with mild, moderate or severe headache, and days you took acute medication. Tap Daily entry to log today.",
  "ABOUT_PAGE_2_TITLE": "Calendar",
  "ABOUT_PAGE_2_TEXT": "In My diary, each day in the calendar is coloured by headache intensity, with markers for acute medication and aura. Below it you get a summary of the month: headache hours, days per intensity and medication days.",
  "ABOUT_PAGE_3_TITLE": "Get insights",
  "ABOUT_PAGE_3_TEXT": "Review your registrations and get an overview through the calendar, the diary and a range of charts – for example how your medication use develops over time.",
  "ABOUT_PAGE_4_TITLE": "My data",
  "ABOUT_PAGE_4_TEXT": "Follow headache intensity over time, see how well each acute medication works, and spot which factors go together with your headaches – for periods of up to several years.",
  "ABOUT_PAGE_5_TITLE": "Share with your doctor",
  "ABOUT_PAGE_5_TEXT": "Share your data easily with your doctor. The app creates a one-time code that your doctor enters at headachecalendar.com to see your registrations.",
  "ABOUT_PAGE_6_TITLE": "Tips",
  "ABOUT_PAGE_6_TEXT": "Get practical tips about headache, such as common triggers and why regular physical activity and enough sleep matter – also at weekends.",
  "ABOUT_PAGE_7_TITLE": "Dark mode",
  "ABOUT_PAGE_7_TEXT": "Sensitive to light? Turn on dark mode. You can also switch it on or off later in your personal settings.",
  "ABOUT_PAGE_8_TITLE": "Medication use",
  "ABOUT_PAGE_8_TEXT": "See which medicines you have used and when – acute medication, preventive medication and injections – and how well each acute medication has worked.",
  "ABOUT_PAGE_9_TITLE": "Headache factors",
  "ABOUT_PAGE_9_TEXT": "See patterns in severity, migraine, aura, menstruation and long or short attacks, and follow your use of painkillers and triptans over time."
 },
 "es": {
  "LANDING_READ_MORE": "Más información sobre la aplicación",
  "ABOUT_TITLE": "Acerca de la aplicación",
  "ABOUT_INTRO": "Tener una visión clara de los días con dolor de cabeza, su intensidad y el uso de medicación facilita encontrar el tratamiento adecuado junto con su médico. La aplicación le ayuda a llevar el control.",
  "ABOUT_STEP_OF": "{current} de {total}",
  "ABOUT_PREVIOUS": "Anterior",
  "ABOUT_NEXT": "Siguiente",
  "ABOUT_CLOSE": "Cerrar",
  "ABOUT_PAGE_1_TITLE": "Pantalla de inicio",
  "ABOUT_PAGE_1_TEXT": "Descargue la aplicación. La pantalla de inicio muestra sus últimos 30 días de un vistazo: días sin dolor, con dolor de cabeza leve, moderado o intenso, y días en que tomó medicación para las crisis. Pulse Registro diario para anotar el día de hoy.",
  "ABOUT_PAGE_2_TITLE": "Calendario",
  "ABOUT_PAGE_2_TEXT": "En Mi diario, cada día del calendario se colorea según la intensidad del dolor de cabeza, con marcas para la medicación para las crisis y el aura. Debajo verá un resumen del mes: horas de dolor, días por intensidad y días con medicación.",
  "ABOUT_PAGE_3_TITLE": "Obtenga información",
  "ABOUT_PAGE_3_TEXT": "Revise sus registros y obtenga una visión general a través del calendario, el diario y diversos gráficos, por ejemplo, cómo evoluciona su uso de medicación con el tiempo.",
  "ABOUT_PAGE_4_TITLE": "Mis datos",
  "ABOUT_PAGE_4_TEXT": "Siga la intensidad del dolor de cabeza a lo largo del tiempo, vea lo eficaz que es cada medicación para las crisis y descubra qué factores se relacionan con sus dolores de cabeza, en periodos de hasta varios años.",
  "ABOUT_PAGE_5_TITLE": "Compartir con su médico",
  "ABOUT_PAGE_5_TEXT": "Comparta sus datos fácilmente con su médico. La aplicación genera un código de un solo uso que su médico introduce en headachecalendar.com para ver sus registros.",
  "ABOUT_PAGE_6_TITLE": "Consejos",
  "ABOUT_PAGE_6_TEXT": "Reciba consejos prácticos sobre el dolor de cabeza, como los desencadenantes más comunes y por qué son importantes la actividad física regular y dormir lo suficiente, también los fines de semana.",
  "ABOUT_PAGE_7_TITLE": "Modo oscuro",
  "ABOUT_PAGE_7_TEXT": "¿Le molesta la luz? Active el modo oscuro. También puede activarlo o desactivarlo más adelante en sus ajustes personales.",
  "ABOUT_PAGE_8_TITLE": "Uso de medicación",
  "ABOUT_PAGE_8_TEXT": "Vea qué medicamentos ha tomado y cuándo (medicación para las crisis, tratamiento preventivo e inyecciones) y lo bien que ha funcionado cada medicación para las crisis.",
  "ABOUT_PAGE_9_TITLE": "Factores del dolor de cabeza",
  "ABOUT_PAGE_9_TEXT": "Descubra patrones en la gravedad, la migraña, el aura, la menstruación y las crisis largas o cortas, y siga su uso de analgésicos y triptanes a lo largo del tiempo."
 },
 "et": {
  "LANDING_READ_MORE": "Loe rakendusest lähemalt",
  "ABOUT_TITLE": "Rakendusest",
  "ABOUT_INTRO": "Selge ülevaade peavalupäevadest, valu tugevusest ja ravimite kasutamisest aitab koos arstiga leida sobiva ravi. Rakendus aitab teil ülevaadet hoida.",
  "ABOUT_STEP_OF": "{current} / {total}",
  "ABOUT_PREVIOUS": "Eelmine",
  "ABOUT_NEXT": "Järgmine",
  "ABOUT_CLOSE": "Sulge",
  "ABOUT_PAGE_1_TITLE": "Avaleht",
  "ABOUT_PAGE_1_TEXT": "Laadige rakendus alla. Avaleht näitab teie viimast 30 päeva ühe pilguga: valuta päevi, kerge, mõõduka või tugeva peavaluga päevi ning päevi, mil võtsite hooravimit. Tänase päeva sisestamiseks puudutage nuppu Igapäevane sissekanne.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "Jaotises Minu päevik on iga kalendripäev värvitud peavalu tugevuse järgi ning tähistatud on hooravimid ja aura. Allpool näete kuu kokkuvõtet: peavalutunnid, päevad tugevuse järgi ja ravimipäevad.",
  "ABOUT_PAGE_3_TITLE": "Saage ülevaade",
  "ABOUT_PAGE_3_TEXT": "Vaadake oma sissekanded üle ja saage ülevaade kalendri, päeviku ja mitmesuguste graafikute abil – näiteks selle kohta, kuidas teie ravimite kasutamine aja jooksul muutub.",
  "ABOUT_PAGE_4_TITLE": "Minu andmed",
  "ABOUT_PAGE_4_TEXT": "Jälgige peavalu tugevust ajas, vaadake, kui hästi iga hooravim mõjub, ja märgake, millised tegurid on seotud teie peavaluga – kuni mitme aasta pikkuste perioodide kohta.",
  "ABOUT_PAGE_5_TITLE": "Jagage arstiga",
  "ABOUT_PAGE_5_TEXT": "Jagage oma andmeid lihtsalt arstiga. Rakendus loob ühekordse koodi, mille arst sisestab aadressil headachecalendar.com, et näha teie sissekandeid.",
  "ABOUT_PAGE_6_TITLE": "Nõuanded",
  "ABOUT_PAGE_6_TEXT": "Saage praktilisi nõuandeid peavalu kohta, näiteks levinud vallandajate kohta ja selle kohta, miks regulaarne liikumine ja piisav uni on olulised – ka nädalavahetustel.",
  "ABOUT_PAGE_7_TITLE": "Tume režiim",
  "ABOUT_PAGE_7_TEXT": "Olete valgustundlik? Lülitage sisse tume režiim. Saate selle hiljem ka isiklikes seadetes sisse või välja lülitada.",
  "ABOUT_PAGE_8_TITLE": "Ravimite kasutamine",
  "ABOUT_PAGE_8_TEXT": "Vaadake, milliseid ravimeid ja millal olete kasutanud – hooravimid, ennetavad ravimid ja süstid – ning kui hästi iga hooravim on mõjunud.",
  "ABOUT_PAGE_9_TITLE": "Peavalu tegurid",
  "ABOUT_PAGE_9_TEXT": "Märgake mustreid raskusastmes, migreenis, auras, menstruatsioonis ning pikkades või lühikestes hoogudes ja jälgige valuvaigistite ja triptaanide kasutamist ajas."
 },
 "fi": {
  "LANDING_READ_MORE": "Lue lisää sovelluksesta",
  "ABOUT_TITLE": "Tietoa sovelluksesta",
  "ABOUT_INTRO": "Selkeä kokonaiskuva päänsärkypäivistä, kivun voimakkuudesta ja lääkkeiden käytöstä helpottaa oikean hoidon löytämistä yhdessä lääkärisi kanssa. Sovellus auttaa sinua pysymään kärryillä.",
  "ABOUT_STEP_OF": "{current} / {total}",
  "ABOUT_PREVIOUS": "Edellinen",
  "ABOUT_NEXT": "Seuraava",
  "ABOUT_CLOSE": "Sulje",
  "ABOUT_PAGE_1_TITLE": "Aloitusnäyttö",
  "ABOUT_PAGE_1_TEXT": "Lataa sovellus. Aloitusnäytöltä näet viimeiset 30 päivääsi yhdellä silmäyksellä: kivuttomat päivät, lievän, kohtalaisen tai voimakkaan päänsäryn päivät sekä päivät, jolloin otit kohtauslääkettä. Kirjaa tämä päivä napauttamalla Päivittäinen kirjaus.",
  "ABOUT_PAGE_2_TITLE": "Kalenteri",
  "ABOUT_PAGE_2_TEXT": "Oma päiväkirja -näkymässä jokainen kalenterin päivä on väritetty päänsäryn voimakkuuden mukaan, ja kohtauslääkkeet ja aura on merkitty. Sen alla näet kuukauden yhteenvedon: päänsärkytunnit, päivät voimakkuuksittain ja lääkepäivät.",
  "ABOUT_PAGE_3_TITLE": "Saa kokonaiskuva",
  "ABOUT_PAGE_3_TEXT": "Käy kirjauksesi läpi ja saa kokonaiskuva kalenterin, päiväkirjan ja erilaisten kaavioiden avulla – esimerkiksi siitä, miten lääkkeiden käyttösi kehittyy ajan myötä.",
  "ABOUT_PAGE_4_TITLE": "Omat tiedot",
  "ABOUT_PAGE_4_TEXT": "Seuraa päänsäryn voimakkuutta ajan mittaan, katso, miten hyvin kukin kohtauslääke tehoaa, ja huomaa, mitkä tekijät liittyvät päänsärkyysi – jopa usean vuoden ajanjaksoilta.",
  "ABOUT_PAGE_5_TITLE": "Jaa lääkärillesi",
  "ABOUT_PAGE_5_TEXT": "Jaa tietosi helposti lääkärisi kanssa. Sovellus luo kertakäyttöisen koodin, jonka lääkäri syöttää osoitteessa headachecalendar.com nähdäkseen kirjauksesi.",
  "ABOUT_PAGE_6_TITLE": "Vinkit",
  "ABOUT_PAGE_6_TEXT": "Saa käytännön vinkkejä päänsärkyyn, kuten yleisistä laukaisevista tekijöistä ja siitä, miksi säännöllinen liikunta ja riittävä uni ovat tärkeitä – myös viikonloppuisin.",
  "ABOUT_PAGE_7_TITLE": "Tumma tila",
  "ABOUT_PAGE_7_TEXT": "Oletko valoherkkä? Ota tumma tila käyttöön. Voit myös ottaa sen käyttöön tai poistaa sen käytöstä myöhemmin henkilökohtaisista asetuksista.",
  "ABOUT_PAGE_8_TITLE": "Lääkkeiden käyttö",
  "ABOUT_PAGE_8_TEXT": "Katso, mitä lääkkeitä olet käyttänyt ja milloin – kohtauslääkkeet, estolääkkeet ja pistokset – sekä kuinka hyvin kukin kohtauslääke on tehonnut.",
  "ABOUT_PAGE_9_TITLE": "Päänsärkytekijät",
  "ABOUT_PAGE_9_TEXT": "Näe toistuvat kaavat vaikeusasteessa, migreenissä, aurassa, kuukautisissa sekä pitkissä tai lyhyissä kohtauksissa, ja seuraa kipulääkkeiden ja triptaanien käyttöäsi ajan mittaan."
 },
 "fr": {
  "LANDING_READ_MORE": "En savoir plus sur l'application",
  "ABOUT_TITLE": "À propos de l'application",
  "ABOUT_INTRO": "Avoir une vue claire des jours de céphalée, de leur intensité et de la prise de médicaments permet de trouver plus facilement le bon traitement avec votre médecin. L'application vous aide à faire le suivi.",
  "ABOUT_STEP_OF": "{current} sur {total}",
  "ABOUT_PREVIOUS": "Précédent",
  "ABOUT_NEXT": "Suivant",
  "ABOUT_CLOSE": "Fermer",
  "ABOUT_PAGE_1_TITLE": "Écran d'accueil",
  "ABOUT_PAGE_1_TEXT": "Téléchargez l'application. L'écran d'accueil affiche vos 30 derniers jours en un coup d'œil : jours sans douleur, avec céphalée légère, modérée ou sévère, et jours de prise d'un traitement de crise. Touchez Saisie du jour pour noter la journée.",
  "ABOUT_PAGE_2_TITLE": "Calendrier",
  "ABOUT_PAGE_2_TEXT": "Dans Mon journal, chaque jour du calendrier est coloré selon l'intensité de la céphalée, avec des repères pour le traitement de crise et l'aura. En dessous, vous trouvez un résumé du mois : heures de céphalée, jours par intensité et jours avec médicaments.",
  "ABOUT_PAGE_3_TITLE": "Mieux comprendre",
  "ABOUT_PAGE_3_TEXT": "Consultez vos saisies et obtenez une vue d'ensemble grâce au calendrier, au journal et à divers graphiques – par exemple l'évolution de votre prise de médicaments dans le temps.",
  "ABOUT_PAGE_4_TITLE": "Mes données",
  "ABOUT_PAGE_4_TEXT": "Suivez l'intensité de vos céphalées dans le temps, voyez l'efficacité de chaque traitement de crise et repérez les facteurs associés à vos maux de tête – sur des périodes allant jusqu'à plusieurs années.",
  "ABOUT_PAGE_5_TITLE": "Partager avec votre médecin",
  "ABOUT_PAGE_5_TEXT": "Partagez facilement vos données avec votre médecin. L'application génère un code à usage unique que votre médecin saisit sur headachecalendar.com pour consulter vos saisies.",
  "ABOUT_PAGE_6_TITLE": "Conseils",
  "ABOUT_PAGE_6_TEXT": "Recevez des conseils pratiques sur les céphalées, comme les déclencheurs fréquents et l'importance d'une activité physique régulière et d'un sommeil suffisant – y compris le week-end.",
  "ABOUT_PAGE_7_TITLE": "Mode sombre",
  "ABOUT_PAGE_7_TEXT": "Sensible à la lumière ? Activez le mode sombre. Vous pourrez aussi l'activer ou le désactiver plus tard dans vos paramètres personnels.",
  "ABOUT_PAGE_8_TITLE": "Prise de médicaments",
  "ABOUT_PAGE_8_TEXT": "Voyez quels médicaments vous avez pris et quand – traitement de crise, traitement de fond et injections – et l'efficacité de chaque traitement de crise.",
  "ABOUT_PAGE_9_TITLE": "Facteurs de céphalée",
  "ABOUT_PAGE_9_TEXT": "Repérez des tendances concernant la sévérité, la migraine, l'aura, les règles et les crises longues ou courtes, et suivez votre consommation d'antalgiques et de triptans dans le temps."
 },
 "he": {
  "LANDING_READ_MORE": "מידע נוסף על האפליקציה",
  "ABOUT_TITLE": "אודות האפליקציה",
  "ABOUT_INTRO": "תמונה ברורה של ימי כאב הראש, עוצמת הכאב והשימוש בתרופות מקלה על מציאת הטיפול המתאים יחד עם הרופא. האפליקציה עוזרת לכם לעקוב אחר הכול.",
  "ABOUT_STEP_OF": "{current} מתוך {total}",
  "ABOUT_PREVIOUS": "הקודם",
  "ABOUT_NEXT": "הבא",
  "ABOUT_CLOSE": "סגירה",
  "ABOUT_PAGE_1_TITLE": "מסך הבית",
  "ABOUT_PAGE_1_TEXT": "הורידו את האפליקציה. מסך הבית מציג במבט אחד את 30 הימים האחרונים: ימים ללא כאב, ימים עם כאב ראש קל, בינוני או חזק, וימים שבהם נטלתם תרופה להתקף. הקישו על \"רישום יומי\" כדי לתעד את היום.",
  "ABOUT_PAGE_2_TITLE": "לוח שנה",
  "ABOUT_PAGE_2_TEXT": "ב\"היומן שלי\" כל יום בלוח השנה צבוע לפי עוצמת כאב הראש, עם סימון של תרופה להתקף ושל אאורה. מתחתיו מוצג סיכום החודש: שעות כאב ראש, ימים לפי עוצמה וימי שימוש בתרופות.",
  "ABOUT_PAGE_3_TITLE": "קבלו תובנות",
  "ABOUT_PAGE_3_TEXT": "עברו על הרישומים שלכם וקבלו תמונה כוללת דרך לוח השנה, היומן ומגוון תרשימים – למשל, איך השימוש שלכם בתרופות משתנה לאורך זמן.",
  "ABOUT_PAGE_4_TITLE": "הנתונים שלי",
  "ABOUT_PAGE_4_TEXT": "עקבו אחר עוצמת כאב הראש לאורך זמן, ראו עד כמה כל תרופה להתקף יעילה, וגלו אילו גורמים קשורים לכאבי הראש שלכם – לתקופות של עד כמה שנים.",
  "ABOUT_PAGE_5_TITLE": "שיתוף עם הרופא",
  "ABOUT_PAGE_5_TEXT": "שתפו את הנתונים שלכם עם הרופא בקלות. האפליקציה יוצרת קוד חד־פעמי שהרופא מזין באתר headachecalendar.com כדי לצפות ברישומים שלכם.",
  "ABOUT_PAGE_6_TITLE": "טיפים",
  "ABOUT_PAGE_6_TEXT": "קבלו טיפים מעשיים על כאבי ראש, כמו גורמים מעוררים נפוצים, ולמה פעילות גופנית סדירה ושינה מספקת חשובות – גם בסופי שבוע.",
  "ABOUT_PAGE_7_TITLE": "מצב כהה",
  "ABOUT_PAGE_7_TEXT": "רגישים לאור? הפעילו מצב כהה. אפשר גם להפעיל או לכבות אותו בהמשך בהגדרות האישיות.",
  "ABOUT_PAGE_8_TITLE": "שימוש בתרופות",
  "ABOUT_PAGE_8_TEXT": "ראו באילו תרופות השתמשתם ומתי – תרופות להתקף, תרופות מונעות וזריקות – ועד כמה כל תרופה להתקף הועילה.",
  "ABOUT_PAGE_9_TITLE": "גורמי כאב ראש",
  "ABOUT_PAGE_9_TEXT": "זהו דפוסים בחומרה, במיגרנה, באאורה, במחזור ובהתקפים ארוכים או קצרים, ועקבו אחר השימוש במשככי כאבים ובטריפטנים לאורך זמן."
 },
 "hr": {
  "LANDING_READ_MORE": "Saznajte više o aplikaciji",
  "ABOUT_TITLE": "O aplikaciji",
  "ABOUT_INTRO": "Jasan pregled dana s glavoboljom, njezina intenziteta i uzimanja lijekova olakšava pronalaženje prave terapije zajedno s Vašim liječnikom. Aplikacija Vam pomaže da sve pratite.",
  "ABOUT_STEP_OF": "{current} od {total}",
  "ABOUT_PREVIOUS": "Prethodno",
  "ABOUT_NEXT": "Sljedeće",
  "ABOUT_CLOSE": "Zatvori",
  "ABOUT_PAGE_1_TITLE": "Početni zaslon",
  "ABOUT_PAGE_1_TEXT": "Preuzmite aplikaciju. Početni zaslon na prvi pogled prikazuje Vaših posljednjih 30 dana: dane bez boli, s blagom, umjerenom ili jakom glavoboljom te dane kad ste uzeli lijek za napadaj. Dodirnite Dnevni unos da biste zabilježili današnji dan.",
  "ABOUT_PAGE_2_TITLE": "Kalendar",
  "ABOUT_PAGE_2_TEXT": "U odjeljku Moj dnevnik svaki je dan u kalendaru obojen prema intenzitetu glavobolje, s oznakama za lijekove za napadaj i auru. Ispod se nalazi sažetak mjeseca: sati glavobolje, dani po intenzitetu i dani s lijekovima.",
  "ABOUT_PAGE_3_TITLE": "Steknite uvid",
  "ABOUT_PAGE_3_TEXT": "Pregledajte svoje unose i steknite pregled putem kalendara, dnevnika i niza grafikona – primjerice kako se Vaše uzimanje lijekova mijenja tijekom vremena.",
  "ABOUT_PAGE_4_TITLE": "Moji podaci",
  "ABOUT_PAGE_4_TEXT": "Pratite intenzitet glavobolje tijekom vremena, pogledajte koliko dobro djeluje svaki lijek za napadaj i otkrijte koji su čimbenici povezani s Vašim glavoboljama – za razdoblja i do nekoliko godina.",
  "ABOUT_PAGE_5_TITLE": "Podijelite s liječnikom",
  "ABOUT_PAGE_5_TEXT": "Jednostavno podijelite svoje podatke s liječnikom. Aplikacija izrađuje jednokratni kod koji liječnik unosi na headachecalendar.com kako bi vidio Vaše unose.",
  "ABOUT_PAGE_6_TITLE": "Savjeti",
  "ABOUT_PAGE_6_TEXT": "Dobijte praktične savjete o glavobolji, primjerice o čestim okidačima i zašto su redovita tjelesna aktivnost i dovoljno sna važni – i vikendom.",
  "ABOUT_PAGE_7_TITLE": "Tamni način",
  "ABOUT_PAGE_7_TEXT": "Osjetljivi ste na svjetlo? Uključite tamni način. Možete ga i kasnije uključiti ili isključiti u osobnim postavkama.",
  "ABOUT_PAGE_8_TITLE": "Uzimanje lijekova",
  "ABOUT_PAGE_8_TEXT": "Pogledajte koje ste lijekove uzimali i kada – lijekove za napadaj, preventivne lijekove i injekcije – te koliko je dobro djelovao svaki lijek za napadaj.",
  "ABOUT_PAGE_9_TITLE": "Čimbenici glavobolje",
  "ABOUT_PAGE_9_TEXT": "Uočite obrasce u jačini, migreni, auri, menstruaciji te dugim ili kratkim napadajima i pratite uzimanje lijekova protiv bolova i triptana tijekom vremena."
 },
 "hu": {
  "LANDING_READ_MORE": "Bővebben az alkalmazásról",
  "ABOUT_TITLE": "Az alkalmazásról",
  "ABOUT_INTRO": "A fejfájásos napok, a fájdalom erőssége és a gyógyszerhasználat áttekinthető nyilvántartása megkönnyíti, hogy orvosával közösen megtalálják a megfelelő kezelést. Az alkalmazás segít mindent nyomon követni.",
  "ABOUT_STEP_OF": "{current} / {total}",
  "ABOUT_PREVIOUS": "Előző",
  "ABOUT_NEXT": "Következő",
  "ABOUT_CLOSE": "Bezárás",
  "ABOUT_PAGE_1_TITLE": "Kezdőképernyő",
  "ABOUT_PAGE_1_TEXT": "Töltse le az alkalmazást. A kezdőképernyő egy pillantással mutatja az elmúlt 30 napot: a fájdalommentes napokat, az enyhe, közepes vagy erős fejfájással járó napokat, valamint azokat, amikor rohamoldó gyógyszert vett be. A mai nap rögzítéséhez koppintson a „Napi bejegyzés” gombra.",
  "ABOUT_PAGE_2_TITLE": "Naptár",
  "ABOUT_PAGE_2_TEXT": "A „Naplóm” részben a naptár minden napja a fejfájás erőssége szerint színezett, a rohamoldó gyógyszer és az aura jelölésével. Alatta a hónap összesítése látható: fejfájásos órák, napok erősség szerint és gyógyszeres napok.",
  "ABOUT_PAGE_3_TITLE": "Szerezzen betekintést",
  "ABOUT_PAGE_3_TEXT": "Tekintse át bejegyzéseit, és kapjon áttekintést a naptár, a napló és számos grafikon segítségével – például arról, hogyan alakul gyógyszerhasználata az idő során.",
  "ABOUT_PAGE_4_TITLE": "Adataim",
  "ABOUT_PAGE_4_TEXT": "Kövesse a fejfájás erősségét az idő során, nézze meg, mennyire hatnak az egyes rohamoldó gyógyszerek, és fedezze fel, mely tényezők járnak együtt a fejfájásával – akár több évre visszamenőleg.",
  "ABOUT_PAGE_5_TITLE": "Megosztás orvosával",
  "ABOUT_PAGE_5_TEXT": "Ossza meg adatait egyszerűen orvosával. Az alkalmazás egyszer használatos kódot hoz létre, amelyet orvosa a headachecalendar.com oldalon ad meg, hogy megtekintse bejegyzéseit.",
  "ABOUT_PAGE_6_TITLE": "Tippek",
  "ABOUT_PAGE_6_TEXT": "Kapjon gyakorlati tippeket a fejfájásról, például a gyakori kiváltó okokról, és arról, miért fontos a rendszeres testmozgás és az elegendő alvás – hétvégén is.",
  "ABOUT_PAGE_7_TITLE": "Sötét mód",
  "ABOUT_PAGE_7_TEXT": "Érzékeny a fényre? Kapcsolja be a sötét módot. Később a személyes beállításokban is be- vagy kikapcsolhatja.",
  "ABOUT_PAGE_8_TITLE": "Gyógyszerhasználat",
  "ABOUT_PAGE_8_TEXT": "Nézze meg, mely gyógyszereket és mikor használta – rohamoldó és megelőző gyógyszereket, valamint injekciókat –, és mennyire hatottak az egyes rohamoldó gyógyszerek.",
  "ABOUT_PAGE_9_TITLE": "Fejfájást befolyásoló tényezők",
  "ABOUT_PAGE_9_TEXT": "Ismerje fel a mintázatokat a súlyosság, a migrén, az aura, a menstruáció és a hosszú vagy rövid rohamok terén, és kövesse a fájdalomcsillapítók és triptánok használatát az idő során."
 },
 "is": {
  "LANDING_READ_MORE": "Lesa meira um appið",
  "ABOUT_TITLE": "Um appið",
  "ABOUT_INTRO": "Góð yfirsýn yfir höfuðverkjadaga, styrk og lyfjanotkun auðveldar þér að finna rétta meðferð í samráði við lækninn þinn. Appið hjálpar þér að halda utan um þetta.",
  "ABOUT_STEP_OF": "{current} af {total}",
  "ABOUT_PREVIOUS": "Fyrri",
  "ABOUT_NEXT": "Næsta",
  "ABOUT_CLOSE": "Loka",
  "ABOUT_PAGE_1_TITLE": "Upphafsskjár",
  "ABOUT_PAGE_1_TEXT": "Sæktu appið. Upphafsskjárinn sýnir síðustu 30 daga í hnotskurn: daga án verkja, með vægan, miðlungs eða slæman höfuðverk, og daga sem þú tókst bráðalyf. Ýttu á Dagleg skráning til að skrá daginn í dag.",
  "ABOUT_PAGE_2_TITLE": "Dagatal",
  "ABOUT_PAGE_2_TEXT": "Undir Dagbókin mín er hver dagur í dagatalinu litaður eftir styrk höfuðverksins, með merkjum fyrir bráðalyf og áru. Fyrir neðan færðu samantekt mánaðarins: klukkustundir með höfuðverk, daga eftir styrk og lyfjadaga.",
  "ABOUT_PAGE_3_TITLE": "Fáðu innsýn",
  "ABOUT_PAGE_3_TEXT": "Farðu yfir skráningarnar þínar og fáðu yfirsýn í gegnum dagatalið, dagbókina og ýmis gröf – til dæmis hvernig lyfjanotkun þín þróast með tímanum.",
  "ABOUT_PAGE_4_TITLE": "Mín gögn",
  "ABOUT_PAGE_4_TEXT": "Fylgstu með styrk höfuðverksins yfir tíma, sjáðu hversu vel hvert bráðalyf virkar og komdu auga á hvaða þættir tengjast höfuðverknum þínum – fyrir tímabil allt að nokkrum árum.",
  "ABOUT_PAGE_5_TITLE": "Deildu með lækninum",
  "ABOUT_PAGE_5_TEXT": "Deildu gögnunum þínum auðveldlega með lækninum þínum. Appið býr til einnota kóða sem læknirinn slær inn á headachecalendar.com til að sjá skráningarnar þínar.",
  "ABOUT_PAGE_6_TITLE": "Ráð",
  "ABOUT_PAGE_6_TEXT": "Fáðu hagnýt ráð um höfuðverk, svo sem algenga kveikjuþætti og hvers vegna regluleg hreyfing og nægur svefn skipta máli – líka um helgar.",
  "ABOUT_PAGE_7_TITLE": "Dökk stilling",
  "ABOUT_PAGE_7_TEXT": "Truflar birtan þig? Kveiktu á dökkri stillingu. Þú getur líka kveikt eða slökkt á henni síðar í persónulegum stillingum.",
  "ABOUT_PAGE_8_TITLE": "Lyfjanotkun",
  "ABOUT_PAGE_8_TEXT": "Sjáðu hvaða lyf þú hefur notað og hvenær – bráðalyf, fyrirbyggjandi lyf og sprautur – og hversu vel hvert bráðalyf hefur virkað.",
  "ABOUT_PAGE_9_TITLE": "Höfuðverkjaþættir",
  "ABOUT_PAGE_9_TEXT": "Sjáðu mynstur í alvarleika, mígreni, áru, tíðablæðingum og löngum eða stuttum köstum, og fylgstu með notkun verkjalyfja og triptana yfir tíma."
 },
 "it": {
  "LANDING_READ_MORE": "Scopri di più sull'app",
  "ABOUT_TITLE": "Informazioni sull'app",
  "ABOUT_INTRO": "Una visione chiara dei giorni di mal di testa, della loro intensità e dell'uso di farmaci rende più facile trovare la terapia giusta insieme al Suo medico. L'app La aiuta a tenere tutto sotto controllo.",
  "ABOUT_STEP_OF": "{current} di {total}",
  "ABOUT_PREVIOUS": "Indietro",
  "ABOUT_NEXT": "Avanti",
  "ABOUT_CLOSE": "Chiudi",
  "ABOUT_PAGE_1_TITLE": "Schermata iniziale",
  "ABOUT_PAGE_1_TEXT": "Scarichi l'app. La schermata iniziale mostra a colpo d'occhio gli ultimi 30 giorni: giorni senza dolore, con mal di testa lieve, moderato o forte, e giorni in cui ha assunto farmaci per l'attacco. Tocchi Registrazione giornaliera per annotare la giornata di oggi.",
  "ABOUT_PAGE_2_TITLE": "Calendario",
  "ABOUT_PAGE_2_TEXT": "In Il mio diario, ogni giorno del calendario è colorato in base all'intensità del mal di testa, con indicatori per i farmaci per l'attacco e l'aura. Sotto trova un riepilogo del mese: ore di mal di testa, giorni per intensità e giorni con farmaci.",
  "ABOUT_PAGE_3_TITLE": "Approfondisca",
  "ABOUT_PAGE_3_TEXT": "Riveda le Sue registrazioni e ottenga una panoramica tramite il calendario, il diario e diversi grafici, ad esempio come cambia nel tempo il Suo uso di farmaci.",
  "ABOUT_PAGE_4_TITLE": "I miei dati",
  "ABOUT_PAGE_4_TEXT": "Segua l'intensità del mal di testa nel tempo, veda quanto funziona ciascun farmaco per l'attacco e individui i fattori legati al Suo mal di testa, su periodi fino a diversi anni.",
  "ABOUT_PAGE_5_TITLE": "Condivida con il Suo medico",
  "ABOUT_PAGE_5_TEXT": "Condivida facilmente i Suoi dati con il medico. L'app crea un codice monouso che il medico inserisce su headachecalendar.com per vedere le Sue registrazioni.",
  "ABOUT_PAGE_6_TITLE": "Consigli",
  "ABOUT_PAGE_6_TEXT": "Riceva consigli pratici sul mal di testa, ad esempio sui fattori scatenanti più comuni e sul perché attività fisica regolare e sonno sufficiente sono importanti, anche nel fine settimana.",
  "ABOUT_PAGE_7_TITLE": "Modalità scura",
  "ABOUT_PAGE_7_TEXT": "Sensibile alla luce? Attivi la modalità scura. Può anche attivarla o disattivarla in seguito nelle impostazioni personali.",
  "ABOUT_PAGE_8_TITLE": "Uso dei farmaci",
  "ABOUT_PAGE_8_TEXT": "Veda quali farmaci ha usato e quando (farmaci per l'attacco, terapia di profilassi e iniezioni) e quanto ha funzionato ciascun farmaco per l'attacco.",
  "ABOUT_PAGE_9_TITLE": "Fattori del mal di testa",
  "ABOUT_PAGE_9_TEXT": "Individui schemi ricorrenti in gravità, emicrania, aura, ciclo mestruale e attacchi lunghi o brevi, e segua nel tempo l'uso di antidolorifici e triptani."
 },
 "ja": {
  "LANDING_READ_MORE": "アプリについて詳しく見る",
  "ABOUT_TITLE": "アプリについて",
  "ABOUT_INTRO": "頭痛のある日、痛みの強さ、薬の使用状況をわかりやすく把握できると、医師と一緒に適切な治療を見つけやすくなります。アプリがその記録をサポートします。",
  "ABOUT_STEP_OF": "{current} / {total}",
  "ABOUT_PREVIOUS": "前へ",
  "ABOUT_NEXT": "次へ",
  "ABOUT_CLOSE": "閉じる",
  "ABOUT_PAGE_1_TITLE": "ホーム画面",
  "ABOUT_PAGE_1_TEXT": "アプリをダウンロードしましょう。ホーム画面では、痛みのない日、軽度・中等度・重度の頭痛があった日、頓服薬を使った日など、過去30日間をひと目で確認できます。今日の記録は「毎日の記録」をタップしてください。",
  "ABOUT_PAGE_2_TITLE": "カレンダー",
  "ABOUT_PAGE_2_TEXT": "「マイ日記」では、カレンダーの各日が頭痛の強さに応じて色分けされ、頓服薬と前兆のマークが表示されます。その下には、頭痛の時間、強さ別の日数、服薬日数など、その月のまとめが表示されます。",
  "ABOUT_PAGE_3_TITLE": "傾向を把握する",
  "ABOUT_PAGE_3_TEXT": "記録を振り返り、カレンダー、日記、さまざまなグラフで全体像を把握できます。たとえば、薬の使用状況が時間とともにどう変化しているかも確認できます。",
  "ABOUT_PAGE_4_TITLE": "マイデータ",
  "ABOUT_PAGE_4_TEXT": "頭痛の強さの推移を追い、各頓服薬の効き具合を確認し、頭痛と関係する要因を見つけることができます。最大で数年分の期間に対応しています。",
  "ABOUT_PAGE_5_TITLE": "医師と共有",
  "ABOUT_PAGE_5_TEXT": "データを医師と簡単に共有できます。アプリがワンタイムコードを発行し、医師がheadachecalendar.comでそのコードを入力すると、あなたの記録を確認できます。",
  "ABOUT_PAGE_6_TITLE": "ヒント",
  "ABOUT_PAGE_6_TEXT": "よくある誘因や、週末も含めて規則的な運動と十分な睡眠が大切な理由など、頭痛に役立つ実用的なヒントをお届けします。",
  "ABOUT_PAGE_7_TITLE": "ダークモード",
  "ABOUT_PAGE_7_TEXT": "光がまぶしく感じますか？ダークモードをオンにしましょう。あとから個人設定でオン・オフを切り替えることもできます。",
  "ABOUT_PAGE_8_TITLE": "薬の使用",
  "ABOUT_PAGE_8_TEXT": "頓服薬、予防薬、注射など、いつどの薬を使用したかを確認でき、各頓服薬がどの程度効いたかもわかります。",
  "ABOUT_PAGE_9_TITLE": "頭痛の要因",
  "ABOUT_PAGE_9_TEXT": "重症度、片頭痛、前兆、月経、長い発作・短い発作のパターンを確認し、鎮痛薬やトリプタンの使用状況の推移を追うことができます。"
 },
 "lt": {
  "LANDING_READ_MORE": "Sužinokite daugiau apie programėlę",
  "ABOUT_TITLE": "Apie programėlę",
  "ABOUT_INTRO": "Aiški galvos skausmo dienų, intensyvumo ir vaistų vartojimo apžvalga padeda kartu su gydytoju rasti tinkamą gydymą. Programėlė padeda jums viską stebėti.",
  "ABOUT_STEP_OF": "{current} iš {total}",
  "ABOUT_PREVIOUS": "Ankstesnis",
  "ABOUT_NEXT": "Kitas",
  "ABOUT_CLOSE": "Uždaryti",
  "ABOUT_PAGE_1_TITLE": "Pradžios ekranas",
  "ABOUT_PAGE_1_TEXT": "Atsisiųskite programėlę. Pradžios ekrane iš karto matysite paskutines 30 dienų: dienas be skausmo, su lengvu, vidutiniu ar stipriu galvos skausmu ir dienas, kai vartojote priepuolio vaistus. Bakstelėkite Dienos įrašas, kad užregistruotumėte šiandieną.",
  "ABOUT_PAGE_2_TITLE": "Kalendorius",
  "ABOUT_PAGE_2_TEXT": "Skiltyje Mano dienoraštis kiekviena kalendoriaus diena nuspalvinta pagal galvos skausmo intensyvumą, pažymėti priepuolio vaistai ir aura. Žemiau rasite mėnesio suvestinę: galvos skausmo valandas, dienas pagal intensyvumą ir vaistų dienas.",
  "ABOUT_PAGE_3_TITLE": "Gaukite įžvalgų",
  "ABOUT_PAGE_3_TEXT": "Peržiūrėkite savo įrašus ir susidarykite vaizdą per kalendorių, dienoraštį ir įvairias diagramas – pavyzdžiui, kaip laikui bėgant kinta jūsų vaistų vartojimas.",
  "ABOUT_PAGE_4_TITLE": "Mano duomenys",
  "ABOUT_PAGE_4_TEXT": "Stebėkite galvos skausmo intensyvumą laikui bėgant, matykite, kaip gerai veikia kiekvienas priepuolio vaistas, ir pastebėkite, kurie veiksniai susiję su jūsų galvos skausmu – net kelerių metų laikotarpiais.",
  "ABOUT_PAGE_5_TITLE": "Pasidalykite su gydytoju",
  "ABOUT_PAGE_5_TEXT": "Lengvai pasidalykite savo duomenimis su gydytoju. Programėlė sukuria vienkartinį kodą, kurį gydytojas įveda svetainėje headachecalendar.com, kad matytų jūsų įrašus.",
  "ABOUT_PAGE_6_TITLE": "Patarimai",
  "ABOUT_PAGE_6_TEXT": "Gaukite praktinių patarimų apie galvos skausmą, pavyzdžiui, apie dažnus sukėlėjus ir kodėl svarbu reguliariai judėti bei pakankamai miegoti – ir savaitgaliais.",
  "ABOUT_PAGE_7_TITLE": "Tamsusis režimas",
  "ABOUT_PAGE_7_TEXT": "Jautrūs šviesai? Įjunkite tamsųjį režimą. Vėliau jį galėsite įjungti arba išjungti asmeniniuose nustatymuose.",
  "ABOUT_PAGE_8_TITLE": "Vaistų vartojimas",
  "ABOUT_PAGE_8_TEXT": "Matykite, kokius vaistus ir kada vartojote – priepuolio, profilaktinius vaistus ir injekcijas – ir kaip gerai veikė kiekvienas priepuolio vaistas.",
  "ABOUT_PAGE_9_TITLE": "Galvos skausmo veiksniai",
  "ABOUT_PAGE_9_TEXT": "Pastebėkite dėsningumus pagal sunkumą, migreną, aurą, menstruacijas ir ilgus ar trumpus priepuolius bei stebėkite skausmą malšinančių vaistų ir triptanų vartojimą laikui bėgant."
 },
 "lv": {
  "LANDING_READ_MORE": "Uzziniet vairāk par lietotni",
  "ABOUT_TITLE": "Par lietotni",
  "ABOUT_INTRO": "Skaidrs pārskats par galvassāpju dienām, intensitāti un medikamentu lietošanu palīdz kopā ar ārstu atrast piemērotāko ārstēšanu. Lietotne palīdz Jums saglabāt pārskatu.",
  "ABOUT_STEP_OF": "{current} no {total}",
  "ABOUT_PREVIOUS": "Iepriekšējā",
  "ABOUT_NEXT": "Nākamā",
  "ABOUT_CLOSE": "Aizvērt",
  "ABOUT_PAGE_1_TITLE": "Sākuma ekrāns",
  "ABOUT_PAGE_1_TEXT": "Lejupielādējiet lietotni. Sākuma ekrānā vienā skatienā redzamas Jūsu pēdējās 30 dienas: dienas bez sāpēm, ar vieglām, mērenām vai stiprām galvassāpēm un dienas, kad lietojāt lēkmes medikamentus. Pieskarieties Ikdienas ieraksts, lai reģistrētu šodienu.",
  "ABOUT_PAGE_2_TITLE": "Kalendārs",
  "ABOUT_PAGE_2_TEXT": "Sadaļā Mana dienasgrāmata katra kalendāra diena ir iekrāsota atbilstoši galvassāpju intensitātei, ar atzīmēm par lēkmes medikamentiem un auru. Zemāk redzams mēneša kopsavilkums: galvassāpju stundas, dienas pēc intensitātes un medikamentu dienas.",
  "ABOUT_PAGE_3_TITLE": "Iegūstiet ieskatu",
  "ABOUT_PAGE_3_TEXT": "Pārskatiet savus ierakstus un gūstiet pārskatu kalendārā, dienasgrāmatā un dažādās diagrammās – piemēram, kā laika gaitā mainās Jūsu medikamentu lietošana.",
  "ABOUT_PAGE_4_TITLE": "Mani dati",
  "ABOUT_PAGE_4_TEXT": "Sekojiet galvassāpju intensitātei laika gaitā, skatiet, cik labi iedarbojas katrs lēkmes medikaments, un pamaniet, kuri faktori saistīti ar Jūsu galvassāpēm – pat vairāku gadu periodos.",
  "ABOUT_PAGE_5_TITLE": "Dalieties ar ārstu",
  "ABOUT_PAGE_5_TEXT": "Viegli dalieties ar saviem datiem ar ārstu. Lietotne izveido vienreizēju kodu, ko ārsts ievada vietnē headachecalendar.com, lai redzētu Jūsu ierakstus.",
  "ABOUT_PAGE_6_TITLE": "Padomi",
  "ABOUT_PAGE_6_TEXT": "Saņemiet praktiskus padomus par galvassāpēm, piemēram, par biežākajiem izraisītājiem un to, kāpēc svarīgas ir regulāras fiziskās aktivitātes un pietiekams miegs – arī nedēļas nogalēs.",
  "ABOUT_PAGE_7_TITLE": "Tumšais režīms",
  "ABOUT_PAGE_7_TEXT": "Jutība pret gaismu? Ieslēdziet tumšo režīmu. To var ieslēgt vai izslēgt arī vēlāk personīgajos iestatījumos.",
  "ABOUT_PAGE_8_TITLE": "Medikamentu lietošana",
  "ABOUT_PAGE_8_TEXT": "Skatiet, kādi medikamenti un kad lietoti – lēkmes medikamenti, profilaktiskie medikamenti un injekcijas – un cik labi iedarbojies katrs lēkmes medikaments.",
  "ABOUT_PAGE_9_TITLE": "Galvassāpju faktori",
  "ABOUT_PAGE_9_TEXT": "Saskatiet likumsakarības smaguma pakāpē, migrēnā, aurā, menstruācijās un garās vai īsās lēkmēs, un sekojiet pretsāpju līdzekļu un triptānu lietošanai laika gaitā."
 },
 "mk": {
  "LANDING_READ_MORE": "Дознајте повеќе за апликацијата",
  "ABOUT_TITLE": "За апликацијата",
  "ABOUT_INTRO": "Јасниот преглед на деновите со главоболка, нејзиниот интензитет и употребата на лекови го олеснува наоѓањето на вистинскиот третман заедно со вашиот лекар. Апликацијата ви помага да имате преглед.",
  "ABOUT_STEP_OF": "{current} од {total}",
  "ABOUT_PREVIOUS": "Претходно",
  "ABOUT_NEXT": "Следно",
  "ABOUT_CLOSE": "Затвори",
  "ABOUT_PAGE_1_TITLE": "Почетен екран",
  "ABOUT_PAGE_1_TEXT": "Преземете ја апликацијата. Почетниот екран на прв поглед ги прикажува вашите последни 30 дена: денови без болка, со блага, умерена или силна главоболка и денови кога сте зеле лек за напад. Допрете Дневен запис за да го внесете денешниот ден.",
  "ABOUT_PAGE_2_TITLE": "Календар",
  "ABOUT_PAGE_2_TEXT": "Во Мој дневник секој ден во календарот е обоен според интензитетот на главоболката, со ознаки за лекови за напад и аура. Под него добивате резиме на месецот: часови со главоболка, денови по интензитет и денови со лекови.",
  "ABOUT_PAGE_3_TITLE": "Добијте увид",
  "ABOUT_PAGE_3_TEXT": "Прегледајте ги вашите записи и добијте преглед преку календарот, дневникот и низа графикони – на пример, како се менува вашата употреба на лекови со текот на времето.",
  "ABOUT_PAGE_4_TITLE": "Мои податоци",
  "ABOUT_PAGE_4_TEXT": "Следете го интензитетот на главоболката со текот на времето, видете колку добро делува секој лек за напад и откријте кои фактори се поврзани со вашите главоболки – за периоди и до неколку години.",
  "ABOUT_PAGE_5_TITLE": "Споделете со лекарот",
  "ABOUT_PAGE_5_TEXT": "Лесно споделете ги вашите податоци со вашиот лекар. Апликацијата создава еднократен код што лекарот го внесува на headachecalendar.com за да ги види вашите записи.",
  "ABOUT_PAGE_6_TITLE": "Совети",
  "ABOUT_PAGE_6_TEXT": "Добијте практични совети за главоболката, на пример за честите поттикнувачи и зошто редовната физичка активност и доволно сон се важни – и за викенд.",
  "ABOUT_PAGE_7_TITLE": "Темен режим",
  "ABOUT_PAGE_7_TEXT": "Чувствителни сте на светлина? Вклучете го темниот режим. Подоцна можете да го вклучите или исклучите и во личните поставки.",
  "ABOUT_PAGE_8_TITLE": "Употреба на лекови",
  "ABOUT_PAGE_8_TEXT": "Видете кои лекови сте ги користеле и кога – лекови за напад, превентивни лекови и инјекции – и колку добро делувал секој лек за напад.",
  "ABOUT_PAGE_9_TITLE": "Фактори за главоболка",
  "ABOUT_PAGE_9_TEXT": "Забележете обрасци во јачината, мигрената, аурата, менструацијата и долгите или кратките напади и следете ја употребата на лекови против болка и триптани со текот на времето."
 },
 "nl": {
  "LANDING_READ_MORE": "Lees meer over de app",
  "ABOUT_TITLE": "Over de app",
  "ABOUT_INTRO": "Een duidelijk overzicht van hoofdpijndagen, intensiteit en medicijngebruik maakt het makkelijker om samen met uw arts de juiste behandeling te vinden. De app helpt u het overzicht te houden.",
  "ABOUT_STEP_OF": "{current} van {total}",
  "ABOUT_PREVIOUS": "Vorige",
  "ABOUT_NEXT": "Volgende",
  "ABOUT_CLOSE": "Sluiten",
  "ABOUT_PAGE_1_TITLE": "Startscherm",
  "ABOUT_PAGE_1_TEXT": "Download de app. Het startscherm toont uw afgelopen 30 dagen in één oogopslag: dagen zonder pijn, met lichte, matige of ernstige hoofdpijn, en dagen waarop u aanvalsmedicatie nam. Tik op Dagelijkse invoer om vandaag te registreren.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "In Mijn dagboek krijgt elke dag in de kalender een kleur volgens de intensiteit van de hoofdpijn, met markeringen voor aanvalsmedicatie en aura. Daaronder ziet u een samenvatting van de maand: uren hoofdpijn, dagen per intensiteit en medicatiedagen.",
  "ABOUT_PAGE_3_TITLE": "Krijg inzicht",
  "ABOUT_PAGE_3_TEXT": "Bekijk uw registraties en houd overzicht via de kalender, het dagboek en diverse grafieken – bijvoorbeeld hoe uw medicijngebruik zich in de loop van de tijd ontwikkelt.",
  "ABOUT_PAGE_4_TITLE": "Mijn gegevens",
  "ABOUT_PAGE_4_TEXT": "Volg de intensiteit van uw hoofdpijn in de tijd, zie hoe goed elk aanvalsmedicijn werkt en ontdek welke factoren samenhangen met uw hoofdpijn – over perioden tot wel enkele jaren.",
  "ABOUT_PAGE_5_TITLE": "Delen met uw arts",
  "ABOUT_PAGE_5_TEXT": "Deel uw gegevens eenvoudig met uw arts. De app maakt een eenmalige code aan die uw arts invoert op headachecalendar.com om uw registraties te bekijken.",
  "ABOUT_PAGE_6_TITLE": "Tips",
  "ABOUT_PAGE_6_TEXT": "Krijg praktische tips over hoofdpijn, zoals veelvoorkomende triggers en waarom regelmatig bewegen en voldoende slaap belangrijk zijn – ook in het weekend.",
  "ABOUT_PAGE_7_TITLE": "Donkere modus",
  "ABOUT_PAGE_7_TEXT": "Gevoelig voor licht? Zet de donkere modus aan. U kunt deze later ook aan- of uitzetten in uw persoonlijke instellingen.",
  "ABOUT_PAGE_8_TITLE": "Medicijngebruik",
  "ABOUT_PAGE_8_TEXT": "Bekijk welke medicijnen u wanneer hebt gebruikt – aanvalsmedicatie, preventieve medicatie en injecties – en hoe goed elk aanvalsmedicijn heeft gewerkt.",
  "ABOUT_PAGE_9_TITLE": "Hoofdpijnfactoren",
  "ABOUT_PAGE_9_TEXT": "Zie patronen in ernst, migraine, aura, menstruatie en lange of korte aanvallen, en volg uw gebruik van pijnstillers en triptanen in de tijd."
 },
 "no": {
  "LANDING_READ_MORE": "Les mer om appen",
  "ABOUT_TITLE": "Om appen",
  "ABOUT_INTRO": "God oversikt over hodepinedager, intensitet og medisinbruk gjør det lettere å finne riktig behandling sammen med legen din. Appen hjelper deg å holde oversikten.",
  "ABOUT_STEP_OF": "{current} av {total}",
  "ABOUT_PREVIOUS": "Forrige",
  "ABOUT_NEXT": "Neste",
  "ABOUT_CLOSE": "Lukk",
  "ABOUT_PAGE_1_TITLE": "Startskjerm",
  "ABOUT_PAGE_1_TEXT": "Last ned appen. Startskjermen viser de siste 30 dagene på et øyeblikk: dager uten smerte, med lett, moderat eller sterk hodepine, og dager du tok anfallsmedisin. Trykk Daglig registrering for å registrere i dag.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "I Min dagbok er hver dag i kalenderen farget etter hodepinens intensitet, med markeringer for anfallsmedisin og aura. Under får du en oppsummering av måneden: timer med hodepine, dager per intensitet og medisindager.",
  "ABOUT_PAGE_3_TITLE": "Få innsikt",
  "ABOUT_PAGE_3_TEXT": "Se gjennom registreringene dine og få oversikt via kalenderen, dagboken og en rekke grafer – for eksempel hvordan medisinbruken din utvikler seg over tid.",
  "ABOUT_PAGE_4_TITLE": "Mine data",
  "ABOUT_PAGE_4_TEXT": "Følg intensiteten over tid, se hvor godt hver anfallsmedisin virker, og finn ut hvilke faktorer som henger sammen med hodepinen din – for perioder på opptil flere år.",
  "ABOUT_PAGE_5_TITLE": "Del med legen din",
  "ABOUT_PAGE_5_TEXT": "Del dataene dine enkelt med legen din. Appen lager en engangskode som legen skriver inn på headachecalendar.com for å se registreringene dine.",
  "ABOUT_PAGE_6_TITLE": "Råd",
  "ABOUT_PAGE_6_TEXT": "Få praktiske råd om hodepine, for eksempel vanlige utløsende faktorer og hvorfor jevnlig fysisk aktivitet og nok søvn er viktig – også i helgene.",
  "ABOUT_PAGE_7_TITLE": "Mørk modus",
  "ABOUT_PAGE_7_TEXT": "Lysømfintlig? Slå på mørk modus. Du kan også slå det av eller på senere i de personlige innstillingene.",
  "ABOUT_PAGE_8_TITLE": "Medisinbruk",
  "ABOUT_PAGE_8_TEXT": "Se hvilke medisiner du har brukt og når – anfallsmedisin, forebyggende medisin og injeksjoner – og hvor godt hver anfallsmedisin har virket.",
  "ABOUT_PAGE_9_TITLE": "Hodepinefaktorer",
  "ABOUT_PAGE_9_TEXT": "Se mønstre i alvorlighetsgrad, migrene, aura, menstruasjon og lange eller korte anfall, og følg bruken av smertestillende og triptaner over tid."
 },
 "pl": {
  "LANDING_READ_MORE": "Dowiedz się więcej o aplikacji",
  "ABOUT_TITLE": "O aplikacji",
  "ABOUT_INTRO": "Przejrzysty obraz dni z bólem głowy, jego nasilenia i przyjmowanych leków ułatwia dobranie właściwego leczenia razem z lekarzem. Aplikacja pomoże Ci to wszystko śledzić.",
  "ABOUT_STEP_OF": "{current} z {total}",
  "ABOUT_PREVIOUS": "Poprzednia",
  "ABOUT_NEXT": "Następna",
  "ABOUT_CLOSE": "Zamknij",
  "ABOUT_PAGE_1_TITLE": "Ekran główny",
  "ABOUT_PAGE_1_TEXT": "Pobierz aplikację. Ekran główny pokazuje w skrócie ostatnie 30 dni: dni bez bólu, z łagodnym, umiarkowanym lub silnym bólem głowy oraz dni, w których przyjęto lek doraźny. Dotknij Wpis dzienny, aby zapisać dzisiejszy dzień.",
  "ABOUT_PAGE_2_TITLE": "Kalendarz",
  "ABOUT_PAGE_2_TEXT": "W sekcji Mój dziennik każdy dzień w kalendarzu ma kolor odpowiadający nasileniu bólu głowy, z oznaczeniami leków doraźnych i aury. Poniżej znajdziesz podsumowanie miesiąca: godziny bólu głowy, dni według nasilenia i dni z lekami.",
  "ABOUT_PAGE_3_TITLE": "Analizy",
  "ABOUT_PAGE_3_TEXT": "Przeglądaj swoje wpisy i miej wszystko pod kontrolą dzięki kalendarzowi, dziennikowi i różnym wykresom – na przykład jak z czasem zmienia się stosowanie leków.",
  "ABOUT_PAGE_4_TITLE": "Moje dane",
  "ABOUT_PAGE_4_TEXT": "Śledź nasilenie bólu głowy w czasie, sprawdzaj, jak działa każdy lek doraźny, i odkrywaj, które czynniki wiążą się z Twoimi bólami głowy – nawet w okresie kilku lat.",
  "ABOUT_PAGE_5_TITLE": "Udostępnij lekarzowi",
  "ABOUT_PAGE_5_TEXT": "Łatwo udostępnij swoje dane lekarzowi. Aplikacja tworzy jednorazowy kod, który lekarz wpisuje na stronie headachecalendar.com, aby zobaczyć Twoje wpisy.",
  "ABOUT_PAGE_6_TITLE": "Porady",
  "ABOUT_PAGE_6_TEXT": "Otrzymuj praktyczne porady dotyczące bólu głowy, np. o częstych czynnikach wyzwalających i o tym, dlaczego regularna aktywność fizyczna i odpowiednia ilość snu są ważne – także w weekendy.",
  "ABOUT_PAGE_7_TITLE": "Tryb ciemny",
  "ABOUT_PAGE_7_TEXT": "Światło Cię razi? Włącz tryb ciemny. Możesz go też później włączyć lub wyłączyć w ustawieniach osobistych.",
  "ABOUT_PAGE_8_TITLE": "Stosowanie leków",
  "ABOUT_PAGE_8_TEXT": "Sprawdź, jakie leki były stosowane i kiedy – leki doraźne, leki zapobiegawcze i zastrzyki – oraz jak skutecznie działał każdy lek doraźny.",
  "ABOUT_PAGE_9_TITLE": "Czynniki bólu głowy",
  "ABOUT_PAGE_9_TEXT": "Dostrzegaj wzorce w nasileniu, migrenie, aurze, miesiączce oraz długich i krótkich napadach, a także śledź stosowanie leków przeciwbólowych i tryptanów w czasie."
 },
 "pt-BR": {
  "LANDING_READ_MORE": "Saiba mais sobre o aplicativo",
  "ABOUT_TITLE": "Sobre o aplicativo",
  "ABOUT_INTRO": "Uma visão clara dos dias com dor de cabeça, da intensidade e do uso de medicamentos facilita encontrar o tratamento certo junto com seu médico. O aplicativo ajuda você a acompanhar tudo.",
  "ABOUT_STEP_OF": "{current} de {total}",
  "ABOUT_PREVIOUS": "Anterior",
  "ABOUT_NEXT": "Próximo",
  "ABOUT_CLOSE": "Fechar",
  "ABOUT_PAGE_1_TITLE": "Tela inicial",
  "ABOUT_PAGE_1_TEXT": "Baixe o aplicativo. A tela inicial mostra seus últimos 30 dias de forma rápida: dias sem dor, com dor de cabeça leve, moderada ou forte, e dias em que você tomou medicação para as crises. Toque em Registro diário para registrar o dia de hoje.",
  "ABOUT_PAGE_2_TITLE": "Calendário",
  "ABOUT_PAGE_2_TEXT": "Em Meu diário, cada dia do calendário é colorido de acordo com a intensidade da dor de cabeça, com marcações para medicação para as crises e aura. Logo abaixo, você vê um resumo do mês: horas de dor de cabeça, dias por intensidade e dias com medicação.",
  "ABOUT_PAGE_3_TITLE": "Tenha uma visão geral",
  "ABOUT_PAGE_3_TEXT": "Revise seus registros e tenha uma visão geral pelo calendário, pelo diário e por vários gráficos – por exemplo, como seu uso de medicamentos evolui ao longo do tempo.",
  "ABOUT_PAGE_4_TITLE": "Meus dados",
  "ABOUT_PAGE_4_TEXT": "Acompanhe a intensidade da dor de cabeça ao longo do tempo, veja quanto cada medicação para as crises funciona e descubra quais fatores estão ligados às suas dores de cabeça – em períodos de até vários anos.",
  "ABOUT_PAGE_5_TITLE": "Compartilhe com seu médico",
  "ABOUT_PAGE_5_TEXT": "Compartilhe seus dados facilmente com seu médico. O aplicativo gera um código de uso único que o médico digita em headachecalendar.com para ver seus registros.",
  "ABOUT_PAGE_6_TITLE": "Dicas",
  "ABOUT_PAGE_6_TEXT": "Receba dicas práticas sobre dor de cabeça, como os gatilhos mais comuns e por que a atividade física regular e dormir bem são importantes – inclusive nos fins de semana.",
  "ABOUT_PAGE_7_TITLE": "Modo escuro",
  "ABOUT_PAGE_7_TEXT": "Sensível à luz? Ative o modo escuro. Você também pode ativá-lo ou desativá-lo depois nas configurações pessoais.",
  "ABOUT_PAGE_8_TITLE": "Uso de medicamentos",
  "ABOUT_PAGE_8_TEXT": "Veja quais medicamentos você usou e quando – medicação para as crises, medicação preventiva e injeções – e quanto cada medicação para as crises funcionou.",
  "ABOUT_PAGE_9_TITLE": "Fatores da dor de cabeça",
  "ABOUT_PAGE_9_TEXT": "Identifique padrões na gravidade, enxaqueca, aura, menstruação e crises longas ou curtas, e acompanhe o uso de analgésicos e triptanos ao longo do tempo."
 },
 "pt": {
  "LANDING_READ_MORE": "Saiba mais sobre a aplicação",
  "ABOUT_TITLE": "Sobre a aplicação",
  "ABOUT_INTRO": "Uma visão clara dos dias com dor de cabeça, da intensidade e do uso de medicação facilita encontrar o tratamento certo em conjunto com o seu médico. A aplicação ajuda a manter tudo registado.",
  "ABOUT_STEP_OF": "{current} de {total}",
  "ABOUT_PREVIOUS": "Anterior",
  "ABOUT_NEXT": "Seguinte",
  "ABOUT_CLOSE": "Fechar",
  "ABOUT_PAGE_1_TITLE": "Ecrã inicial",
  "ABOUT_PAGE_1_TEXT": "Descarregue a aplicação. O ecrã inicial mostra os últimos 30 dias num relance: dias sem dor, com dor de cabeça ligeira, moderada ou forte, e dias em que tomou medicação para as crises. Toque em Registo diário para registar o dia de hoje.",
  "ABOUT_PAGE_2_TITLE": "Calendário",
  "ABOUT_PAGE_2_TEXT": "Em O meu diário, cada dia do calendário é colorido de acordo com a intensidade da dor de cabeça, com marcações para a medicação para as crises e a aura. Abaixo encontra um resumo do mês: horas de dor de cabeça, dias por intensidade e dias com medicação.",
  "ABOUT_PAGE_3_TITLE": "Obtenha uma visão geral",
  "ABOUT_PAGE_3_TEXT": "Reveja os seus registos e obtenha uma visão geral através do calendário, do diário e de vários gráficos – por exemplo, como o seu uso de medicação evolui ao longo do tempo.",
  "ABOUT_PAGE_4_TITLE": "Os meus dados",
  "ABOUT_PAGE_4_TEXT": "Acompanhe a intensidade da dor de cabeça ao longo do tempo, veja até que ponto cada medicação para as crises resulta e descubra que fatores estão associados às suas dores de cabeça – em períodos de até vários anos.",
  "ABOUT_PAGE_5_TITLE": "Partilhe com o seu médico",
  "ABOUT_PAGE_5_TEXT": "Partilhe facilmente os seus dados com o seu médico. A aplicação cria um código de utilização única que o médico introduz em headachecalendar.com para ver os seus registos.",
  "ABOUT_PAGE_6_TITLE": "Dicas",
  "ABOUT_PAGE_6_TEXT": "Receba dicas práticas sobre dores de cabeça, como os fatores desencadeantes mais comuns e porque é importante praticar atividade física regular e dormir o suficiente – também ao fim de semana.",
  "ABOUT_PAGE_7_TITLE": "Modo escuro",
  "ABOUT_PAGE_7_TEXT": "Sensível à luz? Ative o modo escuro. Também pode ativá-lo ou desativá-lo mais tarde nas definições pessoais.",
  "ABOUT_PAGE_8_TITLE": "Uso de medicação",
  "ABOUT_PAGE_8_TEXT": "Veja que medicamentos tomou e quando – medicação para as crises, medicação preventiva e injeções – e até que ponto cada medicação para as crises resultou.",
  "ABOUT_PAGE_9_TITLE": "Fatores da dor de cabeça",
  "ABOUT_PAGE_9_TEXT": "Identifique padrões na gravidade, enxaqueca, aura, menstruação e crises longas ou curtas, e acompanhe o uso de analgésicos e triptanos ao longo do tempo."
 },
 "ro": {
  "LANDING_READ_MORE": "Aflați mai multe despre aplicație",
  "ABOUT_TITLE": "Despre aplicație",
  "ABOUT_INTRO": "O imagine clară asupra zilelor cu durere de cap, a intensității și a medicației folosite vă ajută să găsiți, împreună cu medicul dumneavoastră, tratamentul potrivit. Aplicația vă ajută să țineți evidența.",
  "ABOUT_STEP_OF": "{current} din {total}",
  "ABOUT_PREVIOUS": "Înapoi",
  "ABOUT_NEXT": "Înainte",
  "ABOUT_CLOSE": "Închideți",
  "ABOUT_PAGE_1_TITLE": "Ecranul principal",
  "ABOUT_PAGE_1_TEXT": "Descărcați aplicația. Ecranul principal vă arată dintr-o privire ultimele 30 de zile: zile fără durere, cu durere de cap ușoară, moderată sau severă și zile în care ați luat medicație pentru criză. Atingeți Înregistrare zilnică pentru a nota ziua de azi.",
  "ABOUT_PAGE_2_TITLE": "Calendar",
  "ABOUT_PAGE_2_TEXT": "În Jurnalul meu, fiecare zi din calendar este colorată în funcție de intensitatea durerii de cap, cu marcaje pentru medicația pentru criză și aură. Dedesubt găsiți un rezumat al lunii: ore cu durere de cap, zile pe intensitate și zile cu medicație.",
  "ABOUT_PAGE_3_TITLE": "Informații utile",
  "ABOUT_PAGE_3_TEXT": "Revedeți înregistrările și obțineți o imagine de ansamblu prin calendar, jurnal și o serie de grafice – de exemplu, cum evoluează în timp medicația pe care o folosiți.",
  "ABOUT_PAGE_4_TITLE": "Datele mele",
  "ABOUT_PAGE_4_TEXT": "Urmăriți intensitatea durerii de cap în timp, vedeți cât de bine funcționează fiecare medicament pentru criză și descoperiți ce factori se asociază cu durerile de cap – pe perioade de până la câțiva ani.",
  "ABOUT_PAGE_5_TITLE": "Partajați cu medicul",
  "ABOUT_PAGE_5_TEXT": "Partajați ușor datele cu medicul dumneavoastră. Aplicația generează un cod unic de acces, pe care medicul îl introduce pe headachecalendar.com pentru a vedea înregistrările dumneavoastră.",
  "ABOUT_PAGE_6_TITLE": "Sfaturi",
  "ABOUT_PAGE_6_TEXT": "Primiți sfaturi practice despre durerea de cap, cum ar fi factorii declanșatori frecvenți și de ce contează activitatea fizică regulată și somnul suficient – inclusiv în weekend.",
  "ABOUT_PAGE_7_TITLE": "Mod întunecat",
  "ABOUT_PAGE_7_TEXT": "Vă deranjează lumina? Activați modul întunecat. Îl puteți activa sau dezactiva și mai târziu din setările personale.",
  "ABOUT_PAGE_8_TITLE": "Utilizarea medicației",
  "ABOUT_PAGE_8_TEXT": "Vedeți ce medicamente ați folosit și când – medicație pentru criză, tratament preventiv și injecții – și cât de bine a funcționat fiecare medicament pentru criză.",
  "ABOUT_PAGE_9_TITLE": "Factorii durerii de cap",
  "ABOUT_PAGE_9_TEXT": "Observați tipare legate de severitate, migrenă, aură, menstruație și crize lungi sau scurte și urmăriți în timp utilizarea analgezicelor și a triptanelor."
 },
 "ru": {
  "LANDING_READ_MORE": "Подробнее о приложении",
  "ABOUT_TITLE": "О приложении",
  "ABOUT_INTRO": "Наглядная картина дней с головной болью, её интенсивности и приёма лекарств помогает вместе с врачом подобрать подходящее лечение. Приложение поможет вам ничего не упустить.",
  "ABOUT_STEP_OF": "{current} из {total}",
  "ABOUT_PREVIOUS": "Назад",
  "ABOUT_NEXT": "Далее",
  "ABOUT_CLOSE": "Закрыть",
  "ABOUT_PAGE_1_TITLE": "Главный экран",
  "ABOUT_PAGE_1_TEXT": "Скачайте приложение. Главный экран показывает последние 30 дней с одного взгляда: дни без боли, с лёгкой, умеренной или сильной головной болью, а также дни, когда вы принимали лекарства для снятия приступа. Нажмите «Ежедневная запись», чтобы внести данные за сегодня.",
  "ABOUT_PAGE_2_TITLE": "Календарь",
  "ABOUT_PAGE_2_TEXT": "В разделе «Мой дневник» каждый день календаря окрашен по интенсивности головной боли, с отметками о лекарствах для снятия приступа и ауре. Ниже — итоги месяца: часы с головной болью, дни по интенсивности и дни приёма лекарств.",
  "ABOUT_PAGE_3_TITLE": "Получите инсайты",
  "ABOUT_PAGE_3_TEXT": "Просматривайте свои записи и получайте общую картину с помощью календаря, дневника и различных графиков — например, как меняется приём лекарств со временем.",
  "ABOUT_PAGE_4_TITLE": "Мои данные",
  "ABOUT_PAGE_4_TEXT": "Следите за интенсивностью головной боли во времени, смотрите, насколько хорошо помогает каждое лекарство для снятия приступа, и выявляйте факторы, связанные с вашей головной болью, — за периоды до нескольких лет.",
  "ABOUT_PAGE_5_TITLE": "Поделитесь с врачом",
  "ABOUT_PAGE_5_TEXT": "Легко делитесь своими данными с врачом. Приложение создаёт одноразовый код, который врач вводит на headachecalendar.com, чтобы увидеть ваши записи.",
  "ABOUT_PAGE_6_TITLE": "Советы",
  "ABOUT_PAGE_6_TEXT": "Получайте практические советы о головной боли: например, о частых провоцирующих факторах и о том, почему важны регулярная физическая активность и достаточный сон — в том числе в выходные.",
  "ABOUT_PAGE_7_TITLE": "Тёмный режим",
  "ABOUT_PAGE_7_TEXT": "Чувствительны к свету? Включите тёмный режим. Позже его можно включить или отключить в личных настройках.",
  "ABOUT_PAGE_8_TITLE": "Приём лекарств",
  "ABOUT_PAGE_8_TEXT": "Смотрите, какие лекарства и когда вы принимали — для снятия приступа, профилактические и инъекции, — и насколько хорошо помогло каждое лекарство для снятия приступа.",
  "ABOUT_PAGE_9_TITLE": "Факторы головной боли",
  "ABOUT_PAGE_9_TEXT": "Выявляйте закономерности по тяжести, мигрени, ауре, менструации и длинным или коротким приступам, а также следите за приёмом обезболивающих и триптанов во времени."
 },
 "sk": {
  "LANDING_READ_MORE": "Viac o aplikácii",
  "ABOUT_TITLE": "O aplikácii",
  "ABOUT_INTRO": "Prehľad o dňoch s bolesťou hlavy, jej intenzite a užívaní liekov uľahčuje nájsť spolu s lekárom správnu liečbu. Aplikácia vám pomôže mať všetko pod kontrolou.",
  "ABOUT_STEP_OF": "{current} z {total}",
  "ABOUT_PREVIOUS": "Späť",
  "ABOUT_NEXT": "Ďalej",
  "ABOUT_CLOSE": "Zavrieť",
  "ABOUT_PAGE_1_TITLE": "Úvodná obrazovka",
  "ABOUT_PAGE_1_TEXT": "Stiahnite si aplikáciu. Úvodná obrazovka prehľadne zobrazuje posledných 30 dní: dni bez bolesti, s miernou, stredne silnou alebo silnou bolesťou hlavy a dni, keď ste užili akútny liek. Dnešný deň zaznamenáte ťuknutím na Denný záznam.",
  "ABOUT_PAGE_2_TITLE": "Kalendár",
  "ABOUT_PAGE_2_TEXT": "V sekcii Môj denník je každý deň v kalendári zafarbený podľa intenzity bolesti hlavy, so značkami pre akútne lieky a auru. Pod ním nájdete súhrn mesiaca: hodiny bolesti hlavy, dni podľa intenzity a dni s liekmi.",
  "ABOUT_PAGE_3_TITLE": "Získajte prehľad",
  "ABOUT_PAGE_3_TEXT": "Prezrite si svoje záznamy a získajte prehľad vďaka kalendáru, denníku a viacerým grafom – napríklad ako sa v čase vyvíja vaše užívanie liekov.",
  "ABOUT_PAGE_4_TITLE": "Moje údaje",
  "ABOUT_PAGE_4_TEXT": "Sledujte intenzitu bolesti hlavy v čase, zistite, ako dobre účinkuje každý akútny liek, a odhaľte, ktoré faktory súvisia s vašimi bolesťami hlavy – aj za obdobie niekoľkých rokov.",
  "ABOUT_PAGE_5_TITLE": "Zdieľajte s lekárom",
  "ABOUT_PAGE_5_TEXT": "Jednoducho zdieľajte svoje údaje so svojím lekárom. Aplikácia vytvorí jednorazový kód, ktorý lekár zadá na headachecalendar.com, aby videl vaše záznamy.",
  "ABOUT_PAGE_6_TITLE": "Tipy",
  "ABOUT_PAGE_6_TEXT": "Získajte praktické tipy o bolesti hlavy, napríklad o častých spúšťačoch a o tom, prečo je dôležitý pravidelný pohyb a dostatok spánku – aj cez víkendy.",
  "ABOUT_PAGE_7_TITLE": "Tmavý režim",
  "ABOUT_PAGE_7_TEXT": "Ste citliví na svetlo? Zapnite tmavý režim. Neskôr ho môžete zapnúť alebo vypnúť aj v osobných nastaveniach.",
  "ABOUT_PAGE_8_TITLE": "Užívanie liekov",
  "ABOUT_PAGE_8_TEXT": "Pozrite si, ktoré lieky ste užívali a kedy – akútne lieky, preventívne lieky a injekcie – a ako dobre jednotlivé akútne lieky zaberali.",
  "ABOUT_PAGE_9_TITLE": "Faktory bolesti hlavy",
  "ABOUT_PAGE_9_TEXT": "Odhaľte súvislosti medzi závažnosťou, migrénou, aurou, menštruáciou a dlhými či krátkymi záchvatmi a sledujte užívanie liekov proti bolesti a triptánov v čase."
 },
 "sl": {
  "LANDING_READ_MORE": "Več o aplikaciji",
  "ABOUT_TITLE": "O aplikaciji",
  "ABOUT_INTRO": "Jasen pregled dni z glavobolom, njegove jakosti in jemanja zdravil olajša iskanje prave terapije skupaj z vašim zdravnikom. Aplikacija vam pomaga ohraniti pregled.",
  "ABOUT_STEP_OF": "{current} od {total}",
  "ABOUT_PREVIOUS": "Nazaj",
  "ABOUT_NEXT": "Naprej",
  "ABOUT_CLOSE": "Zapri",
  "ABOUT_PAGE_1_TITLE": "Začetni zaslon",
  "ABOUT_PAGE_1_TEXT": "Prenesite aplikacijo. Začetni zaslon na hitro prikaže zadnjih 30 dni: dneve brez bolečin, z blagim, zmernim ali močnim glavobolom ter dneve, ko ste vzeli zdravilo za napad. Za vnos današnjega dne tapnite Dnevni vnos.",
  "ABOUT_PAGE_2_TITLE": "Koledar",
  "ABOUT_PAGE_2_TEXT": "V razdelku Moj dnevnik je vsak dan v koledarju obarvan glede na jakost glavobola, z oznakami za zdravila za napad in avro. Pod njim je povzetek meseca: ure glavobola, dnevi po jakosti in dnevi z zdravili.",
  "ABOUT_PAGE_3_TITLE": "Pridobite vpogled",
  "ABOUT_PAGE_3_TEXT": "Preglejte svoje vnose in si ustvarite pregled s koledarjem, dnevnikom in vrsto grafov – na primer, kako se vaše jemanje zdravil spreminja skozi čas.",
  "ABOUT_PAGE_4_TITLE": "Moji podatki",
  "ABOUT_PAGE_4_TEXT": "Spremljajte jakost glavobola skozi čas, poglejte, kako dobro deluje posamezno zdravilo za napad, in odkrijte, kateri dejavniki so povezani z vašimi glavoboli – za obdobja do več let.",
  "ABOUT_PAGE_5_TITLE": "Delite z zdravnikom",
  "ABOUT_PAGE_5_TEXT": "Svoje podatke preprosto delite z zdravnikom. Aplikacija ustvari enkratno kodo, ki jo zdravnik vnese na headachecalendar.com, da si ogleda vaše vnose.",
  "ABOUT_PAGE_6_TITLE": "Nasveti",
  "ABOUT_PAGE_6_TEXT": "Pridobite praktične nasvete o glavobolu, na primer o pogostih sprožilcih in o tem, zakaj sta redna telesna dejavnost in dovolj spanja pomembna – tudi ob koncih tedna.",
  "ABOUT_PAGE_7_TITLE": "Temni način",
  "ABOUT_PAGE_7_TEXT": "Ste občutljivi na svetlobo? Vklopite temni način. Kasneje ga lahko vklopite ali izklopite tudi v osebnih nastavitvah.",
  "ABOUT_PAGE_8_TITLE": "Jemanje zdravil",
  "ABOUT_PAGE_8_TEXT": "Poglejte, katera zdravila ste jemali in kdaj – zdravila za napad, preventivna zdravila in injekcije – ter kako dobro je delovalo posamezno zdravilo za napad.",
  "ABOUT_PAGE_9_TITLE": "Dejavniki glavobola",
  "ABOUT_PAGE_9_TEXT": "Odkrijte vzorce glede resnosti, migrene, avre, menstruacije ter dolgih ali kratkih napadov in spremljajte jemanje protibolečinskih zdravil in triptanov skozi čas."
 },
 "sr": {
  "LANDING_READ_MORE": "Сазнајте више о апликацији",
  "ABOUT_TITLE": "О апликацији",
  "ABOUT_INTRO": "Јасан преглед дана са главобољом, њеног интензитета и употребе лекова олакшава проналажење праве терапије заједно са Вашим лекаром. Апликација Вам помаже да све пратите.",
  "ABOUT_STEP_OF": "{current} од {total}",
  "ABOUT_PREVIOUS": "Претходно",
  "ABOUT_NEXT": "Следеће",
  "ABOUT_CLOSE": "Затвори",
  "ABOUT_PAGE_1_TITLE": "Почетни екран",
  "ABOUT_PAGE_1_TEXT": "Преузмите апликацију. Почетни екран на први поглед приказује Ваших последњих 30 дана: дане без бола, са благом, умереном или јаком главобољом и дане када сте узели лек за напад. Додирните Дневни унос да забележите данашњи дан.",
  "ABOUT_PAGE_2_TITLE": "Календар",
  "ABOUT_PAGE_2_TEXT": "У делу Мој дневник сваки дан у календару обојен је према интензитету главобоље, са ознакама за лекове за напад и ауру. Испод је сажетак месеца: сати главобоље, дани по интензитету и дани са лековима.",
  "ABOUT_PAGE_3_TITLE": "Стекните увид",
  "ABOUT_PAGE_3_TEXT": "Прегледајте своје уносе и стекните преглед кроз календар, дневник и низ графикона – на пример, како се Ваша употреба лекова мења током времена.",
  "ABOUT_PAGE_4_TITLE": "Моји подаци",
  "ABOUT_PAGE_4_TEXT": "Пратите интензитет главобоље током времена, погледајте колико добро делује сваки лек за напад и откријте који су фактори повезани са Вашим главобољама – за периоде и до неколико година.",
  "ABOUT_PAGE_5_TITLE": "Поделите са лекаром",
  "ABOUT_PAGE_5_TEXT": "Једноставно поделите своје податке са лекаром. Апликација прави једнократни код који лекар уноси на headachecalendar.com како би видео Ваше уносе.",
  "ABOUT_PAGE_6_TITLE": "Савети",
  "ABOUT_PAGE_6_TEXT": "Добијте практичне савете о главобољи, нпр. о честим окидачима и зашто су редовна физичка активност и довољно сна важни – и викендом.",
  "ABOUT_PAGE_7_TITLE": "Тамни режим",
  "ABOUT_PAGE_7_TEXT": "Осетљиви сте на светлост? Укључите тамни режим. Касније га можете укључити или искључити и у личним подешавањима.",
  "ABOUT_PAGE_8_TITLE": "Употреба лекова",
  "ABOUT_PAGE_8_TEXT": "Погледајте које сте лекове користили и када – лекове за напад, превентивне лекове и ињекције – и колико је добро деловао сваки лек за напад.",
  "ABOUT_PAGE_9_TITLE": "Фактори главобоље",
  "ABOUT_PAGE_9_TEXT": "Уочите обрасце у јачини, мигрени, аури, менструацији и дугим или кратким нападима и пратите употребу лекова против болова и триптана током времена."
 },
 "sv": {
  "LANDING_READ_MORE": "Läs mer om appen",
  "ABOUT_TITLE": "Om appen",
  "ABOUT_INTRO": "En tydlig överblick över huvudvärksdagar, intensitet och läkemedelsanvändning gör det lättare att hitta rätt behandling tillsammans med din läkare. Appen hjälper dig att hålla koll.",
  "ABOUT_STEP_OF": "{current} av {total}",
  "ABOUT_PREVIOUS": "Föregående",
  "ABOUT_NEXT": "Nästa",
  "ABOUT_CLOSE": "Stäng",
  "ABOUT_PAGE_1_TITLE": "Startskärm",
  "ABOUT_PAGE_1_TEXT": "Ladda ner appen. Startskärmen visar dina senaste 30 dagar i en överblick: dagar utan smärta, med lätt, måttlig eller svår huvudvärk, och dagar då du tog anfallsmedicin. Tryck på Daglig registrering för att registrera dagen.",
  "ABOUT_PAGE_2_TITLE": "Kalender",
  "ABOUT_PAGE_2_TEXT": "I Min dagbok färgas varje dag i kalendern efter huvudvärkens intensitet, med markeringar för anfallsmedicin och aura. Nedanför får du en sammanfattning av månaden: timmar med huvudvärk, dagar per intensitet och medicindagar.",
  "ABOUT_PAGE_3_TITLE": "Få insikt",
  "ABOUT_PAGE_3_TEXT": "Gå igenom dina registreringar och få överblick via kalendern, dagboken och en rad diagram – till exempel hur din läkemedelsanvändning utvecklas över tid.",
  "ABOUT_PAGE_4_TITLE": "Mina data",
  "ABOUT_PAGE_4_TEXT": "Följ huvudvärkens intensitet över tid, se hur bra varje anfallsmedicin fungerar och upptäck vilka faktorer som hänger ihop med din huvudvärk – för perioder på upp till flera år.",
  "ABOUT_PAGE_5_TITLE": "Dela med din läkare",
  "ABOUT_PAGE_5_TEXT": "Dela enkelt dina data med din läkare. Appen skapar en engångskod som läkaren anger på headachecalendar.com för att se dina registreringar.",
  "ABOUT_PAGE_6_TITLE": "Tips",
  "ABOUT_PAGE_6_TEXT": "Få praktiska tips om huvudvärk, till exempel vanliga utlösande faktorer och varför regelbunden fysisk aktivitet och tillräckligt med sömn är viktigt – även på helgerna.",
  "ABOUT_PAGE_7_TITLE": "Mörkt läge",
  "ABOUT_PAGE_7_TEXT": "Ljuskänslig? Slå på mörkt läge. Du kan också slå på eller av det senare i dina personliga inställningar.",
  "ABOUT_PAGE_8_TITLE": "Läkemedelsanvändning",
  "ABOUT_PAGE_8_TEXT": "Se vilka läkemedel du har använt och när – anfallsmedicin, förebyggande medicin och injektioner – och hur bra varje anfallsmedicin har fungerat.",
  "ABOUT_PAGE_9_TITLE": "Huvudvärksfaktorer",
  "ABOUT_PAGE_9_TEXT": "Se mönster i svårighetsgrad, migrän, aura, menstruation och långa eller korta anfall, och följ din användning av smärtstillande och triptaner över tid."
 },
 "tr": {
  "LANDING_READ_MORE": "Uygulama hakkında daha fazla bilgi",
  "ABOUT_TITLE": "Uygulama hakkında",
  "ABOUT_INTRO": "Baş ağrılı günlere, ağrının şiddetine ve ilaç kullanımına dair net bir genel bakış, doktorunuzla birlikte doğru tedaviyi bulmayı kolaylaştırır. Uygulama, her şeyi takip etmenize yardımcı olur.",
  "ABOUT_STEP_OF": "{current} / {total}",
  "ABOUT_PREVIOUS": "Önceki",
  "ABOUT_NEXT": "Sonraki",
  "ABOUT_CLOSE": "Kapat",
  "ABOUT_PAGE_1_TITLE": "Ana ekran",
  "ABOUT_PAGE_1_TEXT": "Uygulamayı indirin. Ana ekran son 30 gününüzü tek bakışta gösterir: ağrısız günler, hafif, orta veya şiddetli baş ağrısı olan günler ve atak ilacı aldığınız günler. Bugünü kaydetmek için “Günlük kayıt” düğmesine dokunun.",
  "ABOUT_PAGE_2_TITLE": "Takvim",
  "ABOUT_PAGE_2_TEXT": "“Günlüğüm” bölümünde takvimdeki her gün baş ağrısı şiddetine göre renklendirilir; atak ilacı ve aura için işaretler de yer alır. Altında ayın özetini görürsünüz: baş ağrılı saatler, şiddete göre günler ve ilaç kullanılan günler.",
  "ABOUT_PAGE_3_TITLE": "İçgörü edinin",
  "ABOUT_PAGE_3_TEXT": "Kayıtlarınızı inceleyin; takvim, günlük ve çeşitli grafikler aracılığıyla genel bir bakış edinin – örneğin ilaç kullanımınızın zaman içinde nasıl değiştiğini görün.",
  "ABOUT_PAGE_4_TITLE": "Verilerim",
  "ABOUT_PAGE_4_TEXT": "Baş ağrısı şiddetini zaman içinde izleyin, her atak ilacının ne kadar iyi etki ettiğini görün ve hangi faktörlerin baş ağrılarınızla bağlantılı olduğunu keşfedin – birkaç yıla varan dönemler için.",
  "ABOUT_PAGE_5_TITLE": "Doktorunuzla paylaşın",
  "ABOUT_PAGE_5_TEXT": "Verilerinizi doktorunuzla kolayca paylaşın. Uygulama, doktorunuzun kayıtlarınızı görmek için headachecalendar.com adresinde gireceği tek kullanımlık bir kod oluşturur.",
  "ABOUT_PAGE_6_TITLE": "İpuçları",
  "ABOUT_PAGE_6_TEXT": "Baş ağrısıyla ilgili pratik ipuçları edinin; örneğin sık görülen tetikleyiciler ve düzenli fiziksel aktivite ile yeterli uykunun neden önemli olduğu – hafta sonları da.",
  "ABOUT_PAGE_7_TITLE": "Karanlık mod",
  "ABOUT_PAGE_7_TEXT": "Işığa karşı hassas mısınız? Karanlık modu açın. Bunu daha sonra kişisel ayarlarınızdan da açıp kapatabilirsiniz.",
  "ABOUT_PAGE_8_TITLE": "İlaç kullanımı",
  "ABOUT_PAGE_8_TEXT": "Hangi ilaçları ne zaman kullandığınızı görün – atak ilaçları, koruyucu ilaçlar ve enjeksiyonlar – ve her atak ilacının ne kadar iyi etki ettiğini inceleyin.",
  "ABOUT_PAGE_9_TITLE": "Baş ağrısı faktörleri",
  "ABOUT_PAGE_9_TEXT": "Şiddet, migren, aura, adet dönemi ve uzun ya da kısa ataklardaki örüntüleri görün; ağrı kesici ve triptan kullanımınızı zaman içinde takip edin."
 },
 "uk": {
  "LANDING_READ_MORE": "Детальніше про застосунок",
  "ABOUT_TITLE": "Про застосунок",
  "ABOUT_INTRO": "Наочний огляд днів із головним болем, його інтенсивності та прийому ліків допомагає разом із лікарем підібрати правильне лікування. Застосунок допоможе вам усе відстежувати.",
  "ABOUT_STEP_OF": "{current} з {total}",
  "ABOUT_PREVIOUS": "Назад",
  "ABOUT_NEXT": "Далі",
  "ABOUT_CLOSE": "Закрити",
  "ABOUT_PAGE_1_TITLE": "Головний екран",
  "ABOUT_PAGE_1_TEXT": "Завантажте застосунок. Головний екран з одного погляду показує ваші останні 30 днів: дні без болю, з легким, помірним або сильним головним болем, а також дні, коли ви приймали екстрені ліки. Натисніть «Щоденний запис», щоб внести дані за сьогодні.",
  "ABOUT_PAGE_2_TITLE": "Календар",
  "ABOUT_PAGE_2_TEXT": "У розділі «Мій щоденник» кожен день календаря позначено кольором за інтенсивністю головного болю, з позначками екстрених ліків і аури. Нижче – підсумок місяця: години головного болю, дні за інтенсивністю та дні з ліками.",
  "ABOUT_PAGE_3_TITLE": "Отримайте інсайти",
  "ABOUT_PAGE_3_TEXT": "Переглядайте свої записи й отримуйте загальну картину за допомогою календаря, щоденника та низки графіків – наприклад, як змінюється прийом ліків із часом.",
  "ABOUT_PAGE_4_TITLE": "Мої дані",
  "ABOUT_PAGE_4_TEXT": "Стежте за інтенсивністю головного болю з часом, дивіться, наскільки добре діють ті чи інші екстрені ліки, і з’ясовуйте, які фактори пов’язані з вашим головним болем – за періоди аж до кількох років.",
  "ABOUT_PAGE_5_TITLE": "Поділіться з лікарем",
  "ABOUT_PAGE_5_TEXT": "Легко діліться своїми даними з лікарем. Застосунок створює одноразовий код, який лікар вводить на headachecalendar.com, щоб переглянути ваші записи.",
  "ABOUT_PAGE_6_TITLE": "Поради",
  "ABOUT_PAGE_6_TEXT": "Отримуйте практичні поради щодо головного болю, наприклад про поширені тригери та про те, чому важливі регулярна фізична активність і достатній сон – зокрема у вихідні.",
  "ABOUT_PAGE_7_TITLE": "Темний режим",
  "ABOUT_PAGE_7_TEXT": "Чутливі до світла? Увімкніть темний режим. Ви також можете ввімкнути або вимкнути його пізніше в особистих налаштуваннях.",
  "ABOUT_PAGE_8_TITLE": "Прийом ліків",
  "ABOUT_PAGE_8_TEXT": "Дивіться, які ліки ви приймали і коли – екстрені ліки, профілактичні ліки та ін’єкції – і наскільки добре подіяли ті чи інші екстрені ліки.",
  "ABOUT_PAGE_9_TITLE": "Фактори головного болю",
  "ABOUT_PAGE_9_TEXT": "Виявляйте закономірності щодо тяжкості, мігрені, аури, менструації та довгих чи коротких нападів, а також стежте за прийомом знеболювальних і триптанів із часом."
 }
}
FILE_END

node - <<'NODE_END'
const fs = require("fs");
const texts = JSON.parse(fs.readFileSync(".about-texts.json", "utf8"));
let updated = 0;
for (const [code, add] of Object.entries(texts)) {
  const file = `src/locales/${code}.json`;
  if (!fs.existsSync(file)) { console.log(`  ! ${file} missing – skipped`); continue; }
  const current = JSON.parse(fs.readFileSync(file, "utf8"));
  fs.writeFileSync(file, JSON.stringify({ ...current, ...add }, null, 2) + "\n");
  updated++;
}
console.log(`✓ Added About texts to ${updated} locale files`);
NODE_END
rm -f .about-texts.json

# Check the screenshots
IMG=public/images/about-app
if [ ! -d "$IMG" ]; then
  echo "⚠ $IMG not found – the modal needs images there (e.g. $IMG/no/1.png … 9.png)"
else
  [ -f "$IMG/no/1.png" ] || echo "⚠ $IMG/no/ is the fallback for all languages but has no 1.png"
  missing=""
  for code in ar bg bs ca cs da de el en es et fi fr he hr hu is it ja lt lv mk nl no pl pt pt-BR ro ru sk sl sr sv tr uk; do
    for n in 1 2 3 4 5 6 7 8 9; do
      if [ ! -f "$IMG/$code/$n.png" ]; then missing="$missing $code"; break; fi
    done
  done
  if [ -n "$missing" ]; then
    echo "ℹ Incomplete or missing image folders (Norwegian images are used instead):$missing"
  else
    echo "✓ All 35 image folders have 1.png – 9.png"
  fi
fi

echo "Done. Restart the dev server (npm run dev)."
