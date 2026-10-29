"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { usePathname } from "next/navigation";

/* ============================================================================
   کانتکست سراسری برنامه (v2.0.0 — بازنویسی از صفر)
   منبع یگانهٔ حقیقت: شرکت/سال مالی/کاربر/دسترسی‌ها
   ریشه‌کنی دو باگ گزارش‌شده:
   ① کوکی acc_ctx هرگز با رابط کاربری ناهم‌گام نمی‌ماند — هر تغییر شرکت/سال
      بلافاصله «هم سمت کلاینت» (document.cookie) و «هم سمت سرور» (POST /api/context)
      نوشته می‌شود؛ پس همهٔ APIها همیشه کانتکست درست می‌بینند.
   ② پنجره‌ها دیگر هرکدام جداگانه کوکی نمی‌خوانند و بی‌صدا شکست نمی‌خورند؛
      همه از useApp() استفاده می‌کنند و اگر کانتکست ناقص باشد پیام راهنمای
      یکدست می‌بینند (بدون خطای «شرکت و سال مالی انتخاب نشده» هنگام صدور).
   ============================================================================ */

export interface CtxUser { username: string; display: string; role: string }
export interface CtxCompany { CompanyId: number; CompanyCode: string; TitleFa: string; CodingMode: number }
export interface CtxYear { YearId: number; CompanyId: number; JalaliYear: number; Title: string; IsClosed: number | boolean }
export interface CtxCan { issue: boolean; review: boolean; finalize: boolean; reverse: boolean; master: boolean; logview: boolean; logdelete: boolean }

interface AppState {
  ready: boolean;                 /* بارگذاری اولیه تمام شد */
  user: CtxUser | null;
  can: CtxCan | null;
  companies: CtxCompany[];
  years: CtxYear[];               /* همهٔ سال‌ها (فیلتر بر اساس شرکت در UI) */
  company: CtxCompany | null;     /* شرکت جاری */
  year: CtxYear | null;           /* سال جاری */
  companyId: number;
  yearId: number;
  pickCompany: (companyId: number) => Promise<void>;
  pickYear: (yearId: number) => Promise<void>;
  reload: () => Promise<void>;
  ctxMissing: boolean;            /* شرکت/سال انتخاب نشده */
  ctxMsg: string;                 /* پیام راهنمای یکدست */
}

const Ctx = createContext<AppState | null>(null);

