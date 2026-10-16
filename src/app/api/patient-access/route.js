// src/app/api/patient-access/route.js
import { NextResponse } from "next/server";
import { cookies } from "next/headers";

// API_URL=https://server.headachecalendar.com  (in .env.local, no trailing slash)
const API_URL = process.env.API_URL;

export async function POST(request) {
  const { code } = await request.json().catch(() => ({}));

  if (!/^\d{6}$/.test(code ?? "")) {
    return NextResponse.json({ error: "INVALID_CODE" }, { status: 400 });
  }

  const headers = { Accept: "application/json" };
  const token = (await cookies()).get("token")?.value;
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(
      `${API_URL}/api/patients/details/json?accessCode=${encodeURIComponent(code)}`,
      { method: "GET", headers, cache: "no-store" }
    );
  } catch {
    return NextResponse.json({ error: "UPSTREAM_UNREACHABLE" }, { status: 502 });
  }

  const data = await res.json().catch(() => null);

  if (!res.ok || !data) {
    return NextResponse.json(
      { error: data?.error ?? "INVALID_CODE" },
      { status: res.ok ? 404 : res.status }
    );
  }

  return NextResponse.json({ patient: data });
}