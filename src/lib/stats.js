// src/lib/stats.js
// Front page visitors per language and clicks on the App Store / Google Play buttons (server only).
//
// Where the numbers are kept, in this order:
//   1. MongoDB        when MONGODB_URI is set                        (src/lib/statsMongo.js)
//   2. Upstash Redis  when KV_REST_API_URL / KV_REST_API_TOKEN are set (src/lib/statsStore.js)
//   3. Memory         otherwise – gone when the server restarts
//
// No cookies or local storage on the visitor's device: a visitor is a one-way hash of
// IP address + browser, which can't be turned back into either.

import { createHash } from "node:crypto";
import { DICTIONARIES, isSupported } from "@/lib/i18n";
import { hashToObject, hasDatabase as hasRedis, pipeline } from "@/lib/statsStore";
import { hasMongo, mongoClick, mongoLoginAttempt, mongoRaw, mongoVisit } from "@/lib/statsMongo";

export const STORES = ["appstore", "googleplay"];
export const RANGES = { 7: 7, 30: 30, 90: 90, all: null };
export const hasDatabase = hasMongo || hasRedis;

const LOCALES = Object.keys(DICTIONARIES);
const KEEP_DAYS = 400; // daily numbers are deleted after this; the all-time totals are kept
const TZ = "Europe/Oslo";
const SALT = process.env.STATS_SALT ?? process.env.ADMIN_SECRET ?? "headache-calendar";
const BOT = /bot|crawl|spider|slurp|preview|headless|lighthouse|facebookexternalhit|monitor/i;

// "2026-11-10" in Norwegian time
const dayKey = (date = new Date()) =>
  new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" }).format(date);

// The last `n` days, oldest first
function lastDays(n) {
  const [y, m, d] = dayKey().split("-").map(Number); // today in Norway, then plain calendar maths
  return Array.from({ length: n }, (_, i) => new Date(Date.UTC(y, m - 1, d - (n - 1 - i))).toISOString().slice(0, 10));
}

