// scripts/add-blinded-and-screening.js
// Adds the blinded and screening links, like on kolskalender:
//   /no/blinded?code=123456    – calendar only, every registered day in one light blue
//   /no/screening?code=123456  – the full dashboard, opened straight from the link
//
// Usage (from the HeadacheCalendar folder):
//   node scripts/add-blinded-and-screening.js
//
// Safe to run more than once.

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const read = (f) => fs.readFileSync(path.join(root, f), "utf8");
const write = (f, s) => {
  fs.mkdirSync(path.dirname(path.join(root, f)), { recursive: true });
  fs.writeFileSync(path.join(root, f), s);
};
let failed = false;

// 1) New files
const NEW_FILES = {
  "src/components/headache/useCodeLink.js": "// src/components/headache/useCodeLink.js\n\"use client\";\n\nimport { useEffect, useState } from \"react\";\n\n// One request per code for the lifetime of the page. The code is single-use and dies\n// after a few seconds, so React's dev double-mount must not fire a second request.\nconst requests = new Map();\n\nfunction fetchPatient(code) {\n  if (!requests.has(code)) {\n    requests.set(\n      code,\n      fetch(\"/api/patient-access\", {\n        method: \"POST\",\n        headers: { \"Content-Type\": \"application/json\" },\n        body: JSON.stringify({ code }),\n      })\n        .then(async (res) => {\n          const data = await res.json().catch(() => ({}));\n          if (res.ok && data.patient) return { patient: data.patient };\n          return { errorKey: res.status === 410 ? \"PATIENT_CODE_EXPIRED\" : \"PATIENT_CODE_INVALID\" };\n        })\n        .catch(() => ({ errorKey: \"ERROR_NETWORK\" }))\n    );\n  }\n  return requests.get(code);\n}\n\n// Opens a patient from a link like /no/screening?code=123456.\n// The result is kept in sessionStorage under `storageKey` together with the code,\n// so a reload of the same link shows the same patient without spending a new code.\n// `onLoaded(patient)` runs before the page renders the patient.\nexport function useCodeLink(storageKey, onLoaded) {\n  const [state, setState] = useState({ status: \"loading\" });\n\n  useEffect(() => {\n    const code = (new URLSearchParams(window.location.search).get(\"code\") || \"\").trim();\n    if (!/^\\d{6}$/.test(code)) {\n      setState({ status: \"error\", errorKey: \"PATIENT_CODE_INVALID\" });\n      return;\n    }\n\n    const ready = (patient) => {\n      onLoaded?.(patient);\n      setState({ status: \"ready\", patient });\n    };\n\n    try {\n      const saved = JSON.parse(sessionStorage.getItem(storageKey));\n      if (saved?.code === code && saved.patient) {\n        ready(saved.patient);\n        return;\n      }\n    } catch {}\n\n    let active = true;\n    fetchPatient(code).then((result) => {\n      if (!active) return;\n      if (!result.patient) {\n        setState({ status: \"error\", errorKey: result.errorKey });\n        return;\n      }\n      try {\n        sessionStorage.setItem(storageKey, JSON.stringify({ code, patient: result.patient }));\n      } catch {}\n      ready(result.patient);\n    });\n    return () => {\n      active = false;\n    };\n    // eslint-disable-next-line react-hooks/exhaustive-deps\n  }, [storageKey]);\n\n  return state;\n}\n",
  "src/components/headache/CodeLinkStatus.js": "// src/components/headache/CodeLinkStatus.js\n\"use client\";\n\nimport Link from \"next/link\";\nimport { useLocale } from \"@/components/LocaleProvider\";\n\n// Loading spinner and error card for the /[lang]/blinded and /[lang]/screening links\nexport default function CodeLinkStatus({ errorKey }) {\n  const { t, dir, locale } = useLocale();\n\n  return (\n    <main dir={dir} lang={locale} className=\"flex min-h-screen items-center justify-center p-6\">\n      {errorKey ? (\n        <div className=\"w-full max-w-md rounded-2xl border border-white/70 bg-white/85 p-8 text-center shadow-sm backdrop-blur\">\n          <h1 className=\"font-serif text-2xl font-bold text-[#4f7cc0]\">{t.HEADACHE_DIARY}</h1>\n          <p role=\"alert\" className=\"mt-3 text-sm leading-relaxed text-slate-600\">\n            {t[errorKey]}\n          </p>\n          <Link\n            href=\"/\"\n            className=\"mt-6 inline-block rounded-full bg-[#6a9be0] px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]\"\n          >\n            {t.CLOSE}\n          </Link>\n        </div>\n      ) : (\n        <div\n          role=\"status\"\n          aria-label={t.COMMON_LOADING}\n          className=\"h-8 w-8 animate-spin rounded-full border-[3px] border-[#6a9be0]/25 border-t-[#6a9be0] motion-reduce:animate-none\"\n        />\n      )}\n    </main>\n  );\n}\n",
  "src/components/headache/useUrlLanguage.js": "// src/components/headache/useUrlLanguage.js\n\"use client\";\n\nimport { useEffect } from \"react\";\nimport { notFound, useParams } from \"next/navigation\";\nimport { useLocale } from \"@/components/LocaleProvider\";\nimport { normalizeLocale } from \"@/lib/i18n\";\n\n// The language in links like /no/blinded or /en-US/screening becomes the site language.\n// Short codes work too (\"no\" → nb-NO, \"sv\" → sv-SE); an unknown one is a 404.\nexport function useUrlLanguage() {\n  const { lang } = useParams();\n  const wanted = normalizeLocale(decodeURIComponent(String(lang ?? \"\")));\n  const { locale, setLocale } = useLocale();\n\n  if (!wanted) notFound();\n\n  useEffect(() => {\n    if (wanted !== locale) setLocale(wanted);\n  }, [wanted, locale, setLocale]);\n}\n",
  "src/components/headache/BlindedCalendarCard.js": "// src/components/headache/BlindedCalendarCard.js\n\"use client\";\n\nimport { useMemo, useState } from \"react\";\nimport HeadacheCalendar from \"@/components/headache/HeadacheCalendar\";\nimport { firstRecordMonth, indexRecords } from \"@/components/headache/data\";\n\n// Calendar only, read-only: month navigation and the blinded grid.\n// No day details, monthly summary or medication lists – they would show what the\n// blinded grid hides.\nexport default function BlindedCalendarCard({ patient }) {\n  const now = new Date();\n  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });\n\n  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);\n  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);\n\n  const idx = (v) => v.year * 12 + v.month;\n  const current = { year: now.getFullYear(), month: now.getMonth() };\n  const move = (delta) =>\n    setView((v) => {\n      const n = idx(v) + delta;\n      return { year: Math.floor(n / 12), month: n % 12 };\n    });\n\n  return (\n    <section className=\"rounded-3xl border border-white/70 bg-white/65 p-4 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:px-5 sm:py-5\">\n      <HeadacheCalendar\n        byDate={byDate}\n        year={view.year}\n        month={view.month}\n        canPrev={first ? idx(view) > idx(first) : false}\n        canNext={idx(view) < idx(current)}\n        onPrev={() => move(-1)}\n        onNext={() => move(1)}\n        blinded\n      />\n    </section>\n  );\n}\n",
  "src/app/[lang]/blinded/page.js": "// src/app/[lang]/blinded/page.js\n//\n// Blinded entry – calendar only, read-only:\n//   http://localhost:3000/no/blinded?code=123456\n//\n// Every registered day is drawn in one flat light blue. No intensity colours, icons,\n// period marking, day details, monthly summary, medication lists, statistics or\n// patient details (age/gender).\n//\n// The patient is kept under its own sessionStorage key (\"blinded\"), never under\n// \"patient\", so /dashboard can't be used to open the unblinded view.\n\"use client\";\n\nimport { useRouter } from \"next/navigation\";\nimport BlindedCalendarCard from \"@/components/headache/BlindedCalendarCard\";\nimport CodeLinkStatus from \"@/components/headache/CodeLinkStatus\";\nimport { useCodeLink } from \"@/components/headache/useCodeLink\";\nimport { useHeadacheText } from \"@/components/headache/useHeadacheText\";\nimport { useUrlLanguage } from \"@/components/headache/useUrlLanguage\";\nimport { useLocale } from \"@/components/LocaleProvider\";\n\nconst clearDashboardPatient = () => {\n  try {\n    sessionStorage.removeItem(\"patient\");\n  } catch {}\n};\n\nexport default function BlindedPage() {\n  useUrlLanguage();\n  const router = useRouter();\n  const { t, locale, dir } = useHeadacheText();\n  const { t: siteText } = useLocale();\n  const link = useCodeLink(\"blinded\", clearDashboardPatient);\n\n  if (link.status !== \"ready\") return <CodeLinkStatus errorKey={link.errorKey} />;\n\n  const close = () => {\n    try {\n      sessionStorage.removeItem(\"blinded\");\n    } catch {}\n    router.replace(\"/\");\n  };\n\n  return (\n    <div dir={dir} lang={locale} className=\"min-h-screen pb-12\">\n      <header className=\"sticky top-0 z-30 border-b border-white/70 bg-white/80 backdrop-blur\">\n        <div className=\"flex w-full items-center justify-between gap-3 px-4 py-3 sm:px-6\">\n          <h1 className=\"truncate font-serif text-2xl font-bold text-[#4f7cc0]\">{siteText.HEADACHE_DIARY}</h1>\n          <button\n            type=\"button\"\n            onClick={close}\n            className=\"shrink-0 whitespace-nowrap rounded-full bg-[#6a9be0] px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]\"\n          >\n            {t.DASHBOARD_CLOSE}\n          </button>\n        </div>\n      </header>\n\n      <main className=\"mx-auto mt-6 max-w-md px-4\">\n        <BlindedCalendarCard patient={link.patient} />\n      </main>\n    </div>\n  );\n}\n",
  "src/app/[lang]/screening/page.js": "// src/app/[lang]/screening/page.js\n//\n// Screening entry – the FULL dashboard from a link:\n//   http://localhost:3000/no/screening?code=123456\n//\n// The URL stays as it is: the patient is put in sessionStorage the way the code card\n// on the landing page does it, and the dashboard is rendered in place. A reload of the\n// same link opens the same patient again without spending a new code.\n//\n// Trade-off: the code stays in the URL (history, server logs). Fine for a code that\n// is single-use and dies within seconds.\n\"use client\";\n\nimport DashboardPage from \"@/app/dashboard/page\";\nimport CodeLinkStatus from \"@/components/headache/CodeLinkStatus\";\nimport { useCodeLink } from \"@/components/headache/useCodeLink\";\nimport { useUrlLanguage } from \"@/components/headache/useUrlLanguage\";\n\nconst seedDashboard = (patient) => {\n  try {\n    sessionStorage.setItem(\"patient\", JSON.stringify(patient));\n  } catch {}\n};\n\nexport default function ScreeningPage() {\n  useUrlLanguage();\n  const link = useCodeLink(\"screening\", seedDashboard);\n\n  if (link.status !== \"ready\") return <CodeLinkStatus errorKey={link.errorKey} />;\n  return <DashboardPage />;\n}\n"
};
for (const [file, content] of Object.entries(NEW_FILES)) {
  const exists = fs.existsSync(path.join(root, file));
  if (exists && read(file) === content) {
    console.log("Already there:", file);
    continue;
  }
  write(file, content);
  console.log(exists ? "Replaced:" : "Created: ", file);
}

