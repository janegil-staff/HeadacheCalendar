// src/lib/track.js
// Sends a count to /api/track without slowing the page down (browser only)
export function track(data) {
  const body = JSON.stringify(data);
  try {
    // sendBeacon survives the page being left, e.g. right after a click on a store button
    if (navigator.sendBeacon?.("/api/track", new Blob([body], { type: "text/plain" }))) return;
  } catch {}
  fetch("/api/track", { method: "POST", body, keepalive: true }).catch(() => {});
}
