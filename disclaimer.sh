#!/usr/bin/env bash
# disclaimer.sh
# Landing page: the purpose text under "Read more about the app", like on kolskalender –
# small italic text, as wide as the phone image and left-aligned with it (centred on phones):
#   "The purpose of the solution is to enable the user to record relevant information about
#    headaches, symptoms and medications. …"
#  - new text LANDING_DISCLAIMER in all 35 files in src/locales/ (after LANDING_READ_MORE)
#  - safe to run again (updates the text if it is already there)
# Run from the project root:  bash disclaimer.sh
set -euo pipefail

PAGE=src/app/page.js
if [ ! -f "$PAGE" ] || [ ! -d src/locales ]; then
  echo "✗ $PAGE or src/locales not found – run this from the project root." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- the text under the Read more button --------------------------------------------------
cat > "$TMP/page.json" <<'FILE_END'
{
  "old": "        <div className=\"flex justify-center lg:col-start-1 lg:row-start-3 lg:w-[75%] lg:justify-self-end lg:justify-start\">\n          <ReadMoreButton />\n        </div>\n",
  "new": "        <div className=\"flex flex-col items-center lg:col-start-1 lg:row-start-3 lg:w-[75%] lg:items-start lg:justify-self-end\">\n          <ReadMoreButton />\n          {t.LANDING_DISCLAIMER && (\n            <p className=\"mt-4 max-w-2xl text-center text-[13px] italic leading-relaxed text-slate-600 lg:text-start\">\n              {t.LANDING_DISCLAIMER}\n            </p>\n          )}\n        </div>\n"
}
FILE_END

node - "$PAGE" "$TMP/page.json" <<'NODE_END'
const fs = require("fs");
const [file, changeFile] = process.argv.slice(2);
const { old: from, new: to } = JSON.parse(fs.readFileSync(changeFile, "utf8"));
let src = fs.readFileSync(file, "utf8");
if (src.includes("t.LANDING_DISCLAIMER")) {
  console.log(`✓ ${file} already shows the text`);
} else if (src.includes(from)) {
  fs.writeFileSync(file, src.replace(from, to));
  console.log(`✓ ${file} (text under Read more)`);
} else {
  console.error(`✗ ${file}: the Read more block differs from what this script expects – run front-image.sh first.`);
  process.exit(1);
}
NODE_END

