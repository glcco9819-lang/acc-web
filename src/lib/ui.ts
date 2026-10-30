"use client";

/* ابزارهای مشترک کلاینت */
export async function api(path: string, init?: RequestInit): Promise<any> {
  const r = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  let j: any = null;
  try { j = await r.json(); } catch { /* - */ }
  if (!r.ok || (j && j.ok === false)) {
    const err = new Error(j?.error || `HTTP ${r.status}`);
    (err as any).code = j?.code;
    throw err;
  }
  /* v2.4.4 — همگام‌سازی خودکار پنجره‌ها: پس از هر تغییر موفق داده (ثبت/اصلاح/حذف)
     رویداد سراسری acc:data منتشر می‌شود تا پنجره‌های شنونده فهرست خود را تازه کنند */
  const m = init?.method;
  if (m && m !== "GET") {
    try { window.dispatchEvent(new CustomEvent("acc:data", { detail: { method: m, path } })); } catch { /* - */ }
    /* v2.5.0 — میزکار چندپنجره‌ای: در حالت جاسازی‌شده (iframe /desktop) میزبان
       باخبر می‌شود تا «سایر پنجره‌های باز» را هم تازه کند */
    try {
      if (window.parent && window.parent !== window)
        window.parent.postMessage({ source: "acc-win", type: "acc:data", path }, window.location.origin);
    } catch { /* - */ }
  }
  return j;
}

export const fa = (n: number | string | null | undefined) =>
  Number(n || 0).toLocaleString("fa-IR", { maximumFractionDigits: 0 });

export const faDate = (s: string | null | undefined) => (s || "").replace(/\//g, "/");

export const STATE_FA = ["", "موقت", "بررسی‌شده", "قطعی"];
export const STATE_CLS = ["", "s1", "s2", "s3"];
export const NATURE_FA = ["", "بدهکار", "بستانکار", "دوطرفه"];

export interface Ctx {
  companyId: number;
  yearId: number;
  company?: { CompanyId: number; CompanyCode: string; TitleFa: string; CodingMode: number };
  year?: { YearId: number; JalaliYear: number; Title: string } | null;
  user?: { username: string; display: string; role: string };
  can?: { issue: boolean; review: boolean; finalize: boolean; reverse: boolean; master: boolean };
}

export function readCtxCookie(): Ctx {
  if (typeof document === "undefined") return { companyId: 0, yearId: 0 };
  const m = document.cookie.match(/(?:^|;\s*)acc_ctx=([^;]+)/);
  try { return m ? JSON.parse(decodeURIComponent(m[1])) : { companyId: 0, yearId: 0 }; }
  catch { return { companyId: 0, yearId: 0 }; }
}

/* خروجی Excel (CSV با BOM — سازگار با اکسل فارسی) [گزینهٔ Excel در فرم‌های گزارش تراز] */
export function exportCsv(filename: string, headers: string[], rows: (string | number)[][]) {
  const esc = (v: string | number) => {
    const s = String(v ?? "");
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const csv = "\uFEFF" + [headers.map(esc).join(","), ...rows.map((r) => r.map(esc).join(","))].join("\r\n");
  const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
  const a = document.createElement("a");
  a.href = url; a.download = filename; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 3000);
}
