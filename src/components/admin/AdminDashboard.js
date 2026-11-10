// src/components/admin/AdminDashboard.js
"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useLocale } from "@/components/LocaleProvider";
import LanguagePicker from "@/components/landing/LanguagePicker";
import { AppleLogo, GooglePlayLogo } from "@/components/landing/StoreLinks";
import { EyeIcon, LockIcon, LogoutIcon, RefreshIcon, UsersIcon } from "@/components/admin/adminIcons";
import { LANGUAGES } from "@/lib/i18n";

const RANGES = [
  { key: "7", label: "ADMIN_RANGE_7" },
  { key: "30", label: "ADMIN_RANGE_30" },
  { key: "90", label: "ADMIN_RANGE_90" },
  { key: "all", label: "ADMIN_RANGE_ALL" },
];

// Colours used across tiles, chart and table
const C = { visitors: "#9dbdee", apple: "#2c4a6e", google: "#5cb87e" };

const CARD =
  "rounded-3xl border border-white/80 bg-white/90 shadow-[0_14px_34px_-18px_rgba(40,80,150,0.55)] backdrop-blur";
const LABEL = "text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]";

const fill = (text = "", values = {}) =>
  Object.entries(values).reduce((s, [k, v]) => s.replaceAll(`{${k}}`, String(v)), text);

function Tile({ icon, iconBg, label, value, sub }) {
  return (
    <section className={`${CARD} p-4 sm:p-5`}>
      <div className="flex flex-wrap items-center gap-2 sm:gap-3">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl text-white shadow-sm" style={{ background: iconBg }}>
          {icon}
        </span>
        <span className={LABEL}>{label}</span>
      </div>
      <p className="mt-3 text-3xl font-semibold sm:mt-4 sm:text-4xl tabular-nums tracking-tight text-slate-800">{value}</p>
      <p className="mt-1 min-h-5 text-sm text-slate-500">{sub}</p>
    </section>
  );
}

function Legend({ color, children }) {
  return (
    <span className="inline-flex items-center gap-1.5 text-xs text-slate-600">
      <span className="h-2.5 w-2.5 rounded-sm" style={{ background: color }} />
      {children}
    </span>
  );
}