function writeCtxCookie(companyId: number, yearId: number) {
  /* نوشتن سمت کلاینت — decodeURIComponent در خواندن (lib/ui.readCtxCookie) هم‌خوان است */
  const val = encodeURIComponent(JSON.stringify({ companyId, yearId }));
  document.cookie = `acc_ctx=${val}; path=/; max-age=${60 * 60 * 24 * 30}; samesite=lax`;
}

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [ready, setReady] = useState(false);
  const [user, setUser] = useState<CtxUser | null>(null);
  const [can, setCan] = useState<CtxCan | null>(null);
  const [companies, setCompanies] = useState<CtxCompany[]>([]);
  const [years, setYears] = useState<CtxYear[]>([]);
  const [companyId, setCompanyId] = useState(0);
  const [yearId, setYearId] = useState(0);
  const [fatal, setFatal] = useState<string>("");
  /* v2.4.1 — ریشه‌کنی باگ «انتخاب شرکت انجام نمی‌شود»: پس از ورود با ناوبری نرم،
     AppProvider دوباره remount نمی‌شود و اگر فقط در mount فچ می‌زدیم، لیست شرکت‌ها
     هرگز پس از لاگین بارگذاری نمی‌شد. حالا با هر تغییر مسیر (به‌ویژه خروج از
     صفحهٔ ورود) کانتکست دوباره همگام می‌شود. */
  const path = usePathname();

  const load = useCallback(async () => {
    /* در صفحهٔ لاگین کانتکست لازم نیست و ریدایرکت تكراری ممنوع */
    if (typeof window !== "undefined" && window.location.pathname.startsWith("/login")) { setReady(true); return; }
    try {
      const r = await fetch("/api/context", { cache: "no-store" });
      if (r.status === 401) { location.href = "/login"; return; }
      const j = await r.json();
      if (!j.ok) { location.href = "/login"; return; }
      setUser(j.user); setCan(j.can);
      setCompanies(j.companies || []); setYears(j.years || []);
      const cur = j.current || null;
      const cId = Number(cur?.CompanyId || j.ctx?.companyId || 0);
      const yId = Number(cur?.YearId || j.ctx?.yearId || 0);
      setCompanyId(cId); setYearId(yId);
      /* اگر سرور سالی را خودکار انتخاب کرده، کوکی را همگام کن — کلاینت و سرور یکی می‌شوند */
      if (cId && yId) writeCtxCookie(cId, yId);
    } catch (err) {
      /* شبکه — دوباره تلاش در رندر بعدی؛ اما این‌بار بی‌صدا نیست:
         خطا در کنسول + پنجرهٔ دیباگ + پیام قابل مشاهده در نوار بالا ثبت می‌شود */
      console.error("[AppProvider] load() failed:", err);
      try {
        const r2 = await fetch("/api/context", { cache: "no-store" });
        const t2 = await r2.text();
        console.error("[AppProvider] retry status:", r2.status, "body:", t2.slice(0, 220));
        (window as unknown as { __ctxDebug?: string }).__ctxDebug = `status=${r2.status} body=${t2.slice(0, 220)}`;
      } catch (e2) {
        console.error("[AppProvider] retry also failed:", e2);
        (window as unknown as { __ctxDebug?: string }).__ctxDebug = `retry-failed: ${String(e2)}`;
      }
      setFatal(`بارگذاری اطلاعات پایه (شرکت‌ها/سال مالی) ناموفق بود — ${String((err as Error)?.message || err)}`);
    }
    setReady(true);
  }, []);

  useEffect(() => { load(); }, [load]);
  /* v2.4.1 — همگام‌سازی مجدد کانتکست با هر تغییر مسیر؛ در /login زود خارج می‌شود
     (بدون ریدایرکت حلقه‌ای) و به‌محض ورود به اولین پنجره، شرکت‌ها و سال‌ها می‌آیند */
  useEffect(() => {
    if (path && !path.startsWith("/login")) load();
  }, [path, load]);

  const pickCompany = useCallback(async (cId: number) => {
    /* v2.4.1 — به‌روزرسانی خوش‌بینانه: انتخاب بلافاصله در UI دیده می‌شود؛
       سال پس از تعیین خودکار در یک لحظه بعد پر می‌شود */
    setCompanyId(cId); setYearId(0);
    /* تغییر شرکت → سال صفر می‌شود؛ سپس اولین سال بازِ همان شرکت خودکار انتخاب می‌شود */
    let yId = 0;
    try {
      const j = await fetch("/api/context", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ companyId: cId, yearId: 0 }),
      }).then((r) => r.json());
      if (!j.ok) { alert(j.error || "خطا در انتخاب شرکت"); return; }
    } catch { /* ادامه — کوکی سمت کلاینت نوشته می‌شود */ }
    /* اولین سال باز شرکت تازه — همان رفتار سرور در GET */
    const cy = years.filter((y) => y.CompanyId === cId && !y.IsClosed).sort((a, b) => b.JalaliYear - a.JalaliYear)[0];
    if (cy) {
      yId = cy.YearId;
      try {
        await fetch("/api/context", {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ companyId: cId, yearId: yId }),
        });
      } catch { /* - */ }
    }
    writeCtxCookie(cId, yId);
    setCompanyId(cId); setYearId(yId);
  }, [years]);

  const pickYear = useCallback(async (yId: number) => {
    setYearId(yId); /* خوش‌بینانه */
    try {
      const j = await fetch("/api/context", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ companyId, yearId: yId }),
      }).then((r) => r.json());
      if (!j.ok) { alert(j.error || "خطا در انتخاب سال مالی"); return; }
    } catch { /* - */ }
    writeCtxCookie(companyId, yId);
    setYearId(yId);
  }, [companyId]);

  const company = useMemo(() => companies.find((c) => c.CompanyId === companyId) || null, [companies, companyId]);
  const year = useMemo(() => years.find((y) => y.YearId === yearId) || null, [years, yearId]);

  const value: AppState = {
    ready, user, can, companies, years, company, year, companyId, yearId,
    pickCompany, pickYear, reload: load,
    ctxMissing: !companyId || !yearId,
    ctxMsg: !companyId
      ? "برای شروع، از نوار بالا شرکت را انتخاب کنید."
      : !yearId
        ? "برای این شرکت سال مالی انتخاب نشده — از نوار بالا سال مالی را انتخاب کنید."
        : "",
  };
  return (
    <Ctx.Provider value={value}>
      {fatal && (
        <div className="msg err" style={{ margin: "10px 14px 0", display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
          <span>{fatal}</span>
          <button className="btn ghost" onClick={() => { setFatal(""); load(); }}>تلاش دوباره</button>
        </div>
      )}
      {children}
    </Ctx.Provider>
  );
}

export function useApp(): AppState {
  const v = useContext(Ctx);
  if (!v) throw new Error("useApp خارج از AppProvider استفاده شده است");
  return v;
}

/* نوار راهنمای «کانتکست ناقص» — یکدست در همهٔ پنجره‌ها */
export function CtxGate({ children }: { children: React.ReactNode }) {
  const app = useApp();
  if (!app.ready) return <div className="muted" style={{ padding: 24, textAlign: "center" }}>در حال بارگذاری…</div>;
  if (app.ctxMissing)
    return (
      <div className="msg err" style={{ marginTop: 12 }}>
        {app.ctxMsg}
      </div>
    );
  return <>{children}</>;
}
