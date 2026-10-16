// src/components/headache/data.js
// Pure helpers for the patient data returned by /api/patients/details/json

export const INTENSITY = {
  0: { key: "CAL_NO_HEADACHE", face: "none" },
  1: { key: "CAL_MILD", face: "mild" },
  2: { key: "CAL_MODERATE", face: "moderate" },
  3: { key: "CAL_STRONG", face: "strong" },
  4: { key: "CAL_EXTREME", face: "extreme" },
};

// Same colours as the app
export const COLORS = {
  none: "#7ea6e6",
  mild: "#5cb87e",
  moderate: "#f6c45f",
  strong: "#ee766e",
  extreme: "#b53b31",
  today: "#6b93d1",
  period: "#fde6ee",
  acute: "#e5484d",
  aura: "#f2c230",
  cluster: "#6b2fb3",
};

export const EFFECT_KEYS = { 1: "EFFECT_NONE", 2: "EFFECT_MODERATE", 3: "EFFECT_GOOD" };

// CGRP antibodies (N02CD) and botulinum toxin (M03AX01) are given as injections
const INJECTION_ATC = [/^N02CD/i, /^M03AX01/i];
const isInjectionAtc = (atc) => !!atc && INJECTION_ATC.some((re) => re.test(atc));

export const pad = (n) => String(n).padStart(2, "0");
export const toDateKey = (y, m, d) => `${y}-${pad(m + 1)}-${pad(d)}`; // m is 0-based
export const monthKey = (y, m) => `${y}-${pad(m + 1)}`;

export function todayKey() {
  const now = new Date();
  return toDateKey(now.getFullYear(), now.getMonth(), now.getDate());
}

export function indexRecords(records = []) {
  const map = new Map();
  for (const r of records) if (r?.date) map.set(r.date, r);
  return map;
}

export const hasAcute = (r) => (r?.acuteMedicines?.length ?? 0) > 0;

export function hasInjection(r) {
  if (!r) return false;
  return [...(r.acuteMedicinesAtc ?? []), ...(r.preventiveMedicinesAtc ?? [])].some(isInjectionAtc);
}

export const intensityOf = (r) => Math.max(0, Math.min(4, Number(r?.intensity) || 0));

// Calendar grid for a month: weeks starting on Monday, null for padding cells
export function monthGrid(year, month) {
  const first = new Date(year, month, 1);
  const lead = (first.getDay() + 6) % 7; // Monday = 0
  const days = new Date(year, month + 1, 0).getDate();
  const cells = [...Array(lead).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
  while (cells.length % 7) cells.push(null);
  return cells;
}

export function monthStats(byDate, year, month) {
  const prefix = monthKey(year, month);
  const stats = {
    attacks: 0,
    minutes: 0,
    intensity: [0, 0, 0, 0, 0],
    migraine: 0,
    aura: 0,
    cluster: 0,
    period: 0,
    acuteDays: 0,
    injectionDays: 0,
    registered: 0,
  };
  for (const [date, r] of byDate) {
    if (!date.startsWith(prefix)) continue;
    stats.registered++;
    stats.attacks += Number(r.attacks) || 0;
    stats.minutes += Number(r.durationMinutes) || 0;
    stats.intensity[intensityOf(r)]++;
    if (r.isMigraine) stats.migraine++;
    if (r.hasAura) stats.aura++;
    if (r.hasClusterHeadache) stats.cluster++;
    if (r.hasPeriod) stats.period++;
    if (hasAcute(r)) stats.acuteDays++;
    if (hasInjection(r)) stats.injectionDays++;
  }
  return stats;
}

// headacheScores is keyed by the first day of the month, e.g. "2026-09-01"
export const monthScore = (patient, year, month) =>
  patient?.headacheScores?.[`${monthKey(year, month)}-01`] ?? null;

export function firstRecordMonth(records = []) {
  let min = null;
  for (const r of records) if (r?.date && (!min || r.date < min)) min = r.date;
  if (!min) return null;
  const [y, m] = min.split("-").map(Number);
  return { year: y, month: m - 1 };
}

export function medicineName(patient, id) {
  const m = patient?.medicines?.find((x) => x.id === id);
  return m?.name ?? String(id);
}

// Intl wants "nb" for Norwegian
export const intlLocale = (locale) => (locale === "no" ? "nb" : locale);

export function formatUnit(locale, value, unit) {
  try {
    return new Intl.NumberFormat(intlLocale(locale), {
      style: "unit",
      unit,
      unitDisplay: "long",
      maximumFractionDigits: 1,
    }).format(value);
  } catch {
    return `${value} ${unit}`;
  }
}

// ---------- Overview helpers for the dashboard sidebar ----------

// Records in the last `days` days, counted back from today (inclusive)
export function recordsInLastDays(byDate, days) {
  const now = new Date();
  const out = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    const r = byDate.get(toDateKey(d.getFullYear(), d.getMonth(), d.getDate()));
    if (r) out.push(r);
  }
  return out;
}

