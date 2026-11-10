// src/lib/statsStore.js
// Storage for the admin numbers (server only).
//
// Uses Upstash Redis over its REST API – no npm package needed. On Vercel: Storage →
// Marketplace → "Upstash for Redis", connect it to the project, and it sets
// KV_REST_API_URL / KV_REST_API_TOKEN (UPSTASH_REDIS_REST_URL / _TOKEN also work).
// Without them (e.g. local dev) everything is kept in memory until the server restarts.

const URL = process.env.KV_REST_API_URL ?? process.env.UPSTASH_REDIS_REST_URL;
const TOKEN = process.env.KV_REST_API_TOKEN ?? process.env.UPSTASH_REDIS_REST_TOKEN;

export const hasDatabase = Boolean(URL && TOKEN);

// ---------- Tiny in-memory stand-in with the few commands used here ----------

const mem = (globalThis.__headacheStatsMemory ??= new Map());

function runMemory([cmd, key, ...args]) {
  switch (cmd) {
    case "PFADD": {
      const set = mem.get(key) ?? new Set();
      const before = set.size;
      args.forEach((a) => set.add(a));
      mem.set(key, set);
      return set.size > before ? 1 : 0;
    }
    case "PFCOUNT": {
      const union = new Set();
      for (const k of [key, ...args]) (mem.get(k) ?? new Set()).forEach((v) => union.add(v));
      return union.size;
    }
    case "HINCRBY": {
      const hash = mem.get(key) ?? {};
      hash[args[0]] = (hash[args[0]] ?? 0) + Number(args[1]);
      mem.set(key, hash);
      return hash[args[0]];
    }
    case "HGETALL": {
      const hash = mem.get(key) ?? {};
      return Object.entries(hash).flatMap(([f, v]) => [f, String(v)]);
    }
    case "INCR": {
      const n = (mem.get(key) ?? 0) + 1;
      mem.set(key, n);
      return n;
    }
    case "DEL":
      return mem.delete(key) ? 1 : 0;
    case "EXPIRE":
      return 1; // memory is gone on restart anyway
    default:
      throw new Error(`Unsupported command ${cmd}`);
  }
}

// Runs several commands in one round trip; returns their results in order
export async function pipeline(commands) {
  if (!commands.length) return [];
  if (!hasDatabase) return commands.map(runMemory);

  const res = await fetch(`${URL.replace(/\/$/, "")}/pipeline`, {
    method: "POST",
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify(commands.map((c) => c.map(String))),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`Redis ${res.status}`);
  const out = await res.json();
  return out.map((r) => {
    if (r.error) throw new Error(r.error);
    return r.result;
  });
}

// ["a", "1", "b", "2"] → { a: 1, b: 2 }
export const hashToObject = (list) => {
  const o = {};
  for (let i = 0; i < (list?.length ?? 0); i += 2) o[list[i]] = Number(list[i + 1]) || 0;
  return o;
};