// 2) Changes to existing files
const PATCHES = [
  {
    "file": "src/components/headache/HeadacheCalendar.js",
    "from": "const FILL = { 1: COLORS.mild, 2: COLORS.moderate, 3: COLORS.strong, 4: COLORS.extreme };\n\nexport default function HeadacheCalendar({\n  byDate,\n",
    "to": "const FILL = { 1: COLORS.mild, 2: COLORS.moderate, 3: COLORS.strong, 4: COLORS.extreme };\n\n// Blinded: every registered day in one flat light blue, so only *whether* a day was\n// registered shows – not intensity, medication, aura, cluster, period or notes\nconst BLIND_BG = \"#DCEBF7\";\nconst BLIND_TEXT = \"#14324a\";\n\nexport default function HeadacheCalendar({\n  byDate,\n"
  },
  {
    "file": "src/components/headache/HeadacheCalendar.js",
    "from": "  onSelect,\n  showNotes = false,\n}) {\n  const { t, locale } = useHeadacheText();\n",
    "to": "  onSelect,\n  showNotes = false,\n  blinded = false,\n}) {\n  const { t, locale } = useHeadacheText();\n"
  },
  {
    "file": "src/components/headache/HeadacheCalendar.js",
    "from": "            const isSelected = key === selected;\n            const note = showNotes && hasNote(r);\n\n            let box = \"border border-dashed border-slate-200 text-slate-400\"; // past, nothing registered\n",
    "to": "            const isSelected = key === selected;\n            const note = showNotes && hasNote(r);\n\n            if (blinded) {\n              // Read-only and nothing but registered / not registered – also in the screen-reader label\n              return (\n                <div\n                  key={i}\n                  role=\"gridcell\"\n                  aria-label={`${longDate.format(new Date(year, month, day))}, ${r ? t.CAL_REGISTERED : t.CAL_NO_REGISTRATION}`}\n                  className=\"h-8 rounded-md p-[3px]\"\n                >\n                  <span\n                    className={`flex h-full w-full items-center justify-center rounded-md text-xs font-semibold tabular-nums ${\n                      r\n                        ? \"\"\n                        : isToday\n                          ? \"ring-2 ring-[#6b93d1] ring-offset-1 text-slate-500\"\n                          : isFuture\n                            ? \"text-slate-300\"\n                            : \"border border-dashed border-slate-200 text-slate-400\"\n                    }`}\n                    style={r ? { backgroundColor: BLIND_BG, color: BLIND_TEXT } : undefined}\n                  >\n                    {day}\n                  </span>\n                </div>\n              );\n            }\n\n            let box = \"border border-dashed border-slate-200 text-slate-400\"; // past, nothing registered\n"
  },
  {
    "file": "src/components/headache/usePatient.js",
    "from": "    try {\n      sessionStorage.removeItem(\"patient\");\n    } catch {}\n    router.replace(\"/\"); // replace: Back shouldn't return to a closed patient\n",
    "to": "    try {\n      sessionStorage.removeItem(\"patient\");\n      sessionStorage.removeItem(\"screening\"); // opened from a /[lang]/screening link\n    } catch {}\n    router.replace(\"/\"); // replace: Back shouldn't return to a closed patient\n"
  }
];
const pending = {};
for (const p of PATCHES) {
  const src = pending[p.file] ?? read(p.file);
  if (src.includes(p.to)) {
    pending[p.file] = src;
    continue;
  }
  if (!src.includes(p.from)) {
    console.error("Could not find the code to replace in", p.file, "(has it been changed?)");
    failed = true;
    continue;
  }
  pending[p.file] = src.replace(p.from, p.to);
}
for (const [file, src] of Object.entries(pending)) {
  if (src === read(file)) console.log("Already updated:", file);
  else {
    write(file, src);
    console.log("Updated:", file);
  }
}

