// src/lib/adminAuth.js
// Login for /admin (server only).
//
// In .env.local / Vercel → Settings → Environment Variables:
//   ADMIN_USERNAME=...            the admin user name
//   ADMIN_PASSWORD=...            a long password
//   ADMIN_SECRET=...              random text that signs the login cookie (e.g. `openssl rand -hex 32`)
// Changing ADMIN_SECRET or ADMIN_PASSWORD logs everyone out.

import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { countLoginAttempt } from "@/lib/stats";

export const SESSION_COOKIE = "hc_admin";
const SESSION_HOURS = 12;
const MAX_ATTEMPTS = 8; // per IP per 15 minutes

// Read when used (not when the file is loaded), so they always match the server's current settings
const env = (name) => (process.env[name] ?? "").trim();
const USER = () => env("ADMIN_USERNAME");
const PASSWORD = () => env("ADMIN_PASSWORD");
const SECRET = () => env("ADMIN_SECRET") || PASSWORD();

// Names of the settings that are missing (empty when the login is set up)
export function missingSettings() {
  const missing = ["ADMIN_USERNAME", "ADMIN_PASSWORD"].filter((n) => !env(n));
  if (missing.length && process.env.NODE_ENV !== "production") {
    console.warn(`[admin] Missing ${missing.join(", ")} – looked for .env.local in ${process.cwd()}. Restart \`npm run dev\` after changing it.`);
  }
  return missing;
}

export const isConfigured = () => Boolean(USER() && PASSWORD());

// Compares two strings in constant time (hashing first makes the lengths equal)
const sameText = (a, b) =>
  timingSafeEqual(createHash("sha256").update(String(a)).digest(), createHash("sha256").update(String(b)).digest());

const sign = (value) => createHmac("sha256", `${SECRET()}|${PASSWORD()}`).update(value).digest("base64url");

export function createSessionValue() {
  const expires = Date.now() + SESSION_HOURS * 3600 * 1000;
  return `${expires}.${sign(String(expires))}`;
}

export const sessionCookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "strict",
  path: "/",
  maxAge: SESSION_HOURS * 3600,
};

export function isValidSession(value) {
  if (!isConfigured() || !value) return false;
  const [expires, mac] = String(value).split(".");
  if (!expires || !mac || Number(expires) < Date.now()) return false;
  return sameText(mac, sign(expires));
}

// For server components and route handlers
export async function isAdmin() {
  return isValidSession((await cookies()).get(SESSION_COOKIE)?.value);
}

export function checkCredentials(user, password) {
  if (!isConfigured()) return false;
  // Both are always compared, so the time taken doesn't reveal which one was wrong
  const userOk = sameText(String(user ?? "").trim(), USER());
  const passwordOk = sameText(password ?? "", PASSWORD());
  return userOk && passwordOk;
}

// Counts login attempts per IP; true when the IP has tried too many times
export async function tooManyAttempts(request) {
  try {
    return (await countLoginAttempt(request)) > MAX_ATTEMPTS;
  } catch {
    return false; // the database being down shouldn't lock the admin out
  }
}
