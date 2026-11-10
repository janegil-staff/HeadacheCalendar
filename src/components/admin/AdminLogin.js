// src/components/admin/AdminLogin.js
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useLocale } from "@/components/LocaleProvider";
import LanguagePicker from "@/components/landing/LanguagePicker";
import { LockIcon } from "@/components/admin/adminIcons";

const ERRORS = { WRONG_LOGIN: "ADMIN_LOGIN_ERROR", LOCKED: "ADMIN_LOGIN_LOCKED", NOT_CONFIGURED: "ADMIN_NOT_CONFIGURED" };

const INPUT =
  "mt-1.5 w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-start text-gray-900 placeholder:text-gray-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-200 disabled:opacity-60";

export default function AdminLogin({ configured, missing = [], cwd = null }) {
  const router = useRouter();
  const { t } = useLocale();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [errorKey, setErrorKey] = useState(configured ? "" : "ADMIN_NOT_CONFIGURED");
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setErrorKey("");
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      if (res.ok) {
        router.refresh(); // the page now renders the dashboard
        return;
      }
      const data = await res.json().catch(() => ({}));
      setErrorKey(ERRORS[data.error] ?? "ADMIN_LOGIN_ERROR");
      setPassword("");
    } catch {
      setErrorKey("ERROR_NETWORK");
    }
    setBusy(false);
  };

  return (
    <main className="relative flex min-h-screen items-center justify-center px-4 py-20">
      <div className="absolute end-4 top-4 sm:end-6 sm:top-6">
        <LanguagePicker />
      </div>

      <div className="w-full max-w-sm">
        <h1 className="text-center font-serif text-3xl font-bold text-blue-800 sm:text-4xl">{t.HEADACHE_DIARY}</h1>

        <form
          onSubmit={submit}
          className="mt-8 rounded-3xl border border-white/70 bg-white/80 p-6 shadow-[0_18px_40px_-20px_rgba(40,80,150,0.55)] backdrop-blur"
        >
          <div className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-[#6a9be0] text-white shadow-sm">
              <LockIcon />
            </span>
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.15em] text-gray-900">{t.ADMIN_TITLE}</p>
              <p className="text-sm text-slate-500">{t.ADMIN_LOGIN_INTRO}</p>
            </div>
          </div>

          <label className="mt-6 block text-sm font-medium text-slate-700">
            {t.ADMIN_USERNAME}
            <input
              type="text"
              name="username"
              autoComplete="username"
              autoFocus
              required
              dir="ltr"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              disabled={busy}
              className={INPUT}
            />
          </label>

          <label className="mt-4 block text-sm font-medium text-slate-700">
            {t.ADMIN_PASSWORD}
            <input
              type="password"
              name="password"
              autoComplete="current-password"
              required
              dir="ltr"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={busy}
              className={INPUT}
            />
          </label>

          {errorKey && (
            <p role="alert" className="mt-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
              {t[errorKey]}
            </p>
          )}
          {/* Development only: which settings the server can't see, and where it looks for .env.local */}
          {missing.length > 0 && (
            <pre dir="ltr" className="mt-2 overflow-x-auto whitespace-pre-wrap rounded-lg bg-slate-900 px-3 py-2 text-left text-xs leading-relaxed text-slate-100">
              {missing.map((m) => `${m}=…`).join("\n")}
              {cwd ? `\n\n.env.local → ${cwd}` : ""}
            </pre>
          )}

          <button
            type="submit"
            disabled={busy}
            className="mt-5 w-full rounded-lg bg-blue-700 py-3 text-sm font-semibold uppercase tracking-[0.2em] text-white transition hover:bg-blue-800 disabled:bg-blue-400"
          >
            {busy ? t.COMMON_LOADING : t.ADMIN_LOGIN}
          </button>
        </form>
      </div>
    </main>
  );
}
