"use client";

import type { ReactNode } from "react";

/* ============================================================================
   ساختار ماژول‌های برنامه (v2.6.0)
   • نوار بالایی (ساید بار بالا): فقط آیکون ماژول‌ها به ترتیب اعلام‌شده
   • ساید بار سمت راست: تب‌ها و فیلدهای (آیتم‌های) ماژول فعال
   • ماژول حسابداری کامل است (همان منوهای قبلی به‌صورت تب/فیلد)؛
     سایر ماژول‌ها فعلاً فقط آیکون دارند و به‌تدریج تکمیل می‌شوند.
   ============================================================================ */

/* آیکون تب‌ها (داخل ساید بار راست) */
export type MenuIcon = "base" | "accounts" | "vouchers" | "books" | "taraz" | "system";
/* آیکون ماژول‌ها (نوار بالایی) */
export type ModuleIcon =
  | "acc" | "store" | "prod" | "sales" | "cash"
  | "hr" | "payroll" | "crm" | "asset";

export interface ModuleTab {
  title: string;
  icon: MenuIcon;
  items: [string, string][]; /* [مسیر, عنوان فیلد/پنجره] */
}

export interface ModuleDef {
  id: string;
  title: string;
  icon: ModuleIcon;
  ready: boolean; /* false = فعلاً فقط آیکون (در دست ساخت) */
  tabs: ModuleTab[];
}

export const MODULES: ModuleDef[] = [
  {
    id: "acc",
    title: "حسابداری",
    icon: "acc",
    ready: true,
    tabs: [
      {
        title: "اطلاعات پایه",
        icon: "base",
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
        icon: "accounts",
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
        icon: "vouchers",
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
        icon: "books",
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
        icon: "taraz",
        items: [
          ["/windows/taraz", "گزارش تراز"],
          ["/windows/taraz-monthly", "گزارش تراز ماهانه"],
          ["/windows/taraz-six", "گزارش تراز اسناد شش‌سطحی"],
        ],
      },
      {
        title: "عملیات پایه",
        icon: "system",
        items: [
          ["/windows/companies", "معرفی شرکت‌ها"],
          ["/windows/fiscal-year", "سال مالی"],
          ["/windows/opening", "ماندهٔ ابتدای دوره و سند افتتاحیه"],
          ["/windows/dictionary", "واژه‌نامهٔ داده"],
          ["/windows/update", "آپدیت آنلاین"],
        ],
      },
    ],
  },
  { id: "store",   title: "انبار",            icon: "store",   ready: false, tabs: [] },
  { id: "prod",    title: "تولید",            icon: "prod",    ready: false, tabs: [] },
  { id: "sales",   title: "فروش",             icon: "sales",   ready: false, tabs: [] },
  { id: "cash",    title: "دریافت و پرداخت",  icon: "cash",    ready: false, tabs: [] },
  { id: "hr",      title: "منابع انسانی",     icon: "hr",      ready: false, tabs: [] },
  { id: "payroll", title: "حقوق و دستمزد",    icon: "payroll", ready: false, tabs: [] },
  { id: "crm",     title: "سی آر ام",         icon: "crm",     ready: false, tabs: [] },
  { id: "asset",   title: "دارایی ثابت",      icon: "asset",   ready: false, tabs: [] },
];

/* سازگاری با پوستهٔ مستقل (Shell) — همان تب‌های ماژول حسابداری */
export const MENUS: { title: string; icon: MenuIcon; items: [string, string][] }[] =
  MODULES[0].tabs.map((t) => ({ title: t.title, icon: t.icon, items: t.items }));

/* ---------- آیکون‌های خطی سبک lucide — بدون وابستگی خارجی ---------- */
const common = (size: number, className?: string) => ({
  width: size, height: size, viewBox: "0 0 24 24", fill: "none",
  stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const, className, "aria-hidden": true,
});

