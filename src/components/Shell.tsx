"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useApp } from "@/components/App";

/* ============================================================================
   پوستهٔ برنامه (v2.0.0) — منوی اصلی + نوار کانتکست + قاب پنجره
   منبع شرکت/سال: AppContext سراسری (نه کوکی محلی هر پنجره)
   ============================================================================ */

/* v2.4.4 — هندسهٔ پنجره: حداقل اندازه و کلید ذخیره‌سازی به‌ازای هر مسیر */
type Geom = { w: number; h: number };
const MIN_W = 560, MIN_H = 480; /* MIN_H هم‌تراز با min-height:480px در CSS — تا اندازهٔ ذخیره‌شده با نمایش یکی باشد */
const geomKey = (p: string) => `acc-win-geom:${p}`;

export default function Shell({ children, title, sub }: { children: React.ReactNode; title: string; sub?: string }) {
  const app = useApp();
  const [open, setOpen] = useState<string | null>(null);
  const path = usePathname();
  const router = useRouter();
  const ref = useRef<HTMLDivElement>(null);
  /* v2.2.0 — پنجرهٔ تمام‌صفحه یا پنجره‌ای قابل تغییر اندازه (درخواست: پنجره‌ها کل صفحه را پر کنند و قابل بزرگ/کوچک شوند) */
  const [big, setBig] = useState(true);
  /* v2.4.4 — تغییر اندازهٔ پنجره با موس (دستگیرهٔ لبهٔ پایین و گوشه‌ها) + همگام‌سازی خودکار هندسه:
     اندازهٔ هر پنجره به‌ازای مسیرش در localStorage ذخیره می‌شود؛ هنگام باز شدن دوبارهٔ همان
     پنجره (حتی در جلسهٔ بعد یا تب دیگر) به‌طور خودکار بازیابی و همگام می‌گردد. */
  const [geom, setGeom] = useState<Geom | null>(null);
  const winRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    try {
      const v = localStorage.getItem("acc-win-size"); if (v === "win") setBig(false);
      const g = localStorage.getItem(geomKey(path || ""));
      setGeom(g ? JSON.parse(g) : null);
    } catch { /* - */ }
  }, [path]);

  /* همگام‌سازی خودکار بین تب‌ها — تغییر اندازه در یک تب، بقیهٔ تب‌ها را هم زنده به‌روز می‌کند */
  useEffect(() => {
    const h = (e: StorageEvent) => {
      if (e.key === geomKey(path || "") && e.newValue) { try { setGeom(JSON.parse(e.newValue)); } catch { /* - */ } }
      else if (e.key === "acc-win-size" && e.newValue) setBig(e.newValue !== "win");
    };
    window.addEventListener("storage", h);
    return () => window.removeEventListener("storage", h);
  }, [path]);

  const persistGeom = (g: Geom) => {
    try {
      localStorage.setItem(geomKey(path || ""), JSON.stringify(g));
      localStorage.setItem("acc-win-size", "win");
    } catch { /* - */ }
  };

  /* شروع درگ دستگیره‌ها — نقطهٔ شروع: مستطیل فعلی پنجره؛ در حالت تمام‌صفحه اولین درگ یعنی رفتن به حالت پنجره‌ای با همان اندازه */
  const startResize = (side: "s" | "se" | "sw") => (e: React.PointerEvent) => {
    e.preventDefault();
    const el = winRef.current; if (!el) return;
    const r = el.getBoundingClientRect();
    const sx = e.clientX, sy = e.clientY, sw = r.width, sh = r.height;
    let last: Geom = { w: Math.round(sw), h: Math.round(sh) };
    if (big) { setGeom(last); persistGeom(last); setBig(false); }
    const move = (ev: PointerEvent) => {
      const dx = ev.clientX - sx, dy = ev.clientY - sy;
      const maxW = window.innerWidth - 24, maxH = window.innerHeight - 92;
      let w = sw, h = sh;
      if (side === "se") w = sw + dx; else if (side === "sw") w = sw - dx;
      h = sh + dy; /* هر سه دستگیره ارتفاع را تغییر می‌دهند */
      last = { w: Math.min(maxW, Math.max(Math.min(MIN_W, maxW), Math.round(w))), h: Math.min(maxH, Math.max(Math.min(MIN_H, maxH), Math.round(h))) };
      setGeom(last);
    };
    const up = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      setGeom(last); persistGeom(last); /* ذخیرهٔ خودکار پس از پایان درگ */
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  const toggleSize = () => {
    setBig((b) => {
      try { localStorage.setItem("acc-win-size", b ? "win" : "full"); } catch { /* - */ }
      return !b;
    });
  };

  useEffect(() => {
    const h = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(null); };
    document.addEventListener("click", h);
    return () => document.removeEventListener("click", h);
  }, []);

  const logout = async () => {
    try { await fetch("/api/auth/login", { method: "DELETE" }); } catch { /* - */ }
    router.replace("/login");
  };

  if (!app.ready) return <div className="boot">در حال بارگذاری…</div>;

  const menus = MENUS.map((g) =>
    g.title === "عملیات پایه" && app.can?.logview
      ? { ...g, items: [...g.items, ["/windows/log", "لاگ سیستم"] as [string, string]] }
      : g
  );
  const yearsOf = app.years.filter((y) => y.CompanyId === app.companyId);

  return (
    <div className="shell">
      <div className="menubar" ref={ref}>
        <Link href="/windows/chart" className="brand">
          <span className="brand-mark">YFG</span>
          <span>حسابداری</span>
        </Link>
        {menus.map((g) => (
          <div key={g.title} className={`menu-group ${open === g.title ? "open" : ""}`}>
            <button onClick={() => setOpen(open === g.title ? null : g.title)}>{g.title}</button>
            <div className="menu-drop">
              {g.items.map(([href, label]) => (
                <Link key={href} href={href} onClick={() => setOpen(null)}
                  className={path === href ? "active" : ""}>{label}</Link>
              ))}
            </div>
          </div>
        ))}
        <div className="menubar-user">
          <span className="user-chip" title={app.user?.username}>
            <b>{app.user?.display}</b>
            <i>{app.user?.role === "admin" ? "مدیر سامانه" : app.user?.role === "registrar" ? "ثبت‌کننده" : "بررسی‌کننده"}</i>
          </span>
          <button className="btn ghost" onClick={logout}>خروج</button>
        </div>
      </div>

      <div className="ctxbar">
        <label>شرکت</label>
        <select value={app.companyId || ""} onChange={(e) => app.pickCompany(Number(e.target.value))}>
          <option value="">— انتخاب —</option>
          {app.companies.map((c) => <option key={c.CompanyId} value={c.CompanyId}>{c.CompanyCode} — {c.TitleFa}</option>)}
        </select>
        <label>سال مالی</label>
        <select value={app.yearId || ""} onChange={(e) => app.pickYear(Number(e.target.value))} disabled={!app.companyId}>
          <option value="">— انتخاب —</option>
          {yearsOf.map((y) => <option key={y.YearId} value={y.YearId}>{y.Title}{y.IsClosed ? " (بسته)" : ""}</option>)}
        </select>
        {app.company && (
          <span className="ctx-badge">کدینگ: {app.company.CodingMode === 2 ? "گروه/کل/معین" : "پلکانی"}</span>
        )}
        {app.year && <span className="ctx-badge">از {app.year.Title}</span>}
      </div>

      <div className="main">
        <div
          className={`window ${big ? "full" : "win"}`}
          ref={winRef}
          style={!big && geom ? { width: geom.w, height: geom.h } : undefined}
        >
          <div className="window-title">
            <span>{title}{sub && <span className="sub"> — {sub}</span>}</span>
            <button className="btn-win" onClick={toggleSize}
              title={big ? "حالت پنجره‌ای (اندازهٔ ذخیره‌شده به‌طور خودکار بازیابی می‌شود)" : "تمام‌صفحه — کل صفحه را پر می‌کند"}
              aria-label="تغییر اندازهٔ پنجره">{big ? "❐" : "▣"}</button>
          </div>
          <div className="window-body">{children}</div>
          {/* v2.4.4 — دستگیره‌های تغییر اندازه با موس: لبهٔ پایین + دو گوشهٔ پایین */}
          <div className="rz rz-s"  onPointerDown={startResize("s")}  title="تغییر ارتفاع" />
          <div className="rz rz-se" onPointerDown={startResize("se")} title="تغییر اندازه (گوشه)" />
          <div className="rz rz-sw" onPointerDown={startResize("sw")} title="تغییر اندازه (گوشه)" />
        </div>
      </div>
    </div>
  );
}

