"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useApp } from "@/components/App";

/* ============================================================================
   پوستهٔ برنامه (v2.0.0) — منوی اصلی + نوار کانتکست + قاب پنجره
   منبع شرکت/سال: AppContext سراسری (نه کوکی محلی هر پنجره)
   ============================================================================ */

export default function Shell({ children, title, sub }: { children: React.ReactNode; title: string; sub?: string }) {
  const app = useApp();
  const [open, setOpen] = useState<string | null>(null);
  const path = usePathname();
  const router = useRouter();
  const ref = useRef<HTMLDivElement>(null);
  /* v2.2.0 — پنجرهٔ تمام‌صفحه یا پنجره‌ای قابل تغییر اندازه (درخواست: پنجره‌ها کل صفحه را پر کنند و قابل بزرگ/کوچک شدن باشند) */
  const [big, setBig] = useState(true);

  useEffect(() => {
    try { const v = localStorage.getItem("acc-win-size"); if (v === "win") setBig(false); } catch { /* - */ }
  }, []);

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
        <div className={`window ${big ? "full" : "win"}`}>
          <div className="window-title">
            <span>{title}{sub && <span className="sub"> — {sub}</span>}</span>
            <button className="btn-win" onClick={toggleSize}
              title={big ? "حالت پنجره‌ای (قابل تغییر اندازه با موس)" : "تمام‌صفحه — کل صفحه را پر می‌کند"}
              aria-label="تغییر اندازهٔ پنجره">{big ? "❐" : "▣"}</button>
          </div>
          <div className="window-body">{children}</div>
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
