// src/lib/statsMongo.js
// MongoDB storage for the admin numbers (server only). Used when MONGODB_URI is set.
//
//   MONGODB_URI=mongodb+srv://user:password@cluster0.xxxxx.mongodb.net
//   MONGODB_DB=headache-calendar        (optional – this is the default)
//
// Collections (created automatically, old rows removed by TTL indexes):
//   stats_visitors  one row per visitor (hashed) per day per language, plus day "all"
//   stats_daily     page views and store clicks per day (_id = "2026-11-10"), plus _id "all"
//   admin_logins    login attempts per IP, for the 15-minute lock

import { MongoClient } from "mongodb";

const URI = process.env.MONGODB_URI;
const DB_NAME = process.env.MONGODB_DB || "headache-calendar";

export const hasMongo = Boolean(URI);

const g = globalThis;

// One shared connection, also across hot reloads in development
async function getDb() {
  if (!g.__hcMongoClient) {
    g.__hcMongoClient = new MongoClient(URI, { maxPoolSize: 5 }).connect().catch((err) => {
      g.__hcMongoClient = null; // try again on the next request
      throw err;
    });
  }
  const db = (await g.__hcMongoClient).db(DB_NAME);
  if (!g.__hcMongoIndexes) {
    g.__hcMongoIndexes = Promise.all([
      db.collection("stats_visitors").createIndex({ day: 1, locale: 1, v: 1 }, { unique: true }),
      db.collection("stats_visitors").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
      db.collection("stats_daily").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
      db.collection("admin_logins").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }),
    ]).catch((err) => {
      g.__hcMongoIndexes = null;
      throw err;
    });
  }
  await g.__hcMongoIndexes;
  return db;
}

// Two visits at the same moment may both try to insert the same row – that's fine
const ignoreDuplicates = (err) => {
  const codes = [err?.code, ...(err?.writeErrors ?? []).map((e) => e.code ?? e.err?.code)];
  if (!codes.every((c) => c === 11000)) throw err;
};

export async function mongoVisit({ locale, id, day, pageView, expiresAt }) {
  const db = await getDb();
  const writes = [
    db
      .collection("stats_visitors")
      .bulkWrite(
        [
          { updateOne: { filter: { day, locale, v: id }, update: { $setOnInsert: { expiresAt } }, upsert: true } },
          { updateOne: { filter: { day: "all", locale, v: id }, update: { $setOnInsert: { since: new Date() } }, upsert: true } },
        ],
        { ordered: false }
      )
      .catch(ignoreDuplicates),
  ];
  if (pageView) {
    writes.push(
      db.collection("stats_daily").bulkWrite([
        { updateOne: { filter: { _id: day }, update: { $inc: { [`pv.${locale}`]: 1 }, $setOnInsert: { expiresAt } }, upsert: true } },
        { updateOne: { filter: { _id: "all" }, update: { $inc: { [`pv.${locale}`]: 1 } }, upsert: true } },
      ])
    );
  }
  await Promise.all(writes);
}

export async function mongoClick({ field, day, expiresAt }) {
  const db = await getDb();
  await db.collection("stats_daily").bulkWrite([
    { updateOne: { filter: { _id: day }, update: { $inc: { [`clicks.${field}`]: 1 }, $setOnInsert: { expiresAt } }, upsert: true } },
    { updateOne: { filter: { _id: "all" }, update: { $inc: { [`clicks.${field}`]: 1 } }, upsert: true } },
  ]);
}

// The raw numbers getStats() needs, in the same shape as the Redis version
export async function mongoRaw({ days, rangeDays }) {
  const db = await getDb();
  const visitors = db.collection("stats_visitors");
  const rangeMatch = { day: rangeDays ? { $in: rangeDays } : "all" };

  const [perLocale, unique, perDay, dailyDocs] = await Promise.all([
    visitors
      .aggregate([
        { $match: rangeMatch },
        { $group: { _id: { l: "$locale", v: "$v" } } },
        { $group: { _id: "$_id.l", n: { $sum: 1 } } },
      ])
      .toArray(),
    visitors.aggregate([{ $match: rangeMatch }, { $group: { _id: "$v" } }, { $count: "n" }]).toArray(),
    visitors
      .aggregate([
        { $match: { day: { $in: days } } },
        { $group: { _id: { d: "$day", v: "$v" } } },
        { $group: { _id: "$_id.d", n: { $sum: 1 } } },
      ])
      .toArray(),
    db.collection("stats_daily").find({ _id: { $in: [...days, "all"] } }).toArray(),
  ]);

  const byId = Object.fromEntries(dailyDocs.map((d) => [d._id, d]));
  return {
    langVisitors: Object.fromEntries(perLocale.map((r) => [r._id, r.n])),
    uniqueVisitors: unique[0]?.n ?? 0,
    dayVisitors: Object.fromEntries(perDay.map((r) => [r._id, r.n])),
    dayPageViews: Object.fromEntries(days.map((d) => [d, byId[d]?.pv ?? {}])),
    dayClicks: Object.fromEntries(days.map((d) => [d, byId[d]?.clicks ?? {}])),
    allPageViews: byId.all?.pv ?? {},
    allClicks: byId.all?.clicks ?? {},
  };
}

// Counts a login attempt for `key`; returns how many there have been in the last 15 minutes
export async function mongoLoginAttempt(key) {
  const db = await getDb();
  const res = await db.collection("admin_logins").findOneAndUpdate(
    { _id: key },
    { $inc: { n: 1 }, $setOnInsert: { expiresAt: new Date(Date.now() + 15 * 60 * 1000) } },
    { upsert: true, returnDocument: "after" }
  );
  return (res?.value ?? res)?.n ?? 1; // driver 6 returns the document, older drivers { value }
}