# ---- texts in all languages --------------------------------------------------------------
cat > "$TMP/texts.json" <<'FILE_END'
{
  "ar-SA": "الغرض من الحل هو تمكين المستخدم من تسجيل المعلومات ذات الصلة بالصداع والأعراض والأدوية. يوفر الحل تخزين المعلومات ومشاركتها بسهولة بين مقدم الرعاية الصحية والمستخدم. لا يقدم الحل استنتاجات طبية أو تحليلًا أو دعمًا لاتخاذ القرار بناءً على بيانات المستخدم. يقدم الحل معلومات عامة مبنية على إرشادات معترف بها.",
  "bg-BG": "Целта на решението е да даде възможност на потребителя да записва важна информация за главоболието, симптомите и лекарствата. Решението предлага съхранение на информацията и лесно споделяне между медицинския специалист и потребителя. Решението не дава медицински заключения, нито анализ и подкрепа при вземане на решения въз основа на данните на потребителя. Решението предлага обща информация, основана на признати насоки.",
  "bs-BA": "Svrha rješenja je omogućiti korisniku da bilježi relevantne informacije o glavobolji, simptomima i lijekovima. Rješenje nudi pohranu informacija i jednostavno dijeljenje između zdravstvenog radnika i korisnika. Rješenje ne daje medicinske zaključke niti analizu i podršku u odlučivanju na osnovu korisničkih podataka. Rješenje nudi opće informacije zasnovane na priznatim smjernicama.",
  "ca-ES": "La finalitat de la solució és permetre a l'usuari registrar informació rellevant sobre el mal de cap, els símptomes i la medicació. La solució ofereix emmagatzematge de la informació i una manera fàcil de compartir-la entre el professional sanitari i l'usuari. La solució no ofereix conclusions mèdiques ni anàlisi o suport a la presa de decisions basats en les dades de l'usuari. La solució ofereix informació general basada en guies reconegudes.",
  "cs-CZ": "Účelem řešení je umožnit uživateli zaznamenávat důležité informace o bolestech hlavy, příznacích a lécích. Řešení nabízí ukládání informací a snadné sdílení mezi zdravotníkem a uživatelem. Řešení neposkytuje lékařské závěry ani analýzu a podporu rozhodování na základě údajů uživatele. Řešení nabízí obecné informace založené na uznávaných doporučených postupech.",
  "da-DK": "Formålet med løsningen er at give brugeren mulighed for at registrere relevante oplysninger om hovedpine, symptomer og medicin. Løsningen tilbyder lagring af oplysninger og nem deling mellem sundhedspersonale og bruger. Løsningen giver ikke medicinske konklusioner eller analyse og beslutningsstøtte baseret på brugerens data. Løsningen tilbyder generel information baseret på anerkendte retningslinjer.",
  "de-DE": "Zweck der Lösung ist es, dem Nutzer zu ermöglichen, relevante Informationen zu Kopfschmerzen, Symptomen und Medikamenten zu erfassen. Die Lösung bietet die Speicherung der Informationen und ein einfaches Teilen zwischen medizinischem Fachpersonal und Nutzer. Die Lösung liefert keine medizinischen Schlussfolgerungen und keine Analyse oder Entscheidungsunterstützung auf Grundlage der Nutzerdaten. Die Lösung bietet allgemeine Informationen auf Grundlage anerkannter Leitlinien.",
  "el-GR": "Σκοπός της λύσης είναι να επιτρέπει στον χρήστη να καταγράφει σχετικές πληροφορίες για τον πονοκέφαλο, τα συμπτώματα και τα φάρμακα. Η λύση προσφέρει αποθήκευση των πληροφοριών και εύκολη κοινοποίηση μεταξύ επαγγελματία υγείας και χρήστη. Η λύση δεν παρέχει ιατρικά συμπεράσματα ούτε ανάλυση και υποστήριξη αποφάσεων με βάση τα δεδομένα του χρήστη. Η λύση προσφέρει γενικές πληροφορίες βασισμένες σε αναγνωρισμένες κατευθυντήριες οδηγίες.",
  "en-US": "The purpose of the solution is to enable the user to record relevant information about headaches, symptoms and medications. The solution offers storage of information and easy sharing between healthcare provider and user. The solution does not provide medical conclusions, or analysis and decision support based on user data. The solution offers general information based on recognised guidelines.",
  "es-ES": "La finalidad de la solución es permitir al usuario registrar información relevante sobre el dolor de cabeza, los síntomas y la medicación. La solución ofrece almacenamiento de la información y una forma sencilla de compartirla entre el profesional sanitario y el usuario. La solución no ofrece conclusiones médicas ni análisis o apoyo a la toma de decisiones basados en los datos del usuario. La solución ofrece información general basada en guías reconocidas.",
  "et-EE": "Lahenduse eesmärk on võimaldada kasutajal registreerida olulist teavet peavalu, sümptomite ja ravimite kohta. Lahendus pakub teabe säilitamist ja lihtsat jagamist tervishoiutöötaja ja kasutaja vahel. Lahendus ei anna meditsiinilisi järeldusi ega kasutaja andmetel põhinevat analüüsi ja otsustustuge. Lahendus pakub üldist teavet, mis põhineb tunnustatud juhistel.",
  "fi-FI": "Ratkaisun tarkoitus on mahdollistaa, että käyttäjä voi kirjata olennaisia tietoja päänsärystä, oireista ja lääkkeistä. Ratkaisu tarjoaa tietojen tallennuksen ja helpon jakamisen terveydenhuollon ammattilaisen ja käyttäjän välillä. Ratkaisu ei tee lääketieteellisiä johtopäätöksiä eikä tarjoa käyttäjän tietoihin perustuvaa analyysia tai päätöksenteon tukea. Ratkaisu tarjoaa yleistä tietoa, joka perustuu tunnustettuihin hoitosuosituksiin.",
  "fr-FR": "L'objectif de la solution est de permettre à l'utilisateur d'enregistrer des informations pertinentes sur les maux de tête, les symptômes et les médicaments. La solution permet de stocker les informations et de les partager facilement entre le professionnel de santé et l'utilisateur. La solution ne fournit pas de conclusions médicales, ni d'analyse ou d'aide à la décision fondées sur les données de l'utilisateur. La solution propose des informations générales fondées sur des recommandations reconnues.",
  "he-IL": "מטרת הפתרון היא לאפשר למשתמש לתעד מידע רלוונטי על כאבי ראש, תסמינים ותרופות. הפתרון מציע אחסון של המידע ושיתוף קל בין איש הצוות הרפואי למשתמש. הפתרון אינו מספק מסקנות רפואיות, ניתוח או תמיכה בקבלת החלטות על סמך נתוני המשתמש. הפתרון מציע מידע כללי המבוסס על הנחיות מוכרות.",
  "hr-HR": "Svrha rješenja je omogućiti korisniku da bilježi relevantne informacije o glavobolji, simptomima i lijekovima. Rješenje nudi pohranu informacija i jednostavno dijeljenje između zdravstvenog djelatnika i korisnika. Rješenje ne daje medicinske zaključke niti analizu i podršku u odlučivanju na temelju korisničkih podataka. Rješenje nudi opće informacije temeljene na priznatim smjernicama.",
  "hu-HU": "A megoldás célja, hogy a felhasználó rögzíthesse a fejfájással, a tünetekkel és a gyógyszerekkel kapcsolatos fontos információkat. A megoldás lehetővé teszi az információk tárolását és egyszerű megosztását az egészségügyi szakember és a felhasználó között. A megoldás nem ad orvosi következtetéseket, és nem nyújt a felhasználói adatokon alapuló elemzést vagy döntéstámogatást. A megoldás elismert irányelveken alapuló általános információkat kínál.",
  "is-IS": "Tilgangur lausnarinnar er að gera notandanum kleift að skrá viðeigandi upplýsingar um höfuðverk, einkenni og lyf. Lausnin býður upp á geymslu upplýsinga og auðvelda deilingu milli heilbrigðisstarfsmanns og notanda. Lausnin veitir hvorki læknisfræðilegar niðurstöður né greiningu og ákvarðanastuðning byggðan á gögnum notandans. Lausnin býður upp á almennar upplýsingar byggðar á viðurkenndum leiðbeiningum.",
  "it-IT": "Lo scopo della soluzione è consentire all'utente di registrare informazioni rilevanti su mal di testa, sintomi e farmaci. La soluzione offre l'archiviazione delle informazioni e una facile condivisione tra operatore sanitario e utente. La soluzione non fornisce conclusioni mediche, né analisi o supporto decisionale basati sui dati dell'utente. La soluzione offre informazioni generali basate su linee guida riconosciute.",
  "ja-JP": "本ソリューションの目的は、ユーザーが頭痛、症状、服薬に関する情報を記録できるようにすることです。本ソリューションは、情報の保存と、医療従事者とユーザーの間での簡単な共有を提供します。本ソリューションは、ユーザーのデータに基づく医学的な結論、分析、意思決定支援を提供するものではありません。本ソリューションは、認められたガイドラインに基づく一般的な情報を提供します。",
  "lt-LT": "Sprendimo paskirtis – leisti naudotojui registruoti svarbią informaciją apie galvos skausmą, simptomus ir vaistus. Sprendimas siūlo informacijos saugojimą ir paprastą dalijimąsi tarp sveikatos priežiūros specialisto ir naudotojo. Sprendimas nepateikia medicininių išvadų, analizės ar sprendimų priėmimo pagalbos pagal naudotojo duomenis. Sprendimas pateikia bendrą informaciją, pagrįstą pripažintomis gairėmis.",
  "lv-LV": "Risinājuma mērķis ir ļaut lietotājam reģistrēt būtisku informāciju par galvassāpēm, simptomiem un medikamentiem. Risinājums piedāvā informācijas glabāšanu un ērtu kopīgošanu starp veselības aprūpes speciālistu un lietotāju. Risinājums nesniedz medicīniskus secinājumus, kā arī analīzi un lēmumu atbalstu, pamatojoties uz lietotāja datiem. Risinājums piedāvā vispārīgu informāciju, kas balstīta uz atzītām vadlīnijām.",
  "mk-MK": "Целта на решението е да му овозможи на корисникот да евидентира релевантни информации за главоболката, симптомите и лековите. Решението нуди чување на информациите и лесно споделување меѓу здравствениот работник и корисникот. Решението не дава медицински заклучоци, ниту анализа и поддршка при одлучување врз основа на податоците на корисникот. Решението нуди општи информации засновани на признаени упатства.",
  "nb-NO": "Formålet med løsningen er å gjøre det mulig for brukeren å registrere relevant informasjon om hodepine, symptomer og medisiner. Løsningen tilbyr lagring av informasjon og enkel deling mellom helsepersonell og bruker. Løsningen gir ikke medisinske konklusjoner eller analyse og beslutningsstøtte basert på brukerens data. Løsningen tilbyr generell informasjon basert på anerkjente retningslinjer.",
  "nl-NL": "Het doel van de oplossing is de gebruiker in staat te stellen relevante informatie over hoofdpijn, symptomen en medicatie vast te leggen. De oplossing biedt opslag van informatie en eenvoudig delen tussen zorgverlener en gebruiker. De oplossing geeft geen medische conclusies en biedt geen analyse of beslissingsondersteuning op basis van gebruikersgegevens. De oplossing biedt algemene informatie op basis van erkende richtlijnen.",
  "pl-PL": "Celem rozwiązania jest umożliwienie użytkownikowi rejestrowania istotnych informacji o bólach głowy, objawach i lekach. Rozwiązanie umożliwia przechowywanie informacji i łatwe udostępnianie ich między pracownikiem ochrony zdrowia a użytkownikiem. Rozwiązanie nie formułuje wniosków medycznych ani nie zapewnia analizy i wsparcia decyzji na podstawie danych użytkownika. Rozwiązanie zawiera ogólne informacje oparte na uznanych wytycznych.",
  "pt-BR": "O objetivo da solução é permitir que o usuário registre informações relevantes sobre dor de cabeça, sintomas e medicamentos. A solução oferece armazenamento das informações e compartilhamento fácil entre o profissional de saúde e o usuário. A solução não fornece conclusões médicas nem análise e apoio à decisão com base nos dados do usuário. A solução oferece informações gerais baseadas em diretrizes reconhecidas.",
  "pt-PT": "O objetivo da solução é permitir que o utilizador registe informação relevante sobre dores de cabeça, sintomas e medicamentos. A solução oferece armazenamento da informação e partilha fácil entre o profissional de saúde e o utilizador. A solução não fornece conclusões médicas nem análise e apoio à decisão com base nos dados do utilizador. A solução oferece informação geral baseada em orientações reconhecidas.",
  "ro-RO": "Scopul soluției este de a-i permite utilizatorului să înregistreze informații relevante despre durerile de cap, simptome și medicamente. Soluția oferă stocarea informațiilor și partajarea ușoară între profesionistul din domeniul sănătății și utilizator. Soluția nu oferă concluzii medicale și nici analiză sau sprijin decizional pe baza datelor utilizatorului. Soluția oferă informații generale bazate pe ghiduri recunoscute.",
  "ru-RU": "Цель решения — дать пользователю возможность записывать важную информацию о головной боли, симптомах и лекарствах. Решение обеспечивает хранение информации и удобный обмен ею между медицинским специалистом и пользователем. Решение не даёт медицинских заключений, а также не выполняет анализ и не поддерживает принятие решений на основе данных пользователя. Решение предлагает общую информацию, основанную на признанных рекомендациях.",
  "sk-SK": "Účelom riešenia je umožniť používateľovi zaznamenávať dôležité informácie o bolestiach hlavy, príznakoch a liekoch. Riešenie ponúka ukladanie informácií a jednoduché zdieľanie medzi zdravotníkom a používateľom. Riešenie neposkytuje lekárske závery ani analýzu a podporu rozhodovania na základe údajov používateľa. Riešenie ponúka všeobecné informácie založené na uznávaných odporúčaniach.",
  "sl-SI": "Namen rešitve je uporabniku omogočiti beleženje pomembnih podatkov o glavobolu, simptomih in zdravilih. Rešitev omogoča shranjevanje podatkov in preprosto deljenje med zdravstvenim delavcem in uporabnikom. Rešitev ne podaja medicinskih zaključkov niti analize in podpore pri odločanju na podlagi uporabnikovih podatkov. Rešitev ponuja splošne informacije, ki temeljijo na priznanih smernicah.",
  "sr-RS": "Сврха решења је да омогући кориснику да бележи релевантне информације о главобољи, симптомима и лековима. Решење нуди чување информација и једноставно дељење између здравственог радника и корисника. Решење не даје медицинске закључке нити анализу и подршку у одлучивању на основу корисничких података. Решење нуди опште информације засноване на признатим смерницама.",
  "sv-SE": "Syftet med lösningen är att göra det möjligt för användaren att registrera relevant information om huvudvärk, symtom och läkemedel. Lösningen erbjuder lagring av information och enkel delning mellan vårdpersonal och användare. Lösningen ger inga medicinska slutsatser eller analys och beslutsstöd baserat på användarens data. Lösningen erbjuder allmän information baserad på erkända riktlinjer.",
  "tr-TR": "Çözümün amacı, kullanıcının baş ağrısı, belirtiler ve ilaçlarla ilgili önemli bilgileri kaydetmesini sağlamaktır. Çözüm, bilgilerin saklanmasını ve sağlık profesyoneli ile kullanıcı arasında kolayca paylaşılmasını sunar. Çözüm, kullanıcı verilerine dayalı tıbbi sonuçlar, analiz veya karar desteği sağlamaz. Çözüm, kabul görmüş kılavuzlara dayanan genel bilgiler sunar.",
  "uk-UA": "Мета рішення — дати користувачеві змогу записувати важливу інформацію про головний біль, симптоми та ліки. Рішення забезпечує зберігання інформації та зручний обмін нею між медичним працівником і користувачем. Рішення не надає медичних висновків, а також аналізу й підтримки ухвалення рішень на основі даних користувача. Рішення пропонує загальну інформацію, що ґрунтується на визнаних настановах."
}
FILE_END

