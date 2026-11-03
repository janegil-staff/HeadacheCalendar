// src/app/api/patient-access/route.js
import { NextResponse } from "next/server";
import { cookies } from "next/headers";

// API_URL=https://server.headachecalendar.com  (in .env.local, no trailing slash)
const API_URL = process.env.API_URL;
// If the code doesn't work on the main server, it is tried here.
// Override with API_URL_FALLBACK in .env.local, or set it to "" to turn the fallback off.
const FALLBACK_URL = process.env.API_URL_FALLBACK ?? "https://test.headachecalendar.com";

// Looks the code up on one server: { patient } on success, otherwise { status, error }
async function lookup(baseUrl, code, token) {
  const headers = { Accept: "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(`${baseUrl}/api/patients/details/json?accessCode=${encodeURIComponent(code)}`, {
      method: "GET",
      headers,
      cache: "no-store",
    });
  } catch {
    return { status: 502, error: "UPSTREAM_UNREACHABLE" };
  }

  const data = await res.json().catch(() => null);
  if (res.ok && data) return { patient: data };
  return { status: res.ok ? 404 : res.status, error: data?.error ?? "INVALID_CODE" };
}

export async function POST(request) {
  const { code } = await request.json().catch(() => ({}));

  if (!/^\d{6}$/.test(code ?? "")) {
    return NextResponse.json({ error: "INVALID_CODE" }, { status: 400 });
  }

  const token = (await cookies()).get("token")?.value;

  const main = await lookup(API_URL, code, token);
  if (main.patient) return NextResponse.json({ patient: main.patient });

  // Fallback to the test server. The login cookie belongs to the main server, so it isn't sent.
  if (FALLBACK_URL && FALLBACK_URL !== API_URL) {
    const test = await lookup(FALLBACK_URL, code, null);
    if (test.patient) return NextResponse.json({ patient: test.patient, server: "test" });

    // Neither worked: show "expired" if either server said so, otherwise the main server's answer
    const expired = [main, test].find((r) => r.status === 410);
    const failure = expired ?? main;
    return NextResponse.json({ error: failure.error }, { status: failure.status });
  }

  return NextResponse.json({ error: main.error }, { status: main.status });
}
