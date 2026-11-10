// src/app/api/track/route.js
// Counts front page visits per language and clicks on the store buttons (see src/lib/stats.js)
import { NextResponse } from "next/server";
import { recordClick, recordVisit } from "@/lib/stats";

export async function POST(request) {
  // sendBeacon sends text/plain, fetch sends JSON – read the body as text either way
  let body = {};
  try {
    body = JSON.parse(await request.text());
  } catch {}

  try {
    if (body.type === "visit") await recordVisit(request, body.locale, body.pageView !== false);
    else if (body.type === "click") await recordClick(request, body.locale, body.store);
  } catch {
    // Counting must never break the site
  }
  return new NextResponse(null, { status: 204 });
}