const clientIp = (request) =>
  (request.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || request.headers.get("x-real-ip") || "";

function visitorId(request) {
  const ua = request.headers.get("user-agent") ?? "";
  return createHash("sha256").update(`${SALT}|${clientIp(request)}|${ua}`).digest("hex").slice(0, 20);
}

export const isBot = (request) => BOT.test(request.headers.get("user-agent") ?? "") || !request.headers.get("user-agent");

const expireCmd = (key) => ["EXPIRE", key, KEEP_DAYS * 86400];
const expiresAt = () => new Date(Date.now() + KEEP_DAYS * 86400000);

// A view of the front page in `locale`. `pageView` is false when only the language was changed.
export async function recordVisit(request, locale, pageView = true) {
  if (!isSupported(locale) || isBot(request)) return;
  const id = visitorId(request);
  const d = dayKey();

  if (hasMongo) return mongoVisit({ locale, id, day: d, pageView, expiresAt: expiresAt() });

  const cmds = [
    ["PFADD", `hc:v:${locale}:${d}`, id],
    expireCmd(`hc:v:${locale}:${d}`),
    ["PFADD", `hc:v:${locale}:all`, id],
    ["PFADD", `hc:v:_:${d}`, id],
    expireCmd(`hc:v:_:${d}`),
    ["PFADD", "hc:v:_:all", id],
  ];
  if (pageView) {
    cmds.push(["HINCRBY", `hc:pv:${d}`, locale, 1], expireCmd(`hc:pv:${d}`), ["HINCRBY", "hc:pv:all", locale, 1]);
  }
  await pipeline(cmds);
}

// A click on one of the store buttons
export async function recordClick(request, locale, store) {
  if (!isSupported(locale) || !STORES.includes(store) || isBot(request)) return;
  const d = dayKey();
  const field = `${store}|${locale}`;

  if (hasMongo) return mongoClick({ field, day: d, expiresAt: expiresAt() });

  await pipeline([["HINCRBY", `hc:c:${d}`, field, 1], expireCmd(`hc:c:${d}`), ["HINCRBY", "hc:c:all", field, 1]]);
}

// Login attempts from one IP in the last 15 minutes (counts this one)
export async function countLoginAttempt(request) {
  const key = `hc:login:${createHash("sha256").update(clientIp(request) || "unknown").digest("hex").slice(0, 16)}`;
  if (hasMongo) return mongoLoginAttempt(key);
  const [count] = await pipeline([["INCR", key], ["EXPIRE", key, 15 * 60]]);
  return Number(count) || 0;
}

// The raw numbers from Redis / memory, in the same shape as mongoRaw()
async function redisRaw({ days, rangeDays }) {
  const cmds = [
    ...LOCALES.map((l) => (rangeDays ? ["PFCOUNT", ...rangeDays.map((d) => `hc:v:${l}:${d}`)] : ["PFCOUNT", `hc:v:${l}:all`])),
    rangeDays ? ["PFCOUNT", ...rangeDays.map((d) => `hc:v:_:${d}`)] : ["PFCOUNT", "hc:v:_:all"],
    ...days.flatMap((d) => [["PFCOUNT", `hc:v:_:${d}`], ["HGETALL", `hc:pv:${d}`], ["HGETALL", `hc:c:${d}`]]),
    ["HGETALL", "hc:pv:all"],
    ["HGETALL", "hc:c:all"],
  ];
  const out = await pipeline(cmds);
  let i = 0;
  const raw = { langVisitors: {}, dayVisitors: {}, dayPageViews: {}, dayClicks: {} };
  for (const l of LOCALES) raw.langVisitors[l] = Number(out[i++]) || 0;
  raw.uniqueVisitors = Number(out[i++]) || 0;
  for (const d of days) {
    raw.dayVisitors[d] = Number(out[i++]) || 0;
    raw.dayPageViews[d] = hashToObject(out[i++]);
    raw.dayClicks[d] = hashToObject(out[i++]);
  }
  raw.allPageViews = hashToObject(out[i++]);
  raw.allClicks = hashToObject(out[i++]);
  return raw;
}

const emptyRow = () => ({ visitors: 0, pageViews: 0, appstore: 0, googleplay: 0 });
const sumClicks = (clicks, store) =>
  Object.entries(clicks).reduce((n, [f, v]) => (f.startsWith(`${store}|`) ? n + (Number(v) || 0) : n), 0);

// Everything the admin page shows, for the last 7 / 30 / 90 days or all time
export async function getStats(rangeKey = "30") {
  const span = Object.hasOwn(RANGES, rangeKey) ? RANGES[rangeKey] : 30;
  const days = lastDays(span ?? 90); // "all" draws the last 90 days in the chart
  const rangeDays = span ? days : null;

  const raw = await (hasMongo ? mongoRaw : redisRaw)({ days, rangeDays });

  const rows = Object.fromEntries(LOCALES.map((l) => [l, emptyRow()]));
  for (const l of LOCALES) rows[l].visitors = Number(raw.langVisitors[l]) || 0;

  const addPageViews = (hash) => {
    for (const [l, n] of Object.entries(hash)) if (rows[l]) rows[l].pageViews += Number(n) || 0;
  };
  const addClicks = (hash) => {
    for (const [field, n] of Object.entries(hash)) {
      const [store, l] = field.split("|");
      if (rows[l] && STORES.includes(store)) rows[l][store] += Number(n) || 0;
    }
  };

  if (rangeDays) {
    for (const d of rangeDays) {
      addPageViews(raw.dayPageViews[d] ?? {});
      addClicks(raw.dayClicks[d] ?? {});
    }
  } else {
    addPageViews(raw.allPageViews);
    addClicks(raw.allClicks);
  }

  const daily = days.map((date) => {
    const pv = raw.dayPageViews[date] ?? {};
    const clicks = raw.dayClicks[date] ?? {};
    return {
      date,
      visitors: Number(raw.dayVisitors[date]) || 0,
      pageViews: Object.values(pv).reduce((a, b) => a + (Number(b) || 0), 0),
      appstore: sumClicks(clicks, "appstore"),
      googleplay: sumClicks(clicks, "googleplay"),
    };
  });

  const languages = LOCALES.map((locale) => ({ locale, ...rows[locale] }));
  const totals = languages.reduce(
    (t, r) => ({ pageViews: t.pageViews + r.pageViews, appstore: t.appstore + r.appstore, googleplay: t.googleplay + r.googleplay }),
    { pageViews: 0, appstore: 0, googleplay: 0 }
  );

  return {
    range: span ? String(span) : "all",
    database: hasDatabase,
    totals: { visitors: Number(raw.uniqueVisitors) || 0, ...totals },
    languages,
    daily,
  };
}
