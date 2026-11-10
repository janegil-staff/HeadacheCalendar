// src/app/api/admin/login/route.js
import { NextResponse } from "next/server";
import {
  SESSION_COOKIE,
  checkCredentials,
  createSessionValue,
  isConfigured,
  sessionCookieOptions,
  tooManyAttempts,
} from "@/lib/adminAuth";

export async function POST(request) {
  if (!isConfigured()) return NextResponse.json({ error: "NOT_CONFIGURED" }, { status: 503 });
  if (await tooManyAttempts(request)) return NextResponse.json({ error: "LOCKED" }, { status: 429 });

  const { username, password } = await request.json().catch(() => ({}));
  if (!checkCredentials(username, password)) {
    return NextResponse.json({ error: "WRONG_LOGIN" }, { status: 401 });
  }

  const res = NextResponse.json({ ok: true });
  res.cookies.set(SESSION_COOKIE, createSessionValue(), sessionCookieOptions);
  return res;
}