const MENUS: { title: string; items: [string, string][] }[] = [
  {
    title: "اطلاعات پایه",
    items: [
      ["/windows/parties", "اشخاص و شرکت‌های طرف مکاتبه"],
      ["/windows/party-categories", "تعریف طبقه‌بندی اشخاص"],
      ["/windows/geo-places", "موقعیت‌های جغرافیایی"],
      ["/windows/app-settings", "تنظیمات عمومی"],
      ["/windows/holidays", "تعطیلات و تقویم"],
    ],
  },
  {
    title: "حساب‌ها",
    items: [
      ["/windows/groups", "معرفی گروه حساب‌ها"],
      ["/windows/kol", "معرفی حساب‌های کل"],
      ["/windows/moein", "معرفی حساب‌های معین"],
      ["/windows/tafsili-types", "انواع تفصیل"],
      ["/windows/tafsili", "معرفی حساب‌های تفصیلی"],
      ["/windows/tafsili-categories", "طبقه‌بندی تفصیلی"],
      ["/windows/std-narrations", "شرح‌های استاندارد"],
      ["/windows/chart", "گزارش مجموعه حساب‌ها (شجره)"],
    ],
  },
  {
    title: "اسناد حسابداری",
    items: [
      ["/windows/vch-types", "تعریف انواع سند"],
      ["/windows/branch", "تعریف شعبه"],
      ["/windows/fx", "تعریف ارزها"],
      ["/windows/vch-issue", "صدور سند حسابداری"],
      ["/windows/vch-list", "لیست اسناد"],
      ["/windows/vch-review", "بررسی اسناد"],
      ["/windows/vch-finalize", "قطعی کردن اسناد"],
      ["/windows/vch-reverse", "برگشت اسناد قطعی"],
    ],
  },
  {
    title: "مرور و دفاتر",
    items: [
      ["/windows/review", "مرور حساب‌ها (کامل — AcVwDef)"],
      ["/windows/notes", "نمایش اعلامیه‌ها"],
      ["/windows/book-journal", "دفتر روزنامه"],
      ["/windows/book-kol", "دفتر کل"],
      ["/windows/book-moein", "دفتر معین"],
      ["/windows/book-tafsili", "دفتر تفصیلی"],
    ],
  },
  {
    title: "گزارش‌های تراز",
    items: [
      ["/windows/taraz", "گزارش تراز"],
      ["/windows/taraz-monthly", "گزارش تراز ماهانه"],
      ["/windows/taraz-six", "گزارش تراز اسناد شش‌سطحی"],
    ],
  },
  {
    title: "عملیات پایه",
    items: [
      ["/windows/companies", "معرفی شرکت‌ها"],
      ["/windows/fiscal-year", "سال مالی"],
      ["/windows/opening", "ماندهٔ ابتدای دوره و سند افتتاحیه"],
      ["/windows/dictionary", "واژه‌نامهٔ داده"],
      ["/windows/update", "آپدیت آنلاین"],
    ],
  },
];
