"use client";

import type { ReactNode } from "react";

/* ============================================================================
   منوی سراسری برنامه (v2.5.0) — مشترک بین Shell (حالت مستقل) و Workspace
   (میزکار چندپنجره‌ای) + آیکون هر گروه برای نوار عنوان پنجره و چیپ نوار پایین
   ============================================================================ */

export type MenuIcon = "base" | "accounts" | "vouchers" | "books" | "taraz" | "system";

export const MENUS: { title: string; icon: MenuIcon; items: [string, string][] }[] = [
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
];

/* آیکون‌های خطی سبک lucide — بدون وابستگی خارجی */
export function WinIcon({ k, size = 14, className }: { k: MenuIcon; size?: number; className?: string }): ReactNode {
  const common = {
    width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const, className, "aria-hidden": true,
  };
  switch (k) {
    case "base": /* folder */
      return (
        <svg {...common}>
          <path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" />
        </svg>
      );
    case "accounts": /* layers */
      return (
        <svg {...common}>
          <path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z" />
          <path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65" />
          <path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65" />
        </svg>
      );
    case "vouchers": /* file-text */
      return (
        <svg {...common}>
          <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" />
          <path d="M14 2v4a2 2 0 0 0 2 2h4" />
          <path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" />
        </svg>
      );
    case "books": /* book-open */
      return (
        <svg {...common}>
          <path d="M12 7v14" />
          <path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z" />
        </svg>
      );
    case "taraz": /* scale */
      return (
        <svg {...common}>
          <path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z" />
          <path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z" />
          <path d="M7 21h10" /><path d="M12 3v18" />
          <path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2" />
        </svg>
      );
    case "system": /* database */
      return (
        <svg {...common}>
          <ellipse cx="12" cy="5" rx="9" ry="3" />
          <path d="M3 5V19A9 3 0 0 0 21 19V5" />
          <path d="M3 12A9 3 0 0 0 21 12" />
        </svg>
      );
  }
}