// Bars per day: visitors behind, store clicks stacked in front
function DailyChart({ daily, t, num, dayFmt }) {
  const [hover, setHover] = useState(null);
  const max = Math.max(1, ...daily.map((d) => Math.max(d.visitors, d.appstore + d.googleplay)));
  const ticks = [0, Math.floor((daily.length - 1) / 2), daily.length - 1];
  const shown = hover != null ? daily[hover] : null;

  return (
    <section className={`${CARD} p-5`}>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className={LABEL}>{t.ADMIN_PER_DAY}</h2>
        <div className="flex flex-wrap gap-4">
          <Legend color={C.visitors}>{t.ADMIN_VISITORS}</Legend>
          <Legend color={C.apple}>App Store</Legend>
          <Legend color={C.google}>Google Play</Legend>
        </div>
      </div>

      {/* Details for the day under the pointer */}
      <div className="mt-3 h-6 text-sm text-slate-600" aria-live="polite">
        {shown && (
          <span className="tabular-nums">
            <span className="font-semibold text-slate-800">{dayFmt.format(new Date(`${shown.date}T12:00:00`))}</span>
            {" · "}
            {t.ADMIN_VISITORS} {num(shown.visitors)} · App Store {num(shown.appstore)} · Google Play {num(shown.googleplay)}
          </span>
        )}
      </div>

      <div className="relative mt-2 h-48" dir="ltr" onMouseLeave={() => setHover(null)}>
        {/* Grid lines */}
        {[0.25, 0.5, 0.75, 1].map((f) => (
          <div key={f} className="absolute inset-x-0 border-t border-dashed border-slate-200" style={{ bottom: `${f * 100}%` }}>
            <span className="absolute -top-2.5 end-0 bg-white/80 px-1 text-[10px] tabular-nums text-slate-400">{num(Math.round(max * f))}</span>
          </div>
        ))}
        <div className="absolute inset-0 flex items-end gap-[2px] pe-8">
          {daily.map((d, i) => {
            const clicks = d.appstore + d.googleplay;
            return (
              <div
                key={d.date}
                onMouseEnter={() => setHover(i)}
                className={`relative flex h-full flex-1 items-end justify-center rounded-t-md transition ${hover === i ? "bg-[#6a9be0]/10" : ""}`}
              >
                <div className="w-full rounded-t-[4px]" style={{ height: `${(d.visitors / max) * 100}%`, background: C.visitors }} />
                {clicks > 0 && (
                  <div className="absolute bottom-0 flex w-1/2 flex-col overflow-hidden rounded-t-[3px]" style={{ height: `${(clicks / max) * 100}%` }}>
                    <div style={{ flex: d.googleplay, background: C.google }} />
                    <div style={{ flex: d.appstore, background: C.apple }} />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
      <div className="mt-2 flex justify-between pe-8 text-[11px] text-slate-400" dir="ltr">
        {ticks.map((i) => (
          <span key={i}>{daily[i] && dayFmt.format(new Date(`${daily[i].date}T12:00:00`))}</span>
        ))}
      </div>
    </section>
  );
}

function LanguageTable({ rows, totals, t, num, pct }) {
  const [showAll, setShowAll] = useState(false);
  const names = useMemo(() => Object.fromEntries(LANGUAGES.map((l) => [l.code, l])), []);
  const used = rows.filter((r) => r.visitors || r.pageViews || r.appstore || r.googleplay);
  const list = (showAll ? rows : used).toSorted(
    (a, b) => b.visitors - a.visitors || b.appstore + b.googleplay - (a.appstore + a.googleplay) || a.locale.localeCompare(b.locale)
  );
  const maxVisitors = Math.max(1, ...rows.map((r) => r.visitors));
  const sumVisitors = rows.reduce((n, r) => n + r.visitors, 0);
  const th = "px-3 py-3 text-end text-[11px] font-bold uppercase tracking-[0.12em] text-slate-500";
  const td = "px-3 py-3 text-end tabular-nums text-slate-700";

  return (
    <section className={`${CARD} overflow-hidden`}>
      <div className="flex flex-wrap items-center justify-between gap-3 px-5 pt-5">
        <h2 className={LABEL}>{t.ADMIN_PER_LANGUAGE}</h2>
        <button
          type="button"
          onClick={() => setShowAll((v) => !v)}
          className="rounded-full border border-[#6a9be0]/40 bg-white px-3 py-1 text-xs font-semibold text-[#4f7cc0] transition hover:bg-[#eef4fd]"
        >
          {showAll ? t.ADMIN_SHOW_USED : t.ADMIN_SHOW_ALL}
        </button>
      </div>

      {list.length === 0 ? (
        <p className="px-5 py-10 text-center text-sm italic text-slate-400">{t.ADMIN_NO_DATA}</p>
      ) : (
        <div className="mt-3 overflow-x-auto">
          <table className="w-full min-w-[40rem] text-sm">
            <thead className="border-y border-slate-100 bg-slate-50/70">
              <tr>
                <th className={`${th} text-start`}>{t.ADMIN_LANGUAGE}</th>
                <th className={`${th} w-[30%]`}>{t.ADMIN_VISITORS}</th>
                <th className={th}>{t.ADMIN_PAGE_VIEWS}</th>
                <th className={th}>App Store</th>
                <th className={th}>Google Play</th>
                <th className={th}>{t.ADMIN_CLICK_RATE}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {list.map((r) => {
                const lang = names[r.locale];
                const clicks = r.appstore + r.googleplay;
                return (
                  <tr key={r.locale} className="transition hover:bg-[#eef4fd]/60">
                    <td className="px-3 py-3">
                      <span className="flex items-center gap-2.5">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#eef4fd] text-base">
                          {lang?.flag || r.locale.slice(0, 2).toUpperCase()}
                        </span>
                        <span className="min-w-0">
                          <span className="block truncate font-medium text-slate-800">{lang?.name ?? r.locale}</span>
                          <span className="block text-xs text-slate-400" dir="ltr">{r.locale}</span>
                        </span>
                      </span>
                    </td>
                    <td className={td}>
                      <span className="flex items-center justify-end gap-3">
                        <span className="hidden h-2 flex-1 overflow-hidden rounded-full bg-slate-100 sm:block">
                          <span className="block h-full rounded-full bg-[#6a9be0]" style={{ width: `${(r.visitors / maxVisitors) * 100}%` }} />
                        </span>
                        <span className="w-12 font-semibold text-slate-800">{num(r.visitors)}</span>
                        <span className="w-12 text-xs text-slate-400">{sumVisitors ? pct(r.visitors / sumVisitors) : "–"}</span>
                      </span>
                    </td>
                    <td className={td}>{num(r.pageViews)}</td>
                    <td className={td}>{num(r.appstore)}</td>
                    <td className={td}>{num(r.googleplay)}</td>
                    <td className={td}>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${clicks ? "bg-[#e7f5ec] text-[#2f7d4b]" : "text-slate-400"}`}>
                        {r.visitors ? pct(clicks / r.visitors) : "–"}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
            <tfoot className="border-t-2 border-slate-100 bg-slate-50/70 font-semibold">
              <tr>
                <td className="px-3 py-3 text-slate-800">{t.ADMIN_TOTAL}</td>
                <td className={`${td} font-semibold text-slate-800`}>{num(totals.visitors)}</td>
                <td className={td}>{num(totals.pageViews)}</td>
                <td className={td}>{num(totals.appstore)}</td>
                <td className={td}>{num(totals.googleplay)}</td>
                <td className={td}>{totals.visitors ? pct((totals.appstore + totals.googleplay) / totals.visitors) : "–"}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}
      <p className="px-5 pb-5 pt-3 text-xs leading-relaxed text-slate-500">{t.ADMIN_PRIVACY_NOTE}</p>
    </section>
  );
}

export default function AdminDashboard() {
  const router = useRouter();
  const { t, locale } = useLocale();
  const [range, setRange] = useState("30");
  const [data, setData] = useState(null);
  const [error, setError] = useState(false);
  const [loading, setLoading] = useState(true);

  const num = useMemo(() => {
    const f = new Intl.NumberFormat(locale);
    return (n) => f.format(n ?? 0);
  }, [locale]);
  const pct = useMemo(() => {
    const f = new Intl.NumberFormat(locale, { style: "percent", maximumFractionDigits: 1 });
    return (n) => f.format(n || 0);
  }, [locale]);
  const dayFmt = useMemo(() => new Intl.DateTimeFormat(locale, { day: "numeric", month: "short" }), [locale]);

  const load = useCallback(async (r) => {
    setLoading(true);
    setError(false);
    try {
      const res = await fetch(`/api/admin/stats?range=${r}`, { cache: "no-store" });
      if (res.status === 401) {
        router.refresh(); // session ended → back to the login
        return;
      }
      if (!res.ok) throw new Error();
      setData(await res.json());
    } catch {
      setError(true);
    }
    setLoading(false);
  }, [router]);

  useEffect(() => {
    load(range);
  }, [load, range]);

  const logout = async () => {
    await fetch("/api/admin/logout", { method: "POST" }).catch(() => {});
    router.refresh();
  };

  const totals = data?.totals;
  const share = (n) => (totals?.visitors ? fill(t.ADMIN_OF_VISITORS, { n: pct(n / totals.visitors) }) : "");

  return (
    <div className="min-h-screen pb-16">
      {/* Top bar, like the patient dashboard */}
      <header className="sticky top-0 z-30 border-b border-white/70 bg-white/80 backdrop-blur">
        <div className="flex w-full items-center justify-between gap-3 px-4 py-3 sm:grid sm:grid-cols-[1fr_auto_1fr] sm:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#8db3ea] text-white">
              <LockIcon className="h-4 w-4" />
            </span>
            <p className="truncate text-sm font-semibold text-slate-700">{t.ADMIN_TITLE}</p>
          </div>
          <h1 className="hidden font-serif text-2xl font-bold text-[#4f7cc0] sm:block">{t.HEADACHE_DIARY}</h1>
          <div className="flex items-center justify-end gap-2">
            <div className="hidden md:block">
              <LanguagePicker />
            </div>
            <button
              type="button"
              onClick={logout}
              className="inline-flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full bg-[#6a9be0] px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-[#5b8bd3]"
            >
              <LogoutIcon className="h-4 w-4 rtl:rotate-180" />
              {t.ADMIN_LOGOUT}
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto mt-6 max-w-6xl space-y-6 px-4">
        {/* Period */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div role="tablist" className="inline-flex rounded-full border border-white/70 bg-white/70 p-1 shadow-sm backdrop-blur">
            {RANGES.map((r) => (
              <button
                key={r.key}
                type="button"
                role="tab"
                aria-selected={range === r.key}
                onClick={() => setRange(r.key)}
                className={`whitespace-nowrap rounded-full px-3 py-1.5 text-sm font-semibold transition sm:px-4 ${
                  range === r.key ? "bg-[#6a9be0] text-white shadow-sm" : "text-[#4f7cc0] hover:bg-white"
                }`}
              >
                {t[r.label]}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={() => load(range)}
            disabled={loading}
            className="inline-flex items-center gap-1.5 rounded-full border border-white/70 bg-white/70 px-4 py-2 text-sm font-semibold text-[#4f7cc0] shadow-sm backdrop-blur transition hover:bg-white disabled:opacity-60"
          >
            <RefreshIcon className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            {t.ADMIN_REFRESH}
          </button>
        </div>

        {data && !data.database && (
          <p className="rounded-2xl border border-amber-200 bg-amber-50/90 px-4 py-3 text-sm text-amber-800">{t.ADMIN_NO_DATABASE}</p>
        )}
        {error && <p className="rounded-2xl border border-red-200 bg-red-50/90 px-4 py-3 text-sm text-red-700">{t.ADMIN_LOAD_ERROR}</p>}

        {data && (
          <div className={`space-y-6 transition-opacity ${loading ? "opacity-60" : ""}`}>
            <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
              <Tile icon={<UsersIcon />} iconBg="#6a9be0" label={t.ADMIN_VISITORS} value={num(totals.visitors)} />
              <Tile icon={<EyeIcon />} iconBg="#8db3ea" label={t.ADMIN_PAGE_VIEWS} value={num(totals.pageViews)} />
              <Tile icon={<AppleLogo className="h-5 w-5" />} iconBg={C.apple} label="App Store" value={num(totals.appstore)} sub={share(totals.appstore)} />
              <Tile
                icon={<span className="flex h-7 w-7 items-center justify-center rounded-lg bg-white"><GooglePlayLogo className="h-4 w-4" /></span>}
                iconBg={C.google}
                label="Google Play"
                value={num(totals.googleplay)}
                sub={share(totals.googleplay)}
              />
            </div>

            <DailyChart daily={data.daily} t={t} num={num} dayFmt={dayFmt} />
            <LanguageTable rows={data.languages} totals={totals} t={t} num={num} pct={pct} />
          </div>
        )}
      </main>
    </div>
  );
}