node - "$TMP/texts.json" <<'NODE_END'
const fs = require("fs");
const texts = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const KEY = "LANDING_DISCLAIMER";
const dir = "src/locales";
let failed = false;

for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json")).sort()) {
  const code = file.replace(/\.json$/, "");
  if (!texts[code]) console.log(`! ${file}: no translation, using English`);
  const value = JSON.stringify(texts[code] ?? texts["en-US"]);
  const p = `${dir}/${file}`;
  let src = fs.readFileSync(p, "utf8");
  const before = JSON.parse(src);
  const indent = (src.match(/^([ \t]+)"/m) || [, "\t"])[1];

  const existing = new RegExp(`^([ \\t]*)"${KEY}":.*$`, "m");
  if (existing.test(src)) {
    src = src.replace(existing, (line, ind) => `${ind}"${KEY}": ${value}${line.trimEnd().endsWith(",") ? "," : ""}`);
  } else {
    const anchor = /^[ \t]*"LANDING_READ_MORE":.*,[ \t]*$/m;
    if (anchor.test(src)) src = src.replace(anchor, (line) => `${line}\n${indent}"${KEY}": ${value},`);
    else src = src.replace(/\s*}\s*$/, `,\n${indent}"${KEY}": ${value}\n}\n`);
  }

  const after = JSON.parse(src);
  if (after[KEY] !== JSON.parse(value) || Object.keys(after).length < Object.keys(before).length) {
    console.error(`✗ ${file}: could not add ${KEY}`);
    failed = true;
    continue;
  }
  fs.writeFileSync(p, src);
}
if (failed) process.exit(1);
console.log(`✓ ${KEY} in all src/locales/*.json`);
NODE_END