export function ModIcon({ k, size = 18, className }: { k: ModuleIcon; size?: number; className?: string }): ReactNode {
  switch (k) {
    case "acc": /* calculator — حسابداری */
      return (
        <svg {...common(size, className)}>
          <rect width="16" height="20" x="4" y="2" rx="2" />
          <line x1="8" x2="16" y1="6" y2="6" />
          <line x1="16" x2="16" y1="14" y2="18" />
          <path d="M16 10h.01" /><path d="M12 10h.01" /><path d="M8 10h.01" />
          <path d="M12 14h.01" /><path d="M8 14h.01" /><path d="M12 18h.01" /><path d="M8 18h.01" />
        </svg>
      );
    case "store": /* package — انبار */
      return (
        <svg {...common(size, className)}>
          <path d="M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73z" />
          <path d="M12 22V12" /><path d="m3.3 7 7.703 4.734a2 2 0 0 0 1.994 0L20.7 7" />
          <path d="m7.5 4.27 9 5.15" />
        </svg>
      );
    case "prod": /* factory — تولید */
      return (
        <svg {...common(size, className)}>
          <path d="M2 20a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8a2 2 0 0 0-1.106-1.789l-7.209-3.64A2 2 0 0 0 13 4.12v4.14l-6.5-3.286A2 2 0 0 0 3 6.78v13.2" />
          <path d="M2 20h20" />
          <path d="M9 17h.01" /><path d="M13 17h.01" /><path d="M17 17h.01" />
        </svg>
      );
    case "sales": /* shopping-cart — فروش */
      return (
        <svg {...common(size, className)}>
          <circle cx="8" cy="21" r="1" /><circle cx="19" cy="21" r="1" />
          <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12" />
        </svg>
      );
    case "cash": /* banknote با پیکان — دریافت و پرداخت */
      return (
        <svg {...common(size, className)}>
          <rect width="20" height="12" x="2" y="6" rx="2" />
          <circle cx="12" cy="12" r="2" />
          <path d="M6 12h.01" /><path d="M18 12h.01" />
        </svg>
      );
    case "hr": /* users — منابع انسانی */
      return (
        <svg {...common(size, className)}>
          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M22 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
      );
    case "payroll": /* wallet — حقوق و دستمزد */
      return (
        <svg {...common(size, className)}>
          <path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1" />
          <path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4" />
        </svg>
      );
    case "crm": /* heart-handshake — سی آر ام */
      return (
        <svg {...common(size, className)}>
          <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
          <path d="M12 5 9.04 7.96a2.17 2.17 0 0 0 0 3.08c.82.82 2.13.85 3 .07l2.07-1.9a2.82 2.82 0 0 1 3.79 0l2.96 2.66" />
          <path d="m18 15-2-2" /><path d="m15 18-2-2" />
        </svg>
      );
    case "asset": /* building-2 — دارایی ثابت */
      return (
        <svg {...common(size, className)}>
          <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z" />
          <path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2" />
          <path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2" />
          <path d="M10 6h4" /><path d="M10 10h4" /><path d="M10 14h4" /><path d="M10 18h4" />
        </svg>
      );
  }
}

export function WinIcon({ k, size = 14, className }: { k: MenuIcon | ModuleIcon; size?: number; className?: string }): ReactNode {
  /* اگر آیکون از جنس ماژول بود (نوار بالایی) به رندر ماژول واگذار می‌شود */
  if (
    k === "acc" || k === "store" || k === "prod" || k === "sales" || k === "cash" ||
    k === "hr" || k === "payroll" || k === "crm" || k === "asset"
  )
    return <ModIcon k={k} size={size} className={className} />;
  switch (k) {
    case "base": /* folder */
      return (
        <svg {...common(size, className)}>
          <path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" />
        </svg>
      );
    case "accounts": /* layers */
      return (
        <svg {...common(size, className)}>
          <path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z" />
          <path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65" />
          <path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65" />
        </svg>
      );
    case "vouchers": /* file-text */
      return (
        <svg {...common(size, className)}>
          <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" />
          <path d="M14 2v4a2 2 0 0 0 2 2h4" />
          <path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" />
        </svg>
      );
    case "books": /* book-open */
      return (
        <svg {...common(size, className)}>
          <path d="M12 7v14" />
          <path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z" />
        </svg>
      );
    case "taraz": /* scale */
      return (
        <svg {...common(size, className)}>
          <path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z" />
          <path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z" />
          <path d="M7 21h10" /><path d="M12 3v18" />
          <path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2" />
        </svg>
      );
    case "system": /* database */
      return (
        <svg {...common(size, className)}>
          <ellipse cx="12" cy="5" rx="9" ry="3" />
          <path d="M3 5V19A9 3 0 0 0 21 19V5" />
          <path d="M3 12A9 3 0 0 0 21 12" />
        </svg>
      );
  }
}