export function periodSummary(records) {
  const headache = records.filter((r) => intensityOf(r) > 0);
  const acute = records.filter(hasAcute);
  return {
    registered: records.length,
    headacheDays: headache.length,
    migraineDays: records.filter((r) => r.isMigraine).length,
    auraDays: records.filter((r) => r.hasAura).length,
    clusterDays: records.filter((r) => r.hasClusterHeadache).length,
    acuteDays: acute.length,
    // effect: 1 = no effect, 2 = moderate, 3 = good (0 = not rated)
    ratedAcuteDays: acute.filter((r) => r.effect > 0).length,
    noEffectDays: acute.filter((r) => r.effect === 1).length,
    headacheOnPeriod: headache.filter((r) => r.hasPeriod).length,
  };
}

export function lastRegistration(records = []) {
  let max = null;
  for (const r of records) if (r?.date && (!max || r.date > max)) max = r.date;
  return max;
}

// HIT-6 entries may be numbers or objects – take the newest score we can find
export function latestHit6(patient) {
  const list = Array.isArray(patient?.hitSix) ? patient.hitSix : [];
  if (!list.length) return null;
  const withDate = list.map((e) =>
    typeof e === "number"
      ? { score: e, date: null }
      : { score: e?.score ?? e?.total ?? e?.value ?? e?.sum ?? null, date: e?.date ?? e?.createdAt ?? null }
  );
  withDate.sort((a, b) => String(b.date ?? "").localeCompare(String(a.date ?? "")));
  const hit = withDate.find((e) => typeof e.score === "number");
  return hit ?? null;
}

// The last `count` months (oldest first) with per-month numbers
export function monthlyOverview(patient, byDate, count = 12) {
  const now = new Date();
  const months = [];
  for (let i = count - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const y = d.getFullYear();
    const m = d.getMonth();
    const s = monthStats(byDate, y, m);
    months.push({
      year: y,
      month: m,
      score: monthScore(patient, y, m),
      levels: s.intensity, // [none, mild, moderate, strong, extreme]
      headacheDays: s.intensity[1] + s.intensity[2] + s.intensity[3] + s.intensity[4],
      migraineDays: s.migraine,
      acuteDays: s.acuteDays,
      registered: s.registered,
    });
  }
  return months;
}

// Topics for the doctor to discuss, derived only from the registrations.
// Each item: { id, titleKey, textKey, values: { n, total }, extraKey? }
export function adviceTopics(patient, byDate) {
  const topics = [];
  const last30 = periodSummary(recordsInLastDays(byDate, 30));
  const last90 = periodSummary(recordsInLastDays(byDate, 90));
  const hasPreventive = (patient?.preventiveMedicines?.length ?? 0) > 0;

  // ICHD-3: acute medication on ≥10 days/month (≥15 for simple analgesics) – flag from 10
  if (last30.acuteDays >= 10) {
    topics.push({ id: "overuse", titleKey: "ADVICE_OVERUSE_TITLE", textKey: "ADVICE_OVERUSE_TEXT", values: { n: last30.acuteDays } });
  }
  if (last30.headacheDays >= 4 && !hasPreventive) {
    topics.push({ id: "preventive", titleKey: "ADVICE_PREVENTIVE_TITLE", textKey: "ADVICE_PREVENTIVE_TEXT", values: { n: last30.headacheDays } });
  }
  if (last90.ratedAcuteDays >= 3 && last90.noEffectDays / last90.ratedAcuteDays >= 0.5) {
    topics.push({
      id: "effect",
      titleKey: "ADVICE_EFFECT_TITLE",
      textKey: "ADVICE_EFFECT_TEXT",
      values: { n: last90.noEffectDays, total: last90.ratedAcuteDays },
    });
  }
  if (last90.headacheDays >= 4 && last90.headacheOnPeriod / last90.headacheDays >= 0.5) {
    topics.push({
      id: "period",
      titleKey: "ADVICE_PERIOD_TITLE",
      textKey: "ADVICE_PERIOD_TEXT",
      values: { n: last90.headacheOnPeriod, total: last90.headacheDays },
    });
  }
  if (last90.auraDays > 0) {
    topics.push({
      id: "aura",
      titleKey: "ADVICE_AURA_TITLE",
      textKey: "ADVICE_AURA_TEXT",
      values: { n: last90.auraDays },
      extraKey: patient?.gender === "female" ? "ADVICE_AURA_FEMALE" : null,
    });
  }
  if (last90.clusterDays > 0) {
    topics.push({ id: "cluster", titleKey: "ADVICE_CLUSTER_TITLE", textKey: "ADVICE_CLUSTER_TEXT", values: { n: last90.clusterDays } });
  }

  // Rising month intensity: last full month vs. the average of the three before it
  const now = new Date();
  const score = (offset) => {
    const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
    return monthScore(patient, d.getFullYear(), d.getMonth());
  };
  const last = score(1);
  const before = [score(2), score(3), score(4)].filter((v) => typeof v === "number");
  if (typeof last === "number" && before.length === 3) {
    const avg = Math.round((before.reduce((a, b) => a + b, 0) / 3) * 10) / 10;
    if (last >= avg * 1.3 && last - avg >= 3) {
      topics.push({ id: "trend", titleKey: "ADVICE_TREND_TITLE", textKey: "ADVICE_TREND_TEXT", values: { n: last, total: avg } });
    }
  }
  return topics;
}

// Replaces {n} / {total} in a translated string
export const fill = (text = "", values = {}) =>
  Object.entries(values).reduce((s, [k, v]) => s.replaceAll(`{${k}}`, String(v)), text);