// 3) New text CAL_REGISTERED (screen-reader label for a registered day in the blinded calendar)
const REGISTERED = {
  "ar": "مسجّل",
  "bg": "Записано",
  "bs": "Uneseno",
  "ca": "Registrat",
  "cs": "Zaznamenáno",
  "da": "Registreret",
  "de": "Eingetragen",
  "el": "Καταγεγραμμένο",
  "en": "Registered",
  "es": "Registrado",
  "et": "Registreeritud",
  "fi": "Kirjattu",
  "fr": "Enregistré",
  "he": "נרשם",
  "hr": "Uneseno",
  "hu": "Rögzítve",
  "is": "Skráð",
  "it": "Registrato",
  "ja": "記録あり",
  "lt": "Užregistruota",
  "lv": "Reģistrēts",
  "mk": "Внесено",
  "nl": "Geregistreerd",
  "no": "Registrert",
  "pl": "Zarejestrowano",
  "pt-BR": "Registrado",
  "pt": "Registado",
  "ro": "Înregistrat",
  "ru": "Записано",
  "sk": "Zaznamenané",
  "sl": "Vpisano",
  "sr": "Унето",
  "sv": "Registrerad",
  "tr": "Kaydedildi",
  "uk": "Записано"
};
const textsFile = "src/components/headache/texts.js";
let texts = read(textsFile);
if (texts.includes('"CAL_REGISTERED":')) {
  console.log("Already updated:", textsFile);
} else {
  let added = 0;
  texts = texts.replace(/^  "([A-Za-z-]+)": \{\n[\s\S]*?(?=^  "[A-Za-z-]+": \{|^\};)/gm, (block, lang) => {
    if (!REGISTERED[lang]) return block;
    return block.replace(/^(    "CAL_NO_REGISTRATION": .*,\n)/m, (line) => {
      added++;
      return `${line}    "CAL_REGISTERED": ${JSON.stringify(REGISTERED[lang])},\n`;
    });
  });
  if (added === Object.keys(REGISTERED).length) {
    write(textsFile, texts);
    console.log(`Updated: ${textsFile} (CAL_REGISTERED in ${added} languages)`);
  } else {
    console.error(`Expected ${Object.keys(REGISTERED).length} languages in ${textsFile}, found ${added} – not changed`);
    failed = true;
  }
}

process.exit(failed ? 1 : 0);
