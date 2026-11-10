// src/app/api/admin/stats/route.js
import { NextResponse } from "next/server";
import { isAdmin } from "@/lib/adminAuth";
import { getStats } from "@/lib/stats";

export async function GET(request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "UNAUTHORIZED" }, { status: 401 });

  const range = new URL(request.url).searchParams.get("range") ?? "30";
  try {
    return NextResponse.json(await getStats(range), { headers: { "Cache-Control": "no-store" } });
  } catch {
    return NextResponse.json({ error: "LOAD_FAILED" }, { status: 502 });
  }
}
