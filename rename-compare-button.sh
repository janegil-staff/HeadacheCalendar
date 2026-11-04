#!/usr/bin/env bash
# rename-compare-button.sh
# Renames the REF_OPEN button text from "Compare before and after a reference date"
# to "Compare before and after" in all languages in src/components/headache/texts.js.
# Run from the project root:  bash rename-compare-button.sh
set -euo pipefail
F=src/components/headache/texts.js
[ -f "$F" ] || { echo "✗ $F not found – run this from the project root." >&2; exit 1; }
node - "$F" <<'JS'
const fs = require("fs");
const file = process.argv[2];
const map = {
  "قارن قبل تاريخ مرجعي وبعده": "قارن قبل وبعد",
  "Сравни преди и след референтна дата": "Сравни преди и след",
  "Uporedi prije i poslije referentnog datuma": "Uporedi prije i poslije",
  "Comparar abans i després d’una data de referència": "Comparar abans i després",
  "Porovnat před a po referenčním datu": "Porovnat před a po",
  "Sammenlign før og efter en referencedato": "Sammenlign før og efter",
  "Vor und nach einem Stichtag vergleichen": "Vorher und nachher vergleichen",
  "Σύγκριση πριν και μετά από μια ημερομηνία αναφοράς": "Σύγκριση πριν και μετά",
  "Compare before and after a reference date": "Compare before and after",
  "Comparar antes y después de una fecha de referencia": "Comparar antes y después",
  "Võrdle enne ja pärast võrdluskuupäeva": "Võrdle enne ja pärast",
  "Vertaa ennen ja jälkeen viitepäivämäärän": "Vertaa ennen ja jälkeen",
  "Comparer avant et après une date de référence": "Comparer avant et après",
  "השוואה לפני ואחרי תאריך ייחוס": "השוואה לפני ואחרי",
  "Usporedi prije i poslije referentnog datuma": "Usporedi prije i poslije",
  "Összehasonlítás egy viszonyítási dátum előtt és után": "Összehasonlítás előtte és utána",
  "Bera saman fyrir og eftir viðmiðunardagsetningu": "Bera saman fyrir og eftir",
  "Confronta prima e dopo una data di riferimento": "Confronta prima e dopo",
  "基準日の前後を比較": "前後を比較",
  "Palyginti prieš ir po atskaitos datos": "Palyginti prieš ir po",
  "Salīdzināt pirms un pēc atsauces datuma": "Salīdzināt pirms un pēc",
  "Спореди пред и по референтен датум": "Спореди пред и по",
  "Vergelijk voor en na een referentiedatum": "Vergelijk voor en na",
  "Sammenlign før og etter en referansedato": "Sammenlign før og etter",
  "Porównaj przed i po dacie odniesienia": "Porównaj przed i po",
  "Comparar antes e depois de uma data de referência": "Comparar antes e depois",
  "Compară înainte și după o dată de referință": "Compară înainte și după",
  "Сравнить до и после опорной даты": "Сравнить до и после",
  "Porovnať pred a po referenčnom dátume": "Porovnať pred a po",
  "Primerjaj pred in po referenčnem datumu": "Primerjaj pred in po",
  "Упореди пре и после референтног датума": "Упореди пре и после",
  "Jämför före och efter ett referensdatum": "Jämför före och efter",
  "Bir referans tarihinden önce ve sonrasını karşılaştır": "Öncesi ve sonrasını karşılaştır",
  "Порівняти до та після опорної дати": "Порівняти до та після",
};
let src = fs.readFileSync(file, "utf8");
let changed = 0;
src = src.replace(/("REF_OPEN":\s*")([^"]*)(")/g, (m, a, v, b) => {
  if (map[v]) { changed++; return a + map[v] + b; }
  return m;
});
fs.writeFileSync(file, src);
const total = (src.match(/"REF_OPEN":/g) || []).length;
console.log(`✓ Renamed REF_OPEN in ${changed} of ${total} languages` + (changed ? "" : " (already renamed?)"));
JS
